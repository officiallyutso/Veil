
import 'package:webview_flutter/webview_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class Receipt {
  final String id;
  final String merchant;
  final String date;
  final double total;
  final List<ReceiptItem> items;
  final String orderNumber;
  final String sourceUrl;
  final DateTime extractedAt;
  
  Receipt({
    required this.id,
    required this.merchant,
    required this.date,
    required this.total,
    required this.items,
    required this.orderNumber,
    required this.sourceUrl,
    required this.extractedAt,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'merchant': merchant,
      'date': date,
      'total': total,
      'items': items.map((item) => item.toJson()).toList(),
      'orderNumber': orderNumber,
      'sourceUrl': sourceUrl,
      'extractedAt': extractedAt.toIso8601String(),
    };
  }
  
  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'],
      merchant: json['merchant'],
      date: json['date'],
      total: json['total'],
      items: (json['items'] as List).map((item) => ReceiptItem.fromJson(item)).toList(),
      orderNumber: json['orderNumber'],
      sourceUrl: json['sourceUrl'],
      extractedAt: DateTime.parse(json['extractedAt']),
    );
  }
}

class ReceiptItem {
  final String name;
  final double price;
  final int quantity;
  
  ReceiptItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }
  
  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'],
      price: json['price'],
      quantity: json['quantity'] ?? 1,
    );
  }
}

class ReceiptExtractorService {
  static const String _boxName = 'receipts';
  late Box<Map> _box;
  final _uuid = Uuid();
  
  Future<void> initialize() async {
    _box = await Hive.openBox<Map>(_boxName);
  }
  
  Future<Receipt?> extractReceiptFromPage(WebViewController controller, String url) async {
    try {
      // Get page HTML
      final html = await controller.runJavaScriptReturningResult(
        'document.documentElement.outerHTML'
      ) as String;
      
      // Extract receipt data using RegExp patterns
      final merchant = _extractMerchant(html);
      final date = _extractDate(html);
      final total = _extractTotal(html);
      final items = _extractItems(html);
      final orderNumber = _extractOrderNumber(html);
      
      if (merchant.isEmpty || date.isEmpty || total <= 0) {
        return null; // Not enough data to consider it a receipt
      }
      
      final receipt = Receipt(
        id: _uuid.v4(),
        merchant: merchant,
        date: date,
        total: total,
        items: items,
        orderNumber: orderNumber,
        sourceUrl: url,
        extractedAt: DateTime.now(),
      );
      
      // Save to Hive
      await _box.put(receipt.id, receipt.toJson());
      
      return receipt;
    } catch (e) {
      print('Error extracting receipt: $e');
      return null;
    }
  }
  
  String _extractMerchant(String html) {
    // Look for common merchant indicators
    final merchantRegex = RegExp(
      r'(?:from|by|merchant|vendor|store|shop)[\s:]*([A-Za-z0-9\s\.,&]+)(?:\s|<|$)',
      caseSensitive: false
    );
    
        final match = merchantRegex.firstMatch(html);
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim();
    }
    
    // Try to find merchant in title or header
    final titleRegex = RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false);
    final titleMatch = titleRegex.firstMatch(html);
    if (titleMatch != null && titleMatch.group(1) != null) {
      final title = titleMatch.group(1)!;
      if (title.contains('Receipt') || title.contains('Order')) {
        // Extract the first part of the title as merchant
        final parts = title.split('-');
        if (parts.isNotEmpty) {
          return parts[0].trim();
        }
      }
    }
    
    return '';
  }
  
  String _extractDate(String html) {
    // Look for date patterns
    final dateRegex = RegExp(
      r'(?:date|ordered|purchased|transaction)[\s:]*([A-Za-z0-9\s\.,\/\-]+\d{4})',
      caseSensitive: false
    );
    
    final match = dateRegex.firstMatch(html);
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim();
    }
    
    // Try more specific date formats
    final specificDateRegex = RegExp(
      r'\b(\d{1,2}[\/\-\.]\d{1,2}[\/\-\.]\d{2,4})\b',
      caseSensitive: false
    );
    
    final specificMatch = specificDateRegex.firstMatch(html);
    if (specificMatch != null && specificMatch.group(1) != null) {
      return specificMatch.group(1)!.trim();
    }
    
    return '';
  }
  
  double _extractTotal(String html) {
    // Look for total amount patterns
    final totalRegex = RegExp(
      r'(?:total|amount|sum|charged)[\s:]*[\$£€]?\s*(\d+[.,]\d{2})',
      caseSensitive: false
    );
    
    final match = totalRegex.firstMatch(html);
    if (match != null && match.group(1) != null) {
      final totalStr = match.group(1)!.replaceAll(',', '.');
      return double.tryParse(totalStr) ?? 0.0;
    }
    
    // Try more specific currency format
    final currencyRegex = RegExp(
      r'\$\s*(\d+\.\d{2})',
      caseSensitive: false
    );
    
    final currencyMatch = currencyRegex.firstMatch(html);
    if (currencyMatch != null && currencyMatch.group(1) != null) {
      return double.tryParse(currencyMatch.group(1)!) ?? 0.0;
    }
    
    return 0.0;
  }
  
  List<ReceiptItem> _extractItems(String html) {
    final items = <ReceiptItem>[];
    
    // Look for item patterns in tables or lists
    final itemRegex = RegExp(
      r'<tr[^>]*>.*?<td[^>]*>(.*?)</td>.*?<td[^>]*>.*?(\$\s*\d+\.\d{2}).*?</td>.*?</tr>',
      caseSensitive: false,
      dotAll: true
    );
    
    final matches = itemRegex.allMatches(html);
    for (final match in matches) {
      if (match.group(1) != null && match.group(2) != null) {
        final name = match.group(1)!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        final priceStr = match.group(2)!.replaceAll('\$', '').trim();
        final price = double.tryParse(priceStr) ?? 0.0;
        
        if (name.isNotEmpty && price > 0) {
          items.add(ReceiptItem(name: name, price: price));
        }
      }
    }
    
    // If no items found in tables, try list items
    if (items.isEmpty) {
      final listItemRegex = RegExp(
        r'<li[^>]*>.*?([A-Za-z0-9\s\.,&]+).*?(\$\s*\d+\.\d{2}).*?</li>',
        caseSensitive: false,
        dotAll: true
      );
      
      final listMatches = listItemRegex.allMatches(html);
      for (final match in listMatches) {
        if (match.group(1) != null && match.group(2) != null) {
          final name = match.group(1)!.trim();
          final priceStr = match.group(2)!.replaceAll('\$', '').trim();
          final price = double.tryParse(priceStr) ?? 0.0;
          
          if (name.isNotEmpty && price > 0) {
            items.add(ReceiptItem(name: name, price: price));
          }
        }
      }
    }
    
    return items;
  }
  
  String _extractOrderNumber(String html) {
    // Look for order number patterns
    final orderRegex = RegExp(
      r'(?:order|confirmation|reference|invoice)[\s\#\:]*([A-Za-z0-9\-]+)',
      caseSensitive: false
    );
    
    final match = orderRegex.firstMatch(html);
    if (match != null && match.group(1) != null) {
      return match.group(1)!.trim();
    }
    
    return '';
  }
  
  Future<List<Receipt>> getAllReceipts() async {
    final receipts = _box.values.map((map) {
      return Receipt.fromJson(Map<String, dynamic>.from(map));
    }).toList();
    
    // Sort by extracted time (newest first)
    receipts.sort((a, b) => b.extractedAt.compareTo(a.extractedAt));
    
    return receipts;
  }
  
  Future<Receipt?> getReceipt(String id) async {
    final map = _box.get(id);
    if (map == null) return null;
    
    return Receipt.fromJson(Map<String, dynamic>.from(map));
  }
  
  Future<void> deleteReceipt(String id) async {
    await _box.delete(id);
  }
  
  Future<void> clearAllReceipts() async {
    await _box.clear();
  }
}