
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SearchSource {
  final String name;
  final String iconPath;
  final String searchUrlTemplate;
  
  const SearchSource({
    required this.name,
    required this.iconPath,
    required this.searchUrlTemplate,
  });
  
  String getSearchUrl(String query) {
    return searchUrlTemplate.replaceAll('{query}', Uri.encodeComponent(query));
  }
}

class SearchElsewhereService {
  final List<SearchSource> _defaultSources = [
    SearchSource(
      name: 'Google',
      iconPath: 'assets/icons/google.svg',
      searchUrlTemplate: 'https://www.google.com/search?q={query}',
    ),
    SearchSource(
      name: 'Reddit',
      iconPath: 'assets/icons/reddit.svg',
      searchUrlTemplate: 'https://www.reddit.com/search?q={query}',
    ),
    SearchSource(
      name: 'Stack Overflow',
      iconPath: 'assets/icons/stackoverflow.svg',
      searchUrlTemplate: 'https://stackoverflow.com/search?q={query}',
    ),
    SearchSource(
      name: 'YouTube',
      iconPath: 'assets/icons/youtube.svg',
      searchUrlTemplate: 'https://www.youtube.com/results?search_query={query}',
    ),
    SearchSource(
      name: 'Wikipedia',
      iconPath: 'assets/icons/wikipedia.svg',
      searchUrlTemplate: 'https://en.wikipedia.org/wiki/Special:Search?search={query}',
    ),
  ];
  
  List<SearchSource> _customSources = [];
  
  List<SearchSource> get allSources => [..._defaultSources, ..._customSources];
  
  Future<void> initialize() async {
    // Load custom sources from preferences if needed
  }
  
  Future<String?> getSelectedText(WebViewController controller) async {
    try {
      final result = await controller.runJavaScriptReturningResult(
        'window.getSelection().toString()'
      );
      
      final selectedText = result.toString();
      if (selectedText.isNotEmpty && selectedText != 'null') {
        return selectedText.replaceAll('"', '');
      }
      
      return null;
    } catch (e) {
      print('Error getting selected text: $e');
      return null;
    }
  }
  
  Future<void> searchInSource(SearchSource source, String query, {bool useExternalBrowser = false}) async {
    final url = source.getSearchUrl(query);
    
    if (useExternalBrowser) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
    
    // If not using external browser, the caller should handle loading the URL in the app's WebView
  }
  
  void addCustomSource(SearchSource source) {
    _customSources.add(source);
    // Save to preferences if needed
  }
  
  void removeCustomSource(String name) {
    _customSources.removeWhere((source) => source.name == name);
    // Save to preferences if needed
  }
}