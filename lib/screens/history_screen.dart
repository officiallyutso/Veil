import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:veil/services/history_service.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _showClearHistoryDialog(context),
            tooltip: 'Clear History',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search History',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: Consumer<HistoryService>(
              builder: (context, historyService, child) {
                final filteredItems = _searchQuery.isEmpty
                    ? historyService.historyItems
                    : historyService.searchHistory(_searchQuery);
                
                if (filteredItems.isEmpty) {
                  return Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No browsing history yet'
                          : 'No results found for "$_searchQuery"',
                    ),
                  );
                }
                
                // Group history items by date
                final groupedItems = <String, List<dynamic>>{};
                for (final item in filteredItems) {
                  final date = DateFormat('MMMM d, yyyy').format(item.visitedAt);
                  if (!groupedItems.containsKey(date)) {
                    groupedItems[date] = [];
                  }
                  groupedItems[date]!.add(item);
                }
                
                return ListView.builder(
                  itemCount: groupedItems.length,
                  itemBuilder: (context, index) {
                    final date = groupedItems.keys.elementAt(index);
                    final items = groupedItems[date]!;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            date,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ...items.map((item) {
                          return ListTile(
                            leading: item.favicon.isNotEmpty
                                ? Image.network(
                                    item.favicon,
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.public),
                                  )
                                : const Icon(Icons.public),
                            title: Text(item.title),
                            subtitle: Text(
                              item.url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              DateFormat('h:mm a').format(item.visitedAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            onTap: () {
                              Navigator.pop(context, item.url);
                            },
                            onLongPress: () {
                              _showHistoryItemOptions(context, item);
                            },
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _showHistoryItemOptions(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                            ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Open'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  Navigator.pop(context, item.url); // Return URL to browser
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_add),
                title: const Text('Add to Bookmarks'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToBookmarksDialog(context, item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy URL'),
                onTap: () {
                  Navigator.pop(context);
                  // Copy URL to clipboard
                  Clipboard.setData(ClipboardData(text: item.url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URL copied to clipboard')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete from History', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<HistoryService>(context, listen: false)
                      .deleteHistoryItem(item.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showAddToBookmarksDialog(BuildContext context, dynamic historyItem) {
    // This would be implemented to add the history item to bookmarks
    // You would need to integrate with the BookmarkService
    // For now, we'll just show a simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to Bookmarks'),
        content: const Text('This feature will be implemented soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  void _showClearHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Browsing History'),
        content: const Text(
          'Are you sure you want to clear all browsing history? This action cannot be undone.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<HistoryService>(context, listen: false).clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Browsing history cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}