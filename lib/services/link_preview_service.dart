import 'package:flutter/material.dart';
import 'package:html/dom.dart' as html_parser;
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:sentiment_dart/sentiment_dart.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;

class LinkPreviewService {
  
  Future<LinkPreviewData> getLinkPreview(String url) async {
    try {
      // Fetch metadataa
      final metadata = await MetadataFetch.extract(url);
      
      // Fetch page content for additional analysis
      final response = await http.get(Uri.parse(url));
      final document = html_parser.parse(response.body);
      
      // Extract text content
      document.querySelectorAll('script, style, meta, link, noscript').forEach((element) {
        element.remove();
      });
      final bodyText = document.body?.text ?? '';
      
      // Calculate word count
      final wordCount = _calculateWordCount(bodyText);
      
      // Analyze sentiment
      final sentimentScore = _analyzeSentiment(bodyText);
      
      // Check for paywall
      final hasPaywall = _detectPaywall(document);
      
      return LinkPreviewData(
        url: url,
        title: metadata?.title ?? 'No title',
        description: metadata?.description ?? 'No description',
        image: metadata?.image,
        wordCount: wordCount,
        sentimentScore: sentimentScore,
        hasPaywall: hasPaywall,
      );
    } catch (e) {
      return LinkPreviewData(
        url: url,
        title: 'Preview unavailable',
        description: 'Could not load preview data',
      );
    }
  }
  
  int _calculateWordCount(String text) {
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  }
  
  double _analyzeSentiment(String text) {
    if (text.isEmpty) return 0;
    
    // Take a sample of the text to analyze (for performance)
    final sampleText = text.length > 5000 
        ? text.substring(0, 5000) 
        : text;
    
    final result = Sentiment.analysis(sampleText);
    return result['comparative'] as double;
  }
  
  bool _detectPaywall(html_parser.Document document) {
    // Common paywall indicators
    final paywallKeywords = [
      'subscribe', 'subscription', 'premium', 'member', 'paid', 
      'sign up', 'unlock', 'continue reading', 'free trial'
    ];
    
    // Check for paywall elements
    final bodyText = document.body?.text.toLowerCase() ?? '';
    
    // Look for paywall-related elements
    final paywallElements = document.querySelectorAll(
      '.paywall, .subscription, .premium, .subscribe, [data-paywall], [data-subscription]'
    );
    
    if (paywallElements.isNotEmpty) {
      return true;
    }
    
    // Check for paywall keywords in prominent positions
    for (var keyword in paywallKeywords) {
      if (bodyText.contains(keyword)) {
        return true;
      }
    }
    
    return false;
  }
}

extension on SentimentResult {
  void operator [](String other) {}
}

class LinkPreviewData {
  final String url;
  final String title;
  final String description;
  final String? image;
  final int? wordCount;
  final double? sentimentScore;
  final bool? hasPaywall;
  
  LinkPreviewData({
    required this.url,
    required this.title,
    required this.description,
    this.image,
    this.wordCount,
    this.sentimentScore,
    this.hasPaywall,
  });
  
  String get sentimentLabel {
    if (sentimentScore == null) return 'Unknown';
    
    if (sentimentScore! > 0.3) {
      return 'Positive';
    } else if (sentimentScore! < -0.3) {
      return 'Negative';
    } else {
      return 'Neutral';
    }
  }
  
  String get readingTime {
    if (wordCount == null) return 'Unknown';
    
    // Average reading speed: 200-250 words per minute
    final minutes = (wordCount! / 225).ceil();
    
    if (minutes < 1) {
      return 'Less than a minute';
    } else if (minutes == 1) {
      return '1 minute';
    } else {
      return '$minutes minutes';
    }
  }
}