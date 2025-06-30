import 'package:flutter/material.dart' hide Tab;
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:veil/models/tab_model.dart';
import 'package:veil/services/history_service.dart';
import 'package:veil/services/bookmark_service.dart';
import 'package:veil/services/focus_mode_service.dart';
import 'package:veil/services/glass_mode_service.dart';
import 'package:veil/widgets/browser_app_bar.dart';
import 'package:veil/widgets/browser_bottom_bar.dart';
import 'package:veil/widgets/tab_view.dart';
import 'package:veil/widgets/browser_drawer.dart';

class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final List<Tab> _tabs = [];
  final List<WebViewController> _controllers = [];
  int _currentIndex = 0;
  final _uuid = Uuid();
  bool _isIncognito = false;
  
  @override
  void initState() {
    super.initState();
    _addNewTab();
  }
  
  void _addNewTab({String url = 'https://www.google.com'}) {
    final id = _uuid.v4();
    final tab = Tab(
      id: id,
      url: url,
      title: 'New Tab',
      isIncognito: _isIncognito,
    );
    
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              tab.url = url;
              _tabs[_tabs.indexOf(tab)] = tab;
            });
          },
          onPageFinished: (String url) async {
            final title = await _controllers[_tabs.indexOf(tab)].getTitle() ?? 'New Tab';
            
            setState(() {
              tab.url = url;
              tab.title = title;
              _tabs[_tabs.indexOf(tab)] = tab;
            });
            
            // Add to history if not in incognito mode
            if (!tab.isIncognito) {
              final historyService = Provider.of<HistoryService>(context, listen: false);
              historyService.addHistoryItem(url, title);
            }
            
            // Update focus mode tracking
            final focusModeService = Provider.of<FocusModeService>(context, listen: false);
            if (focusModeService.isActive) {
              focusModeService.updateCurrentDomain(url);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
    
    setState(() {
      _tabs.add(tab);
      _controllers.add(controller);
      _currentIndex = _tabs.length - 1;
    });
  }
  
  void _closeTab(int index) {
    if (_tabs.length <= 1) {
      // Don't close the last tab, just reset it
      _controllers[0].loadRequest(Uri.parse('https://www.google.com'));
      setState(() {
        _tabs[0] = Tab(
          id: _tabs[0].id,
          url: 'https://www.google.com',
          title: 'New Tab',
          isIncognito: _isIncognito,
        );
      });
      return;
    }
    
    setState(() {
      _tabs.removeAt(index);
      _controllers.removeAt(index);
      
      // Adjust current index if needed
      if (_currentIndex >= _tabs.length) {
        _currentIndex = _tabs.length - 1;
      } else if (_currentIndex > index) {
        _currentIndex--;
      }
    });
  }
  
  void _selectTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  
  void _toggleIncognitoMode() {
    setState(() {
      _isIncognito = !_isIncognito;
    });
    
    // Show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isIncognito 
            ? 'Incognito mode enabled. New tabs will be private.' 
            : 'Incognito mode disabled. New tabs will be normal.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrowserAppBar(
        currentTab: _tabs.isNotEmpty ? _tabs[_currentIndex] : null,
        controller: _controllers.isNotEmpty ? _controllers[_currentIndex] : null,
        onNewTab: ({String url = 'https://www.google.com'}) => _addNewTab(url: url),
      ),
      drawer: BrowserDrawer(
        onToggleIncognito: _toggleIncognitoMode,
        isIncognito: _isIncognito,
      ),
      body: _tabs.isNotEmpty
          ? IndexedStack(
              index: _currentIndex,
              children: List.generate(_tabs.length, (index) {
                return TabView(
                  tab: _tabs[index],
                  controller: _controllers[index],
                );
              }),
            )
          : const Center(child: Text('No tabs open')),
      bottomNavigationBar: BrowserBottomBar(
        tabs: _tabs,
        currentIndex: _currentIndex,
        onTabSelected: _selectTab,
        onTabClosed: _closeTab,
        onNewTab: () => _addNewTab(),
      ),
    );
  }
}