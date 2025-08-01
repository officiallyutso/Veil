import 'package:hive/hive.dart';

part 'receipt_model.g.dart';

// Receipt item model
@HiveType(typeId: 9)
class ReceiptItem {
  @HiveField(0)
  String name;
  @HiveField(1)
  double price;

  ReceiptItem({required this.name, required this.price});
}

// Main receipt model  
@HiveType(typeId: 8)
class Receipt {
  @HiveField(0)
  String id;
  @HiveField(1)
  String merchant;
  @HiveField(2)
  String date; // You can use DateTime, but UI expects String
  @HiveField(3)
  String orderNumber;
  @HiveField(4)
  List<ReceiptItem> items;
  @HiveField(5)
  double total;
  @HiveField(6)
  DateTime extractedAt;
  @HiveField(7)
  String sourceUrl;

  Receipt({
    required this.id,
    required this.merchant,
    required this.date,
    required this.orderNumber,
    required this.items,
    required this.total,
    required this.extractedAt,
    required this.sourceUrl,
  });
}
