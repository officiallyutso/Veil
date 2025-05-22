import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GlassModeService {
  bool _isActive = false;
  
  bool get isActive => _isActive;
  
  Future<void> enableGlassMode() async {
    if (!_isActive) {
      // Prevent screenshots
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      _isActive = true;
    }
  }
  
  Future<void> disableGlassMode() async {
    if (_isActive) {
      // Allow screenshots again
      await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      _isActive = false;
    }
  }
  
  // JavaScript to inject for blurring sensitive content
  String get blurSensitiveContentScript => '''
    (function() {
      // CSS to blur sensitive content
      const style = document.createElement('style');
      style.textContent = `
        .sensitive-content, 
        input[type="password"], 
        [data-sensitive="true"],
        .credit-card-number,
        .account-number,
        .ssn,
        [data-mask="true"] {
          filter: blur(6px) !important;
          transition: filter 0.3s ease;
        }
        
        .sensitive-content:hover, 
        input[type="password"]:focus, 
        [data-sensitive="true"]:hover,
        .credit-card-number:hover,
        .account-number:hover,
        .ssn:hover,
        [data-mask="true"]:hover {
          filter: blur(0) !important;
        }
      `;
      document.head.appendChild(style);
      
      // Detect and mark potential sensitive content
      function detectSensitiveContent() {
        // Credit card pattern
        const creditCardPattern = /\\b(?:\\d[ -]*?){13,16}\\b/;
        
        // Social security number pattern (US)
        const ssnPattern = /\\b\\d{3}[-]?\\d{2}[-]?\\d{4}\\b/;
        
        // Email pattern
        const emailPattern = /\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}\\b/;
        
        // Phone number pattern
        const phonePattern = /\\b(?:\\+\\d{1,3}[- ]?)?\\(?\\d{3}\\)?[- ]?\\d{3}[- ]?\\d{4}\\b/;
        
        // Get all text nodes
        const textNodes = [];
        const walk = document.createTreeWalker(
          document.body, 
          NodeFilter.SHOW_TEXT, 
          null, 
          false
        );
        
        let node;
        while(node = walk.nextNode()) {
          textNodes.push(node);
        }
        
        // Check each text node for sensitive patterns
        textNodes.forEach(textNode => {
          const text = textNode.nodeValue;
          if (
            creditCardPattern.test(text) || 
            ssnPattern.test(text) || 
            emailPattern.test(text) || 
            phonePattern.test(text)
          ) {
            const span = document.createElement('span');
            span.className = 'sensitive-content';
            span.textContent = text;
            textNode.parentNode.replaceChild(span, textNode);
          }
        });
      }
      
      // Run detection when page loads and after any DOM changes
      detectSensitiveContent();
      
      // Create a MutationObserver to watch for DOM changes
      const observer = new MutationObserver(mutations => {
        detectSensitiveContent();
      });
      
      // Start observing
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