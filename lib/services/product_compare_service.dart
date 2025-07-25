import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class ProductCompareService {
  static const Duration _requestDelay = Duration(milliseconds: 800);
  DateTime _lastRequest = DateTime.now().subtract(_requestDelay);
  final Map<String, DateTime> _lastRequestByDomain = {};

  Future<Product?> extractProductFromPage(String url) async {
    await _enforceRateLimit(url);
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
          'Accept-Encoding': 'gzip, deflate',
          'Connection': 'keep-alive',
        },
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode != 200) {
        print('HTTP ${response.statusCode} for $url');
        return null;
      }

      final document = html_parser.parse(response.body);
      
      final name = _extractProductName(document);
      final price = _extractProductPrice(document);
      final currency = _extractCurrency(document);
      final imageUrl = _extractProductImage(document, url);

      if (name.isEmpty || price <= 0) {
        return null;
      }

      final merchant = _extractMerchant(document, url);

      return Product(
        name: name,
        price: price,
        currency: currency,
        imageUrl: imageUrl,
        url: url,
        merchant: merchant,
      );
    } catch (e) {
      print('Error extracting product from $url: $e');
      return null;
    }
  }

  Future<void> _enforceRateLimit(String url) async {
    final domain = Uri.parse(url).host;
    final now = DateTime.now();
    
    // Global rate limit
    final timeSinceLastRequest = now.difference(_lastRequest);
    if (timeSinceLastRequest < _requestDelay) {
      await Future.delayed(_requestDelay - timeSinceLastRequest);
    }
    
    // Per-domain rate limit (more restrictive)
    final lastDomainRequest = _lastRequestByDomain[domain];
    if (lastDomainRequest != null) {
      final timeSinceLastDomainRequest = now.difference(lastDomainRequest);
      const domainDelay = Duration(seconds: 2);
      if (timeSinceLastDomainRequest < domainDelay) {
        await Future.delayed(domainDelay - timeSinceLastDomainRequest);
      }
    }
    
    _lastRequest = DateTime.now();
    _lastRequestByDomain[domain] = DateTime.now();
  }

  Future<List<Product>> findAlternatives(Product product) async {
    final alternatives = <Product>[];
    
    // Create better search terms
    final searchTerms = _createSearchTerms(product.name);
    if (searchTerms.isEmpty) return alternatives;

    final searchUrls = [
      'https://www.amazon.com/s?k=${Uri.encodeComponent(searchTerms)}',
      'https://www.walmart.com/search/?query=${Uri.encodeComponent(searchTerms)}',
      'https://www.ebay.com/sch/i.html?_nkw=${Uri.encodeComponent(searchTerms)}',
    ];

    for (int i = 0; i < searchUrls.length && alternatives.length < 6; i++) {
      try {
        await _enforceRateLimit(searchUrls[i]);
        
        final response = await http.get(
          Uri.parse(searchUrls[i]),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ).timeout(Duration(seconds: 15));

        if (response.statusCode == 200) {
          final products = await _extractProductsFromSearchResults(
            response.body, 
            searchUrls[i], 
            product
          );
          alternatives.addAll(products);
        }
      } catch (e) {
        print('Error searching ${searchUrls[i]}: $e');
        continue;
      }
    }

    // Remove duplicates and sort by price
    final uniqueProducts = _removeDuplicates(alternatives);
    uniqueProducts.sort((a, b) => a.price.compareTo(b.price));
    
    return uniqueProducts.take(5).toList();
  }

  String _createSearchTerms(String productName) {
    // Remove common words and extract meaningful terms
    final stopWords = {'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'};
    final words = productName
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && !stopWords.contains(word))
        .take(4)
        .join(' ');
    
    return words;
  }

  Future<List<Product>> _extractProductsFromSearchResults(
    String html, 
    String searchUrl, 
    Product originalProduct
  ) async {
    final products = <Product>[];
    final document = html_parser.parse(html);
    
    // Different selectors for different sites
    List<String> selectors = [];
    final domain = Uri.parse(searchUrl).host;
    
    if (domain.contains('amazon')) {
      selectors = ['[data-component-type="s-search-result"]', '.s-result-item'];
    } else if (domain.contains('walmart')) {
      selectors = ['[data-testid="item"]', '.search-result-gridview-item'];
    } else if (domain.contains('ebay')) {
      selectors = ['.s-item', '.srp-results .s-item'];
    } else {
      selectors = ['.product', '.item', '.result'];
    }

    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      
      for (final element in elements.take(3)) {
        try {
          final product = await _extractProductFromElement(element, searchUrl, originalProduct);
          if (product != null) {
            products.add(product);
          }
        } catch (e) {
          continue; // Skip problematic elements
        }
      }
      
      if (products.isNotEmpty) break; // Found products with this selector
    }

    return products;
  }

  Future<Product?> _extractProductFromElement(
    Element element, 
    String baseUrl, 
    Product originalProduct
  ) async {
    final nameSelectors = [
      'h2 a', '.product-title', '.item-title', 'h3 a', '.title a', 
      '[data-cy="listing-row-title"]', '.s-size-mini .a-color-base'
    ];
    
    final priceSelectors = [
      '.price', '.a-price-whole', '.notranslate', '.price-current',
      '.sr-price', '.u-strikethrough', '.price-display'
    ];
    
    final linkSelectors = ['a', 'h2 a', 'h3 a', '.product-title a'];

    String? name;
    double? price;
    String? href;

    // Extract name
    for (final selector in nameSelectors) {
      final nameElement = element.querySelector(selector);
      if (nameElement != null) {
        name = nameElement.text.trim();
        if (name.isNotEmpty) break;
      }
    }

    // Extract price
    for (final selector in priceSelectors) {
      final priceElement = element.querySelector(selector);
      if (priceElement != null) {
        price = _parsePrice(priceElement.text);
        if (price > 0) break;
      }
    }

    // Extract link
    for (final selector in linkSelectors) {
      final linkElement = element.querySelector(selector);
      if (linkElement != null) {
        href = linkElement.attributes['href'];
        if (href != null && href.isNotEmpty) break;
      }
    }

    if (name == null || name.isEmpty || price == null || price <= 0 || href == null) {
      return null;
    }

    // Only include if price is meaningfully different
    if ((price - originalProduct.price).abs() < 1.0) {
      return null;
    }

    final productUrl = _makeAbsoluteUrl(href, baseUrl);
    final merchant = Uri.parse(baseUrl).host.replaceAll('www.', '');

    return Product(
      name: name,
      price: price,
      currency: originalProduct.currency,
      imageUrl: '', // Could extract this too
      url: productUrl,
      merchant: merchant,
    );
  }

  List<Product> _removeDuplicates(List<Product> products) {
    final seen = <String>{};
    return products.where((product) {
      final key = '${product.name.toLowerCase()}_${product.price}_${product.merchant}';
      return seen.add(key);
    }).toList();
  }

  // ... (keep existing helper methods like _extractProductName, _parsePrice, etc.)
}
