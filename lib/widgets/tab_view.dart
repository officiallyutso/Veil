import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:veil/models/tab_model.dart' as tab_model;

class TabView extends StatefulWidget {
  final tab_model.Tab tab;
  final WebViewController controller;
  final VoidCallback? onNavigationGestureToggle;
  
  const TabView({
    super.key,
    required this.tab,
    required this.controller,
    this.onNavigationGestureToggle,
  });
  
  @override
  State<TabView> createState() => _TabViewState();
}

class _TabViewState extends State<TabView> {
  bool _isGestureNavigationEnabled = true;
  double _dragStartX = 0;
  
  void toggleGestureNavigation() {
    setState(() {
      _isGestureNavigationEnabled = !_isGestureNavigationEnabled;
    });
    widget.onNavigationGestureToggle?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _isGestureNavigationEnabled ? _onDragStart : null,
      onHorizontalDragEnd: _isGestureNavigationEnabled ? _onDragEnd : null,
      child: Stack(
        children: [
          WebViewWidget(
            controller: widget.controller,
          ),
          if (!_isGestureNavigationEnabled)
            Positioned(
              top: 50,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Gesture Nav Disabled',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _onDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
  }
  
  void _onDragEnd(DragEndDetails details) async {
    final dragDistance = details.globalPosition.dx - _dragStartX;
    const minSwipeDistance = 100.0;
    
    if (dragDistance > minSwipeDistance) {
      // Right swipe - go back
      if (await widget.controller.canGoBack()) {
        widget.controller.goBack();
        _showNavigationFeedback('Back');
      }
    } else if (dragDistance < -minSwipeDistance) {
      // Left swipe - go forward
      if (await widget.controller.canGoForward()) {
        widget.controller.goForward();
        _showNavigationFeedback('Forward');
      }
    }
  }
  
  void _showNavigationFeedback(String direction) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigated $direction'),
        duration: const Duration(milliseconds: 1000),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 100, left: 16, right: 16),
      ),
    );
  }
}
