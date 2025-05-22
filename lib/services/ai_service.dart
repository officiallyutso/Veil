import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class AiService {
  final Gemini _gemini = Gemini.instance;
  bool _isInitialized = false;
  
  Future<void> initialize(String apiKey) async {
    if (!_isInitialized) {
      Gemini.init(apiKey: apiKey);
      _isInitialized = true;
    }
  }
  
  Future<String> summarizePage(String url) async {
    try {
      // Fetch the page content
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return 'Failed to load the page.';
      }
      
      // Parse HTML and extract main content
      final document = html_parser.parse(response.body);
      
      // Remove script, style, and other non-content elements
      document.querySelectorAll('script, style, meta, link, noscript').forEach((element) {
        element.remove();
      });
      
      // Extract text from body
      final bodyText = document.body?.text ?? '';
      
      // Truncate if too long (Gemini has token limits)
      final truncatedText = bodyText.length > 10000 
          ? bodyText.substring(0, 10000) + '...' 
          : bodyText;
      
      // Generate summary using Gemini
      final prompt = 'Summarize the following webpage content in 3-5 concise bullet points:\n\n$truncatedText';
      
      final result = await _gemini.text(prompt);
      
      return result.text ?? 'Unable to generate summary.';
    } catch (e) {
      return 'Error generating summary: $e';
    }
  }
  
  Future<String> explainCode(String code, String language) async {
    try {
      final prompt = 'Explain the following $language code in simple terms:\n\n```$language\n$code\n```';
      
      final result = await _gemini.text(prompt);
      
      return result.text ?? 'Unable to explain code.';
    } catch (e) {
      return 'Error explaining code: $e';
    }
  }
  
  Future<String> generateHighlights(String text) async {
    try {
      final prompt = 'Extract 3-5 key insights or important points from the following text:\n\n$text';
      
      final result = await _gemini.text(prompt);
      
      return result.text ?? 'Unable to generate highlights.';
    } catch (e) {
      return 'Error generating highlights: $e';
    }
  }
}