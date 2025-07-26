import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class Bookmark {
  final String id;
  final String title;
  final String url;
  final String? favicon;
  final String folderId;
  final DateTime createdAt;
  final List<String> tags;

  Bookmark({
    required this.id,
    required this.title,
    required this.url,
    this.favicon,
    required this.folderId,
    required this.createdAt,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'url': url,
    'favicon': favicon,
    'folderId': folderId,
    'createdAt': createdAt.toIso8601String(),
    'tags': tags,
  };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
    id: json['id'],
    title: json['title'],
    url: json['url'],
    favicon: json['favicon'],
    folderId: json['folderId'],
    createdAt: DateTime.parse(json['createdAt']),
    tags: List<String>.from(json['tags'] ?? []),
  );
}

class BookmarkFolder {
  final String id;
  final String name;
  final String? parentId;
  final DateTime createdAt;

  BookmarkFolder({
    required this.id,
    required this.name,
    this.parentId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'parentId': parentId,
    'createdAt': createdAt.toIso8601String(),
  };

  factory BookmarkFolder.fromJson(Map<String, dynamic> json) => BookmarkFolder(
    id: json['id'],
    name: json['name'],
    parentId: json['parentId'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}

class BookmarkService extends ChangeNotifier {
  static const String _bookmarksBoxName = 'bookmarks';
  static const String _foldersBoxName = 'bookmark_folders';
  
  late Box _bookmarksBox;
  late Box _foldersBox;
  late List<Bookmark> _bookmarks;
  late List<BookmarkFolder> _folders;
  final _uuid = Uuid();

  List<Bookmark> get bookmarks => _bookmarks;
  List<BookmarkFolder> get folders => _folders;

  Future<void> initialize() async {
    _bookmarksBox = await Hive.openBox(_bookmarksBoxName);
    _foldersBox = await Hive.openBox(_foldersBoxName);
    
    _loadData();
    await _ensureDefaultFolder();
  }

  void _loadData() {
    _bookmarks = _bookmarksBox.values
        .map((data) => Bookmark.fromJson(Map<String, dynamic>.from(data)))
        .toList();
    
    _folders = _foldersBox.values
        .map((data) => BookmarkFolder.fromJson(Map<String, dynamic>.from(data)))
        .toList();
    
    _bookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _ensureDefaultFolder() async {
    if (_folders.isEmpty) {
      await createFolder('Default', null);
    }
  }

  Future<String> createFolder(String name, String? parentId) async {
    final id = _uuid.v4();
    final folder = BookmarkFolder(
      id: id,
      name: name,
      parentId: parentId,
      createdAt: DateTime.now(),
    );
    
    await _foldersBox.put(id, folder.toJson());
    _loadData();
    notifyListeners();
    return id;
  }

  Future<void> addBookmark({
    required String title,
    required String url,
    String? favicon,
    String? folderId,
    List<String> tags = const [],
  }) async {
    folderId ??= _folders.first.id; // Use default folder if none specified
    
    // Check for duplicates
    final existing = _bookmarks.firstWhere(
      (b) => b.url == url,
      orElse: () => Bookmark(id: '', title: '', url: '', folderId: '', createdAt: DateTime.now()),
    );
    
    if (existing.id.isNotEmpty) {
      // Update existing bookmark
      await updateBookmark(existing.id, title: title, tags: tags);
      return;
    }

    final id = _uuid.v4();
    final bookmark = Bookmark(
      id: id,
      title: title,
      url: url,
      favicon: favicon,
      folderId: folderId,
      createdAt: DateTime.now(),
      tags: tags,
    );
    
    await _bookmarksBox.put(id, bookmark.toJson());
    _loadData();
    notifyListeners();
  }

  Future<void> updateBookmark(
    String id, {
    String? title,
    String? url,
    String? favicon,
    String? folderId,
    List<String>? tags,
  }) async {
    final existing = _bookmarks.firstWhere((b) => b.id == id);
    final updated = Bookmark(
      id: id,
      title: title ?? existing.title,
      url: url ?? existing.url,
      favicon: favicon ?? existing.favicon,
      folderId: folderId ?? existing.folderId,
      createdAt: existing.createdAt,
      tags: tags ?? existing.tags,
    );
    
    await _bookmarksBox.put(id, updated.toJson());
    _loadData();
    notifyListeners();
  }

  Future<void> deleteBookmark(String id) async {
    await _bookmarksBox.delete(id);
    _loadData();
    notifyListeners();
  }

  Future<void> deleteFolder(String id) async {
    // Move bookmarks to default folder
    final defaultFolder = _folders.first;
    for (final bookmark in _bookmarks) {
      if (bookmark.folderId == id) {
        await updateBookmark(bookmark.id, folderId: defaultFolder.id);
      }
    }
    
    await _foldersBox.delete(id);
    _loadData();
    notifyListeners();
  }

  List<Bookmark> getBookmarksInFolder(String folderId) {
    return _bookmarks.where((b) => b.folderId == folderId).toList();
  }

  List<Bookmark> searchBookmarks(String query) {
    if (query.isEmpty) return _bookmarks;
    
    final lowercaseQuery = query.toLowerCase();
    return _bookmarks.where((bookmark) {
      return bookmark.title.toLowerCase().contains(lowercaseQuery) ||
             bookmark.url.toLowerCase().contains(lowercaseQuery) ||
             bookmark.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  Future<Map<String, dynamic>> exportBookmarks() async {
    return {
      'folders': _folders.map((f) => f.toJson()).toList(),
      'bookmarks': _bookmarks.map((b) => b.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importBookmarks(Map<String, dynamic> data) async {
    try {
      final folders = data['folders'] as List;
      final bookmarks = data['bookmarks'] as List;
      
      for (final folderData in folders) {
        await _foldersBox.put(folderData['id'], folderData);
      }
      
      for (final bookmarkData in bookmarks) {
        await _bookmarksBox.put(bookmarkData['id'], bookmarkData);
      }
      
      _loadData();
      notifyListeners();
    } catch (e) {
      print('Error importing bookmarks: $e');
      throw Exception('Failed to import bookmarks');
    }
  }
}
