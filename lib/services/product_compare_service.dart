import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class Product {
  final String name;
  final double price;
  final String currency;
  final String imageUrl;
  final String productUrl;
  final String merchant;
  
  Product({
    required this.name,
    required this.price,
    required this.currency,
    required this.imageUrl,
    required this.productUrl,
    required this.merchant,
  });
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
        productUrl: url,
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
    ];
    
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        return elements.first.text.trim();
      }
    }
    
    // Try meta tags
    final metaTags = document.querySelectorAll('meta[property="og:title"]');
    if (metaTags.isNotEmpty) {
      final content = metaTags.first.attributes['content'];
      if (content != null && content.isNotEmpty) {
        return content.trim();
      }
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
    ];
    
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        final priceText = elements.first.text;
        return _parsePrice(priceText);
      }
    }
    
    // Try meta tags
    final metaTags = document.querySelectorAll('meta[property="product:price:amount"]');
    if (metaTags.isNotEmpty) {
      final content = metaTags.first.attributes['content'];
      if (content != null && content.isNotEmpty) {
        return double.tryParse(content) ?? 0.0;
      }
    }
    
    return 0.0;
  }
  
  double _parsePrice(String priceText) {
    // Remove currency symbols and non-numeric characters
    final numericText = priceText.replaceAll(RegExp(r'[^\d.,]'), '');
    
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
    } else if (numericText.contains(',')) {
      // Only comma is present, assume it's the decimal separator
      normalizedText = numericText.replaceAll(',', '.');
    }
    
    return double.tryParse(normalizedText) ?? 0.0;
  }
  
  String _extractCurrency(Document document) {
    // Try common currency selectors
    final selectors = [
      'span.currency',
      '[itemprop="priceCurrency"]',
    ];
    
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        return elements.first.text.trim();
      }
    }
    
    // Try meta tags
    final metaTags = document.querySelectorAll('meta[property="product:price:currency"]');
    if (metaTags.isNotEmpty) {
      final content = metaTags.first.attributes['content'];
      if (content != null && content.isNotEmpty) {
        return content.trim();
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
    ];
    
    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        final src = elements.first.attributes['src'];
        if (src != null && src.isNotEmpty) {
          // Convert relative URL to absolute if needed
          if (src.startsWith('http')) {
            return src;
          } else {
            final baseUri = Uri.parse(baseUrl);
            return Uri(
              scheme: baseUri.scheme,
              host: baseUri.host,
              path: src.startsWith('/') ? src : '/${src}',
            ).toString();
          }
        }
      }
    }
    
    // Try meta tags
    final metaTags = document.querySelectorAll('meta[property="og:image"]');
    if (metaTags.isNotEmpty) {
      final content = metaTags.first.attributes['content'];
      if (content != null && content.isNotEmpty) {
        return content;
      }
    }
    
    return '';
  }
  
  String _extractMerchant(Document document, String url) {
    // Try meta tags
    final metaTags = document.querySelectorAll('meta[property="og:site_name"]');
    if (metaTags.isNotEmpty) {
      final content = metaTags.first.attributes['content'];
      if (content != null && content.isNotEmpty) {
        return content.trim();
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
        return parts[0].substring(0, 1).toUpperCase() + parts[0].substring(1);
      }
      
      return domain;
    } catch (e) {
      return '';
    }
  }
  
  Future<List<Product>> findAlternatives(Product product) async {
    final alternatives = <Product>[];
    
    // Search for the product on popular shopping sites
    final searchTerms = product.name.split(' ').take(5).join(' ');
    
    // Define search URLs for different merchants
    final searchUrls = [
      'https://www.amazon.com/s?k=${Uri.encodeComponent(searchTerms)}',
      'https://www.walmart.com/search/?query=${Uri.encodeComponent(searchTerms)}',
      'https://www.ebay.com/sch/i.html?_nkw=${Uri.encodeComponent(searchTerms)}',
    ];
    
    // Limit to 3 searches to avoid overloading
    for (int i = 0; i < searchUrls.length && alternatives.length < 5; i++) {
      try {
        final url = searchUrls[i];
        final response = await http.get(Uri.parse(url));
        
        if (response.statusCode == 200) {
          final document = html_parser.parse(response.body);
          
          // Extract product listings (simplified - would need specific selectors for each site)
          final productElements = document.querySelectorAll('.product, .item, .result');
          
          for (final element in productElements.take(2)) { // Limit to 2 products per site
            final nameElement = element.querySelector('.title, .name, h2');
            final priceElement = element.querySelector('.price');
            final linkElement = element.querySelector('a');
            
            if (nameElement != null && priceElement != null && linkElement != null) {
              final name = nameElement.text.trim();
              final price = _parsePrice(priceElement.text);
              final href = linkElement.attributes['href'];
              
              if (name.isNotEmpty && price > 0 && href != null) {
                // Convert relative URL to absolute if needed
                final productUrl = href.startsWith('http') ? href : 'https://${Uri.parse(url).host}$href';
                
                // Only add if price is lower than original
                if (price < product.price) {
                  alternatives.add(Product(
                    name: name,
                    price: price,
                    currency: product.currency, // Assume same currency
                    imageUrl: '', // Would need to extract this
                    productUrl: productUrl,
                    merchant: Uri.parse(url).host.replaceAll('www.', ''),
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