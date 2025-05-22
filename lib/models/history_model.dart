import 'package:hive/hive.dart';

part 'history_model.g.dart';

@HiveType(typeId: 6)
class HistoryItem {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String url;
  
  @HiveField(2)
  String title;
  
  @HiveField(3)
  String favicon;
  
  @HiveField(4)
  DateTime visitedAt;
  
  HistoryItem({
    required this.id,
    required this.url,
    required this.title,
    this.favicon = '',
    DateTime? visitedAt,
  }) : this.visitedAt = visitedAt ?? DateTime.now();
}