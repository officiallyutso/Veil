import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GlassModeService extends ChangeNotifier {
  bool _isActive = false;
  bool _isSupported = true;

  bool get isActive => _isActive;
  bool get isSupported => _isSupported;

  Future<void> enableGlassMode() async {
    try {
      if (!_isActive && _isSupported) {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
        _isActive = true;
        notifyListeners();
      }
    } catch (e) {
      print('Failed to enable glass mode: $e');
      _isSupported = false;
      notifyListeners();
      // Fallback: show user notification that feature isn't available
    }
  }

  
  Future<void> disableGlassMode() async {
    try {
      if (_isActive) {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
        _isActive = false;
        notifyListeners();
      }
    } catch (e) {
      print('Failed to disable glass mode: $e');
    }
  }

  // Enhanced blur script with better performance
  String get blurSensitiveContentScript => '''
    (function() {
      if (window.glassModeInitialized) return;
      window.glassModeInitialized = true;
      
      const style = document.createElement('style');
      style.id = 'glass-mode-styles';
      style.textContent = `
        .sensitive-content,
        input[type="password"],
        [data-sensitive="true"],
        .credit-card-number,
        .account-number,
        .ssn,
        [data-mask="true"] {
          filter: blur(8px) !important;
          transition: filter 0.2s ease;
        }
        
        .sensitive-content:hover,
        input[type="password"]:focus,
        [data-sensitive="true"]:hover {
          filter: blur(0) !important;
        }
        
        .glass-mode-overlay {
          position: fixed;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          background: rgba(255, 255, 255, 0.1);
          backdrop-filter: blur(1px);
          pointer-events: none;
          z-index: 999999;
        }
      `;
      document.head.appendChild(style);

      function detectAndBlurSensitive() {
        const patterns = {
          creditCard: /\\b(?:\\d[ -]*?){13,16}\\b/g,
          ssn: /\\b\\d{3}[-]?\\d{2}[-]?\\d{4}\\b/g,
          email: /\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b/g,
          phone: /\\b(?:\\+\\d{1,3}[- ]?)?\\(?\\d{3}\\)?[- ]?\\d{3}[- ]?\\d{4}\\b/g
        };

        const walker = document.createTreeWalker(
          document.body,
          NodeFilter.SHOW_TEXT,
          {
            acceptNode: function(node) {
              return node.parentElement?.tagName !== 'SCRIPT' ? 
                NodeFilter.FILTER_ACCEPT : 
                NodeFilter.FILTER_REJECT;
            }
          }
        );

        const textNodes = [];
        let node;
        while (node = walker.nextNode()) {
          textNodes.push(node);
        }

        textNodes.forEach(textNode => {
          let text = textNode.nodeValue;
          let hasMatch = false;
          
          for (const [type, pattern] of Object.entries(patterns)) {
            if (pattern.test(text)) {
              hasMatch = true;
              break;
            }
          }
          
          if (hasMatch) {
            const span = document.createElement('span');
            span.className = 'sensitive-content';
            span.setAttribute('data-glass-mode', 'true');
            span.textContent = text;
            textNode.parentNode.replaceChild(span, textNode);
          }
        });
      }

      // Initial detection
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', detectAndBlurSensitive);
      } else {
        detectAndBlurSensitive();
      }

      // Watch for dynamic content
      const observer = new MutationObserver(function(mutations) {
        let shouldReprocess = false;
        mutations.forEach(mutation => {
          if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
            shouldReprocess = true;
          }
        });
        
        if (shouldReprocess) {
          setTimeout(detectAndBlurSensitive, 100);
        }
      });

      observer.observe(document.body, {
        childList: true,
        subtree: true
      });
    })();
  ''';
  
  Future<void> injectBlurScript(WebViewController controller) async {
    await controller.runJavaScript(blurSensitiveContentScript);
  }
}