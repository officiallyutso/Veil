import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:veil/models/tab_model.dart' as tab_model;
import 'package:veil/services/settings_service.dart';
import 'package:veil/services/history_service.dart';
import 'package:veil/widgets/browser_app_bar.dart';
import 'package:veil/widgets/browser_bottom_bar.dart';
import 'package:veil/widgets/tab_view.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final List<tab_model.Tab> _tabs = [];
  int _currentTabIndex = 0;
  final Map<String, WebViewController> _controllers = {};
  final _uuid = Uuid();
  
  @override
  void initState() {
    super.initState();
    _addNewTab();
  }
  
  void _addNewTab({String url = 'https://www.google.com'}) {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    final isIncognito = settingsService.settings.enableIncognitoByDefault;
    
    final newTab = tab_model.Tab(
      id: _uuid.v4(),
      url: url,
      isIncognito: isIncognito,
    );
    
    setState(() {
      _tabs.add(newTab);
      _currentTabIndex = _tabs.length - 1;
    });
    
    _initWebViewController(newTab);
  }
  
  void _initWebViewController(tab_model.Tab tab) {
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    final activePersona = settingsService.getActivePersona();
    
    final controller = WebViewController()
      ..setJavaScriptMode(
        activePersona.enableJavaScript 
            ? JavaScriptMode.unrestricted 
            : JavaScriptMode.disabled
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              tab.url = url;
            });
          },
          onPageFinished: (String url) async {
            final title = await _controllers[tab.id]?.getTitle() ?? '';
            
            setState(() {
              tab.url = url;
              tab.title = title;
            });
            
            if (!tab.isIncognito) {
              final historyService = Provider.of<HistoryService>(context, listen: false);
              historyService.addHistoryItem(url, title);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(tab.url));
    
    _controllers[tab.id] = controller;
  }
  
  void _closeTab(int index) {
    if (_tabs.length <= 1) {
      // Don't close the last tab, just reset it
      final newTab = tab_model.Tab(
        id: _uuid.v4(),
        url: 'https://www.google.com',
      );
      
      setState(() {
        _tabs.clear();
        _tabs.add(newTab);
        _currentTabIndex = 0;
      });
      
      _initWebViewController(newTab);
      return;
    }
    
    final tabToClose = _tabs[index];
    _controllers.remove(tabToClose.id);
    
    setState(() {
      _tabs.removeAt(index);
      if (_currentTabIndex >= _tabs.length) {
        _currentTabIndex = _tabs.length - 1;
      }
    });
  }
  
  void _switchTab(int index) {
    setState(() {
      _currentTabIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final currentTab = _tabs.isNotEmpty ? _tabs[_currentTabIndex] : null;
    final controller = currentTab != null ? _controllers[currentTab.id] : null;
    
    return Scaffold(
      appBar: BrowserAppBar(
        currentTab: currentTab,
        controller: controller,
        onNewTab: _addNewTab,
      ),
      body: currentTab != null && controller != null
          ? TabView(
              tab: currentTab,
              controller: controller,
            )
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: BrowserBottomBar(
        tabs: _tabs,
        currentIndex: _currentTabIndex,
        onTabSelected: _switchTab,
        onTabClosed: _closeTab,
        onNewTab: () => _addNewTab(),
      ),
    );
  }
}