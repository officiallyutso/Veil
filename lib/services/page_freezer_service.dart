
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:webview_flutter/webview_flutter.dart';
class FrozenPage {
  final String id;
  final String url;
  final String title;
  final String html;
  final DateTime savedAt;
  
  FrozenPage({
    required this.id,
    required this.url,
    required this.title,
    required this.html,
    required this.savedAt,
  });
}

class PageFreezerService {
  static const String _boxName = 'frozen_pages';
  late Box<Map> _box;
  final _uuid = Uuid();
  
  Future<void> initialize() async {
    _box = await Hive.openBox<Map>(_boxName);
  }
  
  Future<String> freezePage(WebViewController controller, String url, String title) async {
    // Capture full HTML
    final html = await controller.runJavaScriptReturningResult(
      'document.documentElement.outerHTML'
    ) as String;
    
    // Save resources (images, CSS, etc.) for offline use
    final modifiedHtml = await _processResourcesForOffline(html, url);
    
    // Generate ID
    final id = _uuid.v4();
    
    // Save to Hive
    await _box.put(id, {
      'id': id,
      'url': url,
      'title': title,
      'html': modifiedHtml,
      'savedAt': DateTime.now().toIso8601String(),
    });
    
    return id;
  }
  
  Future<String> _processResourcesForOffline(String html, String baseUrl) async {
    // This is a simplified version. A full implementation would:
    // 1. Parse the HTML
    // 2. Find all resources (images, CSS, JS)
    // 3. Download and save them locally
    // 4. Update the HTML to point to local resources
    
    // For now, we'll just return the original HTML
    return html;
  }
  
  Future<List<FrozenPage>> getAllFrozenPages() async {
    final pages = _box.values.map((map) {
      return FrozenPage(
        id: map['id'],
        url: map['url'],
        title: map['title'],
        html: map['html'],
        savedAt: DateTime.parse(map['savedAt']),
      );
    }).toList();
    
    // Sort by saved time (newest first)
    pages.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    
    return pages;
  }
  
  Future<FrozenPage?> getFrozenPage(String id) async {
    final map = _box.get(id);
    if (map == null) return null;
    
    return FrozenPage(
      id: map['id'],
      url: map['url'],
      title: map['title'],
      html: map['html'],
      savedAt: DateTime.parse(map['savedAt']),
    );
  }
  
  Future<void> deleteFrozenPage(String id) async {
    await _box.delete(id);
  }
  
  Future<void> loadFrozenPage(WebViewController controller, String id) async {
    final page = await getFrozenPage(id);
    if (page != null) {
      await controller.loadHtmlString(page.html, baseUrl: page.url);
    }
  }
}