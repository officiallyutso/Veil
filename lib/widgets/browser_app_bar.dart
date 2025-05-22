import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:veil/models/tab_model.dart' as tab_model;
import 'package:veil/core/routes.dart';

class BrowserAppBar extends StatefulWidget implements PreferredSizeWidget {
  final tab_model.Tab? currentTab;
  final WebViewController? controller;
  final Function({String url}) onNewTab;
  
  const BrowserAppBar({
    super.key,
    this.currentTab,
    this.controller,
    required this.onNewTab,
  });
  
  @override
  State<BrowserAppBar> createState() => _BrowserAppBarState();
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _BrowserAppBarState extends State<BrowserAppBar> {
  final TextEditingController _urlController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _updateUrlField();
  }
  
  @override
  void didUpdateWidget(BrowserAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentTab?.url != widget.currentTab?.url) {
      _updateUrlField();
    }
  }
  
  void _updateUrlField() {
    if (widget.currentTab != null) {
      _urlController.text = widget.currentTab!.url;
    }
  }
  
  void _loadUrl(String url) {
    if (url.isEmpty) return;
    
    // Add http:// if no protocol specified
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    
    widget.controller?.loadRequest(Uri.parse(url));
    setState(() {
      _isEditing = false;
    });
  }
  
  void _handleSearch(String query) {
    if (query.isEmpty) return;
    
    // Check if it's a URL or a search query
    bool isUrl = Uri.tryParse(query)?.hasScheme ?? false;
    if (!isUrl && !query.contains('.')) {
      // It's a search query, use the default search engine
      final searchUrl = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
      _loadUrl(searchUrl);
    } else {
      _loadUrl(query);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      title: _isEditing
          ? TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'Search or enter URL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _urlController.clear();
                  },
                ),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: _handleSearch,
              autofocus: true,
            )
          : GestureDetector(
              onTap: () {
                setState(() {
                  _isEditing = true;
                });
              },
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.currentTab?.isIncognito ?? false
                          ? Icons.visibility_off
                          : Icons.public,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.currentTab?.url ?? '',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
            ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            widget.controller?.reload();
          },
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'new_tab':
                widget.onNewTab();
                break;
              case 'bookmarks':
                Navigator.pushNamed(context, AppRoutes.bookmarks);
                break;
              case 'history':
                Navigator.pushNamed(context, AppRoutes.history);
                break;
              case 'sessions':
                Navigator.pushNamed(context, AppRoutes.sessions);
                break;
              case 'settings':
                Navigator.pushNamed(context, AppRoutes.settings);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'new_tab',
              child: Row(
                children: [
                  Icon(Icons.add),
                  SizedBox(width: 8),
                  Text('New Tab'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'bookmarks',
              child: Row(
                children: [
                  Icon(Icons.bookmark),
                  SizedBox(width: 8),
                  Text('Bookmarks'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history),
                  SizedBox(width: 8),
                  Text('History'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'sessions',
              child: Row(
                children: [
                  Icon(Icons.folder),
                  SizedBox(width: 8),
                  Text('Sessions'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: _isLoading
          ? PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : null,
    );
  }
  
  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}