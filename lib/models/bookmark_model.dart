import 'package:hive/hive.dart';

part 'bookmark_model.g.dart';

@HiveType(typeId: 4)
class Bookmark {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String url;
  
  @HiveField(2)
  String title;
  
  @HiveField(3)
  String favicon;
  
  @HiveField(4)
  DateTime createdAt;
  
  @HiveField(5)
  String? folderId;
  
  Bookmark({
    required this.id,
    required this.url,
    required this.title,
    this.favicon = '',
    DateTime? createdAt,
    this.folderId,
  }) : this.createdAt = createdAt ?? DateTime.now();
}

@HiveType(typeId: 5)
class BookmarkFolder {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String? parentId;
  
  @HiveField(3)
  DateTime createdAt;
  
  BookmarkFolder({
    required this.id,
    required this.name,
    this.parentId,
    DateTime? createdAt,
  }) : this.createdAt = createdAt ?? DateTime.now();
}