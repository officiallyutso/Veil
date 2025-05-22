import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'tab_model.g.dart';

@HiveType(typeId: 2)
class Tab {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String url;
  
  @HiveField(2)
  String title;
  
  @HiveField(3)
  String favicon;
  
  @HiveField(4)
  bool isIncognito;
  
  @HiveField(5)
  double scrollPosition;
  
  @HiveField(6)
  DateTime lastAccessed;
  
  Tab({
    required this.id,
    required this.url,
    this.title = '',
    this.favicon = '',
    this.isIncognito = false,
    this.scrollPosition = 0.0,
    DateTime? lastAccessed,
  }) : this.lastAccessed = lastAccessed ?? DateTime.now();
}

@HiveType(typeId: 3)
class Session {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  List<Tab> tabs;
  
  @HiveField(3)
  DateTime createdAt;
  
  @HiveField(4)
  DateTime lastAccessed;
  
  Session({
    required this.id,
    required this.name,
    required this.tabs,
    DateTime? createdAt,
    DateTime? lastAccessed,
  }) : 
    this.createdAt = createdAt ?? DateTime.now(),
    this.lastAccessed = lastAccessed ?? DateTime.now();
}