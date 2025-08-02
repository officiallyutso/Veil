import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veil/models/bookmark_model.dart';
import 'package:veil/services/bookmark_service.dart' hide Bookmark;

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  String? _currentFolderId;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookmarkService = Provider.of<BookmarkService>(context, listen: false);
      if (bookmarkService.folders.isNotEmpty) {
        setState(() {
          _currentFolderId = bookmarkService.folders.first.id;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddBookmarkDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: () => _showAddFolderDialog(context),
          ),
        ],
      ),
      body: Consumer<BookmarkService>(
        builder: (context, bookmarkService, child) {
          if (bookmarkService.folders.isEmpty) {
            return const Center(
              child: Text('No bookmark folders yet'),
            );
          }
          
          return Column(
            children: [
              // Folder tabs
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: bookmarkService.folders.length,
                  itemBuilder: (context, index) {
                    final folder = bookmarkService.folders[index];
                    final isSelected = folder.id == _currentFolderId;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(folder.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _currentFolderId = folder.id;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              
              // Bookmarks in current folder
              Expanded(
                child: _currentFolderId == null
                    ? const Center(child: Text('Select a folder'))
                    : _buildBookmarksList(bookmarkService),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildBookmarksList(BookmarkService bookmarkService) {
    final bookmarksInFolder = bookmarkService.getBookmarksInFolder(_currentFolderId!);
    
    if (bookmarksInFolder.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No bookmarks in this folder'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Bookmark'),
              onPressed: () => _showAddBookmarkDialog(context),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: bookmarksInFolder.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarksInFolder[index];
        
      //   return ListTile(
      //     leading: bookmark.favicon!.isNotEmpty
      //         ? Image.network(
                  
      //             width: 24,
      //             height: 24,
      //             errorBuilder: (context, error, stackTrace) => const Icon(Icons.bookmark),
      //           )
      //         : const Icon(Icons.bookmark),
      //     title: Text(bookmark.title),
      //     subtitle: Text(
      //       bookmark.url,
      //       maxLines: 1,
      //       overflow: TextOverflow.ellipsis,
      //     ),
      //     onTap: () {
      //       // Return the URL to the browser screen
      //       Navigator.pop(context, bookmark.url);
      //     },
      //     trailing: PopupMenuButton<String>(
      //       onSelected: (value) {
      //       },
      //       itemBuilder: (context) => [
      //         const PopupMenuItem(
      //           value: 'edit',
      //           child: Row(
      //             children: [
      //               Icon(Icons.edit),
      //               SizedBox(width: 8),
      //               Text('Edit'),
      //             ],
      //           ),
      //         ),
      //         const PopupMenuItem(
      //           value: 'delete',
      //           child: Row(
      //             children: [
      //               Icon(Icons.delete),
      //               SizedBox(width: 8),
      //               Text('Delete'),
      //             ],
      //           ),
      //         ),
      //       ],
      //     ),
      //   );
      },
    );
  }
  
  void _showAddBookmarkDialog(BuildContext context) {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    String? selectedFolderId = _currentFolderId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Bookmark'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
                hintText: 'https://example.com',
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            Consumer<BookmarkService>(
              builder: (context, bookmarkService, child) {
                return DropdownButtonFormField<String>(
                  value: selectedFolderId,
                  decoration: const InputDecoration(
                    labelText: 'Folder',
                    border: OutlineInputBorder(),
                  ),
                  items: bookmarkService.folders.map((folder) {
                    return DropdownMenuItem<String>(
                      value: folder.id,
                      child: Text(folder.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedFolderId = value;
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<BookmarkService>(
            builder: (context, bookmarkService, child) {
              return ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty && 
                      urlController.text.isNotEmpty && 
                      selectedFolderId != null) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              );
            },
          ),
        ],
      ),
    );
  }
  
  void _showEditBookmarkDialog(BuildContext context, Bookmark bookmark) {
    final titleController = TextEditingController(text: bookmark.title);
    final urlController = TextEditingController(text: bookmark.url);
    String? selectedFolderId = bookmark.folderId;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Bookmark'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            Consumer<BookmarkService>(
              builder: (context, bookmarkService, child) {
                return DropdownButtonFormField<String>(
                  value: selectedFolderId,
                  decoration: const InputDecoration(
                    labelText: 'Folder',
                    border: OutlineInputBorder(),
                  ),
                  items: bookmarkService.folders.map((folder) {
                    return DropdownMenuItem<String>(
                      value: folder.id,
                      child: Text(folder.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedFolderId = value;
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<BookmarkService>(
            builder: (context, bookmarkService, child) {
              return ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty && 
                      urlController.text.isNotEmpty && 
                      selectedFolderId != null) {
                    final updatedBookmark = Bookmark(
                      id: bookmark.id,
                      url: urlController.text,
                      title: titleController.text,
                      favicon: bookmark.favicon,
                      folderId: selectedFolderId,
                      createdAt: bookmark.createdAt,
                    );
                    bookmarkService.updateBookmark(updatedBookmark as String);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              );
            },
          ),
        ],
      ),
    );
  }
  
  void _showDeleteBookmarkDialog(BuildContext context, Bookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bookmark'),
        content: Text('Are you sure you want to delete "${bookmark.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<BookmarkService>(
            builder: (context, bookmarkService, child) {
              return ElevatedButton(
                onPressed: () {
                  bookmarkService.deleteBookmark(bookmark.id);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              );
            },
          ),
        ],
      ),
    );
  }
  
  void _showAddFolderDialog(BuildContext context) {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Folder'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<BookmarkService>(
            builder: (context, bookmarkService, child) {
              return ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              );
            },
          ),
        ],
      ),
    );
  }
}