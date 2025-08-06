import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:veil/models/note_model.dart';
import 'package:veil/services/note_service.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
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
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToNoteEditor(context),
            tooltip: 'New Note',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(context),
            tooltip: 'More Options',
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
                labelText: 'Search Notes',
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
            child: Consumer<NoteService>(
              builder: (context, noteService, child) {
                final filteredNotes = _searchQuery.isEmpty
                    ? noteService.notes
                    : noteService.searchNotes(_searchQuery);
                
                if (filteredNotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _searchQuery.isEmpty
                              ? 'No notes yet'
                              : 'No results found for "$_searchQuery"',
                        ),
                        const SizedBox(height: 16),
                        if (_searchQuery.isEmpty)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Create Note'),
                            onPressed: () => _navigateToNoteEditor(context),
                          ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return _buildNoteCard(context, note);
                  },
                );
              },
            ),
          ),
          Expanded(
            child: Consumer<NoteService>(
              builder: (context, noteService, child) {
                final filteredNotes = _searchQuery.isEmpty
                    ? noteService.notes
                    : noteService.searchNotes(_searchQuery);
                
                if (filteredNotes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _searchQuery.isEmpty
                              ? 'No notes yet'
                              : 'No results found for "$_searchQuery"',
                        ),
                        const SizedBox(height: 16),
                        if (_searchQuery.isEmpty)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Create Note'),
                            onPressed: () => _navigateToNoteEditor(context),
                          ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    final note = filteredNotes[index];
                    return _buildNoteCard(context, note);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToNoteEditor(context),
        tooltip: 'New Note',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildNoteCard(BuildContext context, Note note) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToNoteEditor(context, note: note),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showNoteOptions(context, note),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.content,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM d, yyyy').format(note.updatedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (note.sourceUrl.isNotEmpty)
                    const Icon(Icons.link, size: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _navigateToNoteEditor(BuildContext context, {Note? note}) {
    Navigator.pushNamed(
      context,
      '/note-editor',
      arguments: note,
    ).then((result) {
      // Refresh the list if needed
      if (result == true) {
        setState(() {});
      }
    });
  }
  
  void _showNoteOptions(BuildContext context, Note note) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToNoteEditor(context, note: note);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Content'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: note.content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note content copied to clipboard')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  Share.share(
                    '${note.title}\n\n${note.content}',
                    subject: note.title,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Export as Markdown'),
                onTap: () async {
                  Navigator.pop(context);
                  final noteService = Provider.of<NoteService>(context, listen: false);
                  try {
                    final filePath = await noteService.exportNoteAsMarkdown(note.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Note exported to $filePath')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to export note: $e')),
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteNoteDialog(context, note);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showDeleteNoteDialog(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<NoteService>(context, listen: false).deleteNote(note.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Note deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sort),
                title: const Text('Sort Notes'),
                onTap: () {
                  Navigator.pop(context);
                  _showSortOptionsDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text('Export All Notes'),
                onTap: () async {
                  Navigator.pop(context);
                  final noteService = Provider.of<NoteService>(context, listen: false);
                  try {
                    final filePath = await noteService.exportAllNotesAsMarkdown();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('All notes exported to $filePath')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to export notes: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showSortOptionsDialog(BuildContext context) {
    // This would be implemented to allow sorting notes by different criteria
    // For now, we'll just show a simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Notes'),
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
}