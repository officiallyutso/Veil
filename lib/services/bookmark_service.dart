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
  
  late Box<Bookmark> _bookmarksBox;
  late Box<BookmarkFolder> _foldersBox;
  late List<Bookmark> _bookmarks;
  late List<BookmarkFolder> _folders;
  final _uuid = Uuid();
  
  List<Bookmark> get bookmarks => _bookmarks;
  List<BookmarkFolder> get folders => _folders;
  
  Future<void> initialize() async {
    // Register adapters if not registered
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(BookmarkAdapter());
    }
    
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(BookmarkFolderAdapter());
    }
    
    // Open boxes
    _bookmarksBox = await Hive.openBox<Bookmark>(_bookmarksBoxName);
    _foldersBox = await Hive.openBox<BookmarkFolder>(_foldersBoxName);
    
    // Load bookmarks and folders
    _bookmarks = _bookmarksBox.values.toList();
    _folders = _foldersBox.values.toList();
    
    // Create default folder if none exists
    if (_folders.isEmpty) {
      await _createDefaultFolder();
    }
  }
  
  Future<void> _createDefaultFolder() async {
    final id = _uuid.v4();
    final folder = BookmarkFolder(
      id: id,
      name: 'Bookmarks',
    );
    
    await _foldersBox.put(id, folder);
    _folders = _foldersBox.values.toList();
  }
  
  Future<void> addBookmark(String url, String title, {String favicon = '', String? folderId}) async {
    final id = _uuid.v4();
    final bookmark = Bookmark(
      id: id,
      url: url,
      title: title.isNotEmpty ? title : url,
      favicon: favicon,
      folderId: folderId ?? _folders.first.id,
    );
    
    await _bookmarksBox.put(id, bookmark);
    
    _bookmarks = _bookmarksBox.values.toList();
    
    notifyListeners();
  }
  
  Future<void> updateBookmark(Bookmark bookmark) async {
    await _bookmarksBox.put(bookmark.id, bookmark);
    
    _bookmarks = _bookmarksBox.values.toList();
    
    notifyListeners();
  }
  
  Future<void> deleteBookmark(String id) async {
    await _bookmarksBox.delete(id);
    
    _bookmarks = _bookmarksBox.values.toList();
    
    notifyListeners();
  }
  
  Future<void> addFolder(String name, {String? parentId}) async {
    final id = _uuid.v4();
    final folder = BookmarkFolder(
      id: id,
      name: name,
      parentId: parentId,
    );
    
    await _foldersBox.put(id, folder);
    
    _folders = _foldersBox.values.toList();
    
    notifyListeners();
  }
  
  Future<void> updateFolder(BookmarkFolder folder) async {
    await _foldersBox.put(folder.id, folder);
    
    _folders = _foldersBox.values.toList();
    
    notifyListeners();
  }
  
  Future<void> deleteFolder(String id) async {
    // Move bookmarks in this folder to the default folder
    final defaultFolderId = _folders.first.id;
    final bookmarksInFolder = _bookmarks.where((b) => b.folderId == id).toList();
    
    for (var bookmark in bookmarksInFolder) {
      bookmark.folderId = defaultFolderId;
      await _bookmarksBox.put(bookmark.id, bookmark);
    }
    
    // Delete the folder
    await _foldersBox.delete(id);
    
    _folders = _foldersBox.values.toList();
    _bookmarks = _bookmarksBox.values.toList();
    
    notifyListeners();
  }
  
  List<Bookmark> getBookmarksInFolder(String folderId) {
    return _bookmarks.where((b) => b.folderId == folderId).toList();
  }
  
  bool isBookmarked(String url) {
    return _bookmarks.any((b) => b.url == url);
  }
  
  Bookmark? getBookmarkByUrl(String url) {
    try {
      return _bookmarks.firstWhere((b) => b.url == url);
    } catch (e) {
      return null;
    }
  }
}

// These adapter classes will be generated by build_runner
class BookmarkAdapter extends TypeAdapter<Bookmark> {
  @override
  final int typeId = 4;

  @override
  Bookmark read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return Bookmark(
      id: fields[0] as String,
      url: fields[1] as String,
      title: fields[2] as String,
      favicon: fields[3] as String,
      createdAt: fields[4] as DateTime,
      folderId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Bookmark obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.favicon)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.folderId);
  }
}

class BookmarkFolderAdapter extends TypeAdapter<BookmarkFolder> {
  @override
  final int typeId = 5;

  @override
  BookmarkFolder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return BookmarkFolder(
      id: fields[0] as String,
      name: fields[1] as String,
      parentId: fields[2] as String?,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BookmarkFolder obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.parentId)
      ..writeByte(3)
      ..write(obj.createdAt);
  }
}