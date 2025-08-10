
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class Product {
  final String name;
  final double price;
  final String currency;
  final String imageUrl;
  final String url; // Changed from productUrl to url
  final String merchant;
  
  Product({
    required this.name,
    required this.price,
    required this.currency,
    required this.imageUrl,
    required this.url, // Changed from productUrl to url
    required this.merchant,
  });
  
  // Optional: Add a getter for backward compatibility
  String get productUrl => url;
  
  // Optional: Add copyWith method for easier object manipulation
  Product copyWith({
    String? name,
    double? price,
    String? currency,
    String? imageUrl,
    String? url,
    String? merchant,
  }) {
    return Product(
      name: name ?? this.name,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      imageUrl: imageUrl ?? this.imageUrl,
      url: url ?? this.url,
      merchant: merchant ?? this.merchant,
    );
  }
  
  // Optional: Add toString method for debugging
  @override
  String toString() {
    return 'Product(name: $name, price: $price, currency: $currency, url: $url, merchant: $merchant)';
  }
  
  // Optional: Add equality operators
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        other.name == name &&
        other.price == price &&
        other.currency == currency &&
        other.imageUrl == imageUrl &&
        other.url == url &&
        other.merchant == merchant;
  }
  
  @override
  int get hashCode {
    return name.hashCode ^
        price.hashCode ^
        currency.hashCode ^
        imageUrl.hashCode ^
        url.hashCode ^
        merchant.hashCode;
  }
}

class ProductCompareService {
  Future<Product?> extractProductFromPage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return null;
      }
      
      final document = html_parser.parse(response.body);
      
      // Extract product details
      final name = _extractProductName(document);
      final price = _extractProductPrice(document);
      final currency = _extractCurrency(document);
      final imageUrl = _extractProductImage(document, url);
      
      if (name.isEmpty || price <= 0) {
        return null; // Not enough data to consider it a product
      }
      
      final merchant = _extractMerchant(document, url);
      
      return Product(
        name: name,
        price: price,
        currency: currency,
        imageUrl: imageUrl,
        url: url, // Changed from productUrl to url
        merchant: merchant,
      );
    } catch (e) {
      print('Error extracting product: $e');
      return null;
    }
  }
  
  String _extractProductName(Document document) {
    // Try common product name selectors
    final selectors = [
      'h1.product-title',
      'h1.product-name',
      'h1.product',
      'h1[itemprop="name"]',
      'h1',
      '[data-testid="product-title"]',
      '.product-title',
      '.product-name',
    ];
    
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        final text = elements.first.text.trim();
        if (text.isNotEmpty) {
          return text;
        }
      }
    }
    
    // Try meta tags
    final metaSelectors = [
      'meta[property="og:title"]',
      'meta[name="twitter:title"]',
      'meta[property="product:name"]',
    ];
    
    for (final selector in metaSelectors) {
      final metaTags = document.querySelectorAll(selector);
      if (metaTags.isNotEmpty) {
        final content = metaTags.first.attributes['content'];
        if (content != null && content.trim().isNotEmpty) {
          return content.trim();
        }
      }
    }
    
    // Try title tag as last resort
    final titleElement = document.querySelector('title');
    if (titleElement != null) {
      return titleElement.text.trim();
    }
    
    return '';
  }
  
  double _extractProductPrice(Document document) {
    // Try common price selectors
    final selectors = [
      'span.price',
      'div.price',
      'p.price',
      '[itemprop="price"]',
      '.product-price',
      '.offer-price',
      '.current-price',
      '.sale-price',
      '[data-testid="price"]',
      '.price-current',
      '.price-now',
    ];
    
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        final priceText = elements.first.text;
        final price = _parsePrice(priceText);
        if (price > 0) {
          return price;
        }
      }
    }
    
    // Try meta tags
    final metaSelectors = [
      'meta[property="product:price:amount"]',
      'meta[property="og:price:amount"]',
      'meta[name="twitter:data1"]',
    ];
    
    for (final selector in metaSelectors) {
      final metaTags = document.querySelectorAll(selector);
      if (metaTags.isNotEmpty) {
        final content = metaTags.first.attributes['content'];
        if (content != null && content.isNotEmpty) {
          final price = double.tryParse(content) ?? 0.0;
          if (price > 0) {
            return price;
          }
        }
      }
    }
    
    return 0.0;
  }
  
  double _parsePrice(String priceText) {
    if (priceText.isEmpty) return 0.0;
    
    // Remove currency symbols and non-numeric characters except . and ,
    final numericText = priceText.replaceAll(RegExp(r'[^\d.,]'), '');
    
    if (numericText.isEmpty) return 0.0;
    
    // Handle different decimal separators
    String normalizedText = numericText;
    
    if (numericText.contains(',') && numericText.contains('.')) {
      // If both . and , are present, the last one is likely the decimal separator
      final lastDotIndex = numericText.lastIndexOf('.');
      final lastCommaIndex = numericText.lastIndexOf(',');
      
      if (lastCommaIndex > lastDotIndex) {
        // Comma is the decimal separator
        normalizedText = numericText.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // Dot is the decimal separator
        normalizedText = numericText.replaceAll(',', '');
      }
    } else if (numericText.contains(',') && !numericText.contains('.')) {
      // Only comma is present
      final commaIndex = numericText.lastIndexOf(',');
      final afterComma = numericText.substring(commaIndex + 1);
      
      // If there are 3 or more digits after comma, it's likely a thousands separator
      if (afterComma.length >= 3) {
        normalizedText = numericText.replaceAll(',', '');
      } else {
        // Likely a decimal separator
        normalizedText = numericText.replaceAll(',', '.');
      }
    }
    
    return double.tryParse(normalizedText) ?? 0.0;
  }
  
  String _extractCurrency(Document document) {
    // Try common currency selectors
    final selectors = [
      'span.currency',
      '[itemprop="priceCurrency"]',
      '.currency-symbol',
      '.price-currency',
    ];
    
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        final currency = elements.first.text.trim();
        if (currency.isNotEmpty) {
          return currency;
        }
      }
    }
    
    // Try meta tags
    final metaSelectors = [
      'meta[property="product:price:currency"]',
      'meta[property="og:price:currency"]',
    ];
    
    for (final selector in metaSelectors) {
      final metaTags = document.querySelectorAll(selector);
      if (metaTags.isNotEmpty) {
        final content = metaTags.first.attributes['content'];
        if (content != null && content.trim().isNotEmpty) {
          return content.trim();
        }
      }
    }
    
    // Default to USD if not found
    return 'USD';
  }
  
  String _extractProductImage(Document document, String baseUrl) {
    // Try common image selectors
    final selectors = [
      'img.product-image',
      'img[itemprop="image"]',
      '.product-image img',
      '#product-image',
      '.product-photo img',
      '[data-testid="product-image"]',
      '.main-image img',
    ];
    
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        final src = elements.first.attributes['src'] ?? 
                   elements.first.attributes['data-src'];
        if (src != null && src.isNotEmpty) {
          return _makeAbsoluteUrl(src, baseUrl);
        }
      }
    }
    
    // Try meta tags
    final metaSelectors = [
      'meta[property="og:image"]',
      'meta[name="twitter:image"]',
      'meta[property="product:image"]',
    ];
    
    for (final selector in metaSelectors) {
      final metaTags = document.querySelectorAll(selector);
      if (metaTags.isNotEmpty) {
        final content = metaTags.first.attributes['content'];
        if (content != null && content.isNotEmpty) {
          return _makeAbsoluteUrl(content, baseUrl);
        }
      }
    }
    
    return '';
  }
  
  String _makeAbsoluteUrl(String url, String baseUrl) {
    if (url.startsWith('http')) {
      return url;
    }
    
    try {
      final baseUri = Uri.parse(baseUrl);
      if (url.startsWith('//')) {
        return '${baseUri.scheme}:$url';
      } else if (url.startsWith('/')) {
        return '${baseUri.scheme}://${baseUri.host}$url';
      } else {
        return '${baseUri.scheme}://${baseUri.host}/${url}';
      }
    } catch (e) {
      return url;
    }
  }
  
  String _extractMerchant(Document document, String url) {
    // Try meta tags
    final metaSelectors = [
      'meta[property="og:site_name"]',
      'meta[name="application-name"]',
      'meta[name="apple-mobile-web-app-title"]',
    ];
    
    for (final selector in metaSelectors) {
      final metaTags = document.querySelectorAll(selector);
      if (metaTags.isNotEmpty) {
        final content = metaTags.first.attributes['content'];
        if (content != null && content.trim().isNotEmpty) {
          return content.trim();
        }
      }
    }
    
    // Extract from URL
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      
      // Remove www. and get the domain name
      final domain = host.startsWith('www.') ? host.substring(4) : host;
      
      // Get the first part of the domain (before the first dot)
      final parts = domain.split('.');
      if (parts.isNotEmpty) {
        final merchantName = parts[0];
        return merchantName.substring(0, 1).toUpperCase() + 
               merchantName.substring(1).toLowerCase();
      }
      
      return domain;
    } catch (e) {
      return 'Unknown';
    }
  }
  
  Future<List<Product>> findAlternatives(Product product) async {
    final alternatives = <Product>[];
    
    // Search for the product on popular shopping sites
    final searchTerms = product.name
        .split(' ')
        .where((term) => term.length > 2) // Filter out short words
        .take(5)
        .join(' ');
    
    if (searchTerms.isEmpty) {
      return alternatives;
    }
    
    // Define search URLs for different merchants
    final searchUrls = [
      'https://www.amazon.com/s?k=${Uri.encodeComponent(searchTerms)}',
      'https://www.walmart.com/search/?query=${Uri.encodeComponent(searchTerms)}',
      'https://www.ebay.com/sch/i.html?_nkw=${Uri.encodeComponent(searchTerms)}',
    ];
    
    // Limit to 3 searches to avoid overloading
    for (int i = 0; i < searchUrls.length && alternatives.length < 5; i++) {
      try {
        final searchUrl = searchUrls[i];
        final response = await http.get(
          Uri.parse(searchUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        );
        
        if (response.statusCode == 200) {
          final document = html_parser.parse(response.body);
          
          // Extract product listings (simplified - would need specific selectors for each site)
          final productElements = document.querySelectorAll(
            '.product, .item, .result, [data-component-type="s-search-result"]'
          );
          
          for (final element in productElements.take(2)) { // Limit to 2 products per site
            final nameElement = element.querySelector(
              '.title, .name, h2, .product-title, [data-cy="listing-row-title"]'
            );
            final priceElement = element.querySelector(
              '.price, .a-price-whole, .notranslate'
            );
            final linkElement = element.querySelector('a');
            
            if (nameElement != null && priceElement != null && linkElement != null) {
              final name = nameElement.text.trim();
              final price = _parsePrice(priceElement.text);
              final href = linkElement.attributes['href'];
              
              if (name.isNotEmpty && price > 0 && href != null) {
                // Convert relative URL to absolute if needed
                final productUrl = _makeAbsoluteUrl(href, searchUrl);
                
                // Only add if price is different from original (could be higher or lower)
                if ((price - product.price).abs() > 0.01) { // Allow small price differences
                  alternatives.add(Product(
                    name: name,
                    price: price,
                    currency: product.currency, // Assume same currency
                    imageUrl: '', // Would need to extract this
                    url: productUrl, // Changed from productUrl to url
                    merchant: Uri.parse(searchUrl).host.replaceAll('www.', ''),
                  ));
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error searching for alternatives: $e');
      }
    }
    
    // Sort by price (lowest first)
    alternatives.sort((a, b) => a.price.compareTo(b.price));
    
    return alternatives;
  }
}
