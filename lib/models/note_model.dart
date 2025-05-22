import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 7)
class Note {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String title;
  
  @HiveField(2)
  String content;
  
  @HiveField(3)
  String sourceUrl;
  
  @HiveField(4)
  DateTime createdAt;
  
  @HiveField(5)
  DateTime updatedAt;
  
  Note({
    required this.id,
    required this.title,
    required this.content,
    this.sourceUrl = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.updatedAt = updatedAt ?? DateTime.now();
}