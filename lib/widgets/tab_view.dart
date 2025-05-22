import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:veil/models/tab_model.dart' as tab_model;
import 'package:gesture_x_detector/gesture_x_detector.dart';

class TabView extends StatefulWidget {
  final tab_model.Tab tab;
  final WebViewController controller;
  
  const TabView({
    super.key,
    required this.tab,
    required this.controller,
  });
  
  @override
  State<TabView> createState() => _TabViewState();
}

class _TabViewState extends State<TabView> {
  bool _isGestureNavigationEnabled = true;
  
  @override
  Widget build(BuildContext context) {
    return GestureXDetector(
      onRightSwipe: _isGestureNavigationEnabled
          ? () async {
              if (await widget.controller.canGoBack()) {
                widget.controller.goBack();
              }
            }
          : null,
      onLeftSwipe: _isGestureNavigationEnabled
          ? () async {
              if (await widget.controller.canGoForward()) {
                widget.controller.goForward();
              }
            }
          : null,
      child: WebViewWidget(
        controller: widget.controller,
      ),
    );
  }
}