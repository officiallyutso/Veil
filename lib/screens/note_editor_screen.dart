import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:veil/models/note_model.dart';
import 'package:veil/services/note_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  
  const NoteEditorScreen({super.key, this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _sourceUrlController = TextEditingController();
  bool _isEdited = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _sourceUrlController.text = widget.note!.sourceUrl;
    }
    
    _titleController.addListener(_markAsEdited);
    _contentController.addListener(_markAsEdited);
    _sourceUrlController.addListener(_markAsEdited);
  }
  
  void _markAsEdited() {
    if (!_isEdited) {
      setState(() {
        _isEdited = true;
      });
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _sourceUrlController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.note == null ? 'New Note' : 'Edit Note'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNote,
              tooltip: 'Save',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 15,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _sourceUrlController,
                decoration: const InputDecoration(
                  labelText: 'Source URL (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'https://example.com',
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _saveNote,
          tooltip: 'Save',
          child: const Icon(Icons.save),
        ),
      ),
    );
  }
  
  Future<bool> _onWillPop() async {
    if (!_isEdited) {
      return true;
    }
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  void _saveNote() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final sourceUrl = _sourceUrlController.text.trim();
    
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter some content')),
      );
      return;
    }
    
    final noteService = Provider.of<NoteService>(context, listen: false);
    
    if (widget.note == null) {
      // Create new note
      await noteService.createNote(
        title: title,
        content: content,
        sourceUrl: sourceUrl,
      );
    } else {
      // Update existing note
      final updatedNote = Note(
        id: widget.note!.id,
        title: title,
        content: content,
        sourceUrl: sourceUrl,
        createdAt: widget.note!.createdAt,
        updatedAt: DateTime.now(),
      );
      await noteService.updateNote(updatedNote);
    }
    
    if (mounted) {
      Navigator.pop(context, true);
    }
  }
}