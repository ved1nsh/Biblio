import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  static const String _apiKey =
      'YOUR_API_KEY_HERE'; // IMPORTANT: Use a .env file instead!
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;

  AiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );
    _visionModel = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
  }

  Future<Map<String, String>> explainText({
    required String selectedText,
    required String contextText,
    required String bookTitle,
  }) async {
    final prompt = '''
      You are a literary assistant for the book "$bookTitle".
      
      Analyze this selected text: "$selectedText"
      Context from the paragraph: "$contextText"

      Provide a response in strict JSON format with exactly two keys:
      1. "definition": A concise dictionary definition or explanation of the selected text, in simple terms.
      2. "contextAnalysis": Explain the meaning of the text in context of the paragraph, book and story in simple terms. Keep it under 3 sentences.

      Do not use markdown formatting like ```json. Just raw JSON.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      final cleanJson =
          response.text?.replaceAll('```json', '').replaceAll('```', '').trim();

      if (cleanJson != null) {
        final Map<String, dynamic> data = jsonDecode(cleanJson);
        return {
          'definition':
              data['definition']?.toString() ?? 'Definition unavailable',
          'contextAnalysis':
              data['contextAnalysis']?.toString() ?? 'Context unavailable',
        };
      }
    } catch (e) {
      debugPrint('AI Error: $e');

      if (e.toString().contains('429') ||
          e.toString().contains('RESOURCE_EXHAUSTED')) {
        return {
          'definition': 'Rate Limit Reached',
          'contextAnalysis': 'Too many requests. Please try again in a moment.',
        };
      }

      return {
        'definition': 'Connection Error',
        'contextAnalysis':
            'Could not reach the AI service. Please check your internet connection.',
      };
    }

    return {
      'definition': 'No Data',
      'contextAnalysis': 'The AI returned an empty response.',
    };
  }

  Future<String> askFollowUpQuestion({
    required String selectedText,
    required String contextText,
    required String bookTitle,
    required String definition,
    required String contextAnalysis,
    required String question,
    String conversationHistory = '',
  }) async {
    final prompt = '''
      You are a literary assistant for the book "$bookTitle".
      
      Original text analyzed: "$selectedText"
      Context: "$contextText"
      Definition given: "$definition"
      Context analysis given: "$contextAnalysis"
      
      ${conversationHistory.isNotEmpty ? 'Previous conversation:\n$conversationHistory\n' : ''}
      
      User's follow-up question: "$question"
      
      Provide a helpful, concise answer to the user's question. Keep the response conversational and under 4 sentences.
      Return ONLY the answer text, no JSON formatting needed.
    ''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim();
      } else {
        throw Exception('Empty response from AI');
      }
    } catch (e) {
      debugPrint('❌ Follow-up question error: $e');

      if (e.toString().contains('429') ||
          e.toString().contains('RESOURCE_EXHAUSTED')) {
        throw Exception('Rate limit reached. Please try again in a moment.');
      }

      throw Exception('Failed to get answer. Please try again.');
    }
  }

  /// Analyze an image crop captured via circle-to-search.
  Future<String> analyzeImage({
    required Uint8List imageBytes,
    required String bookTitle,
  }) async {
    final prompt = '''
You are a literary assistant for the book "$bookTitle".

The user has circled a region on the page of this book. Analyze the content inside the circled area — it may contain text, diagrams, illustrations, or a mix.

Provide a concise, helpful analysis:
- If it's text: explain its meaning, define any difficult words, and describe the context.
- If it's a diagram/chart/illustration: describe what it shows and its significance.
- If it's a mix: address both the textual and visual elements.

Keep your response under 6 sentences. Be conversational and clear.
''';

    try {
      final content = [
        Content.multi([TextPart(prompt), DataPart('image/png', imageBytes)]),
      ];
      final response = await _visionModel.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim();
      } else {
        throw Exception('Empty response from AI');
      }
    } catch (e) {
      debugPrint('❌ Image analysis error: $e');

      if (e.toString().contains('429') ||
          e.toString().contains('RESOURCE_EXHAUSTED')) {
        throw Exception('Rate limit reached. Please try again in a moment.');
      }

      throw Exception('Failed to analyze image. Please try again.');
    }
  }

  /// Ask a follow-up question about a previously analyzed image.
  Future<String> askImageFollowUp({
    required Uint8List imageBytes,
    required String bookTitle,
    required String previousAnalysis,
    required String question,
    String conversationHistory = '',
  }) async {
    final prompt = '''
You are a literary assistant for the book "$bookTitle".

The user previously circled a region on the page and you analyzed it.
Your previous analysis: "$previousAnalysis"

${conversationHistory.isNotEmpty ? 'Previous conversation:\n$conversationHistory\n' : ''}

User's follow-up question: "$question"

Provide a helpful, concise answer. Keep the response under 4 sentences.
''';

    try {
      final content = [
        Content.multi([TextPart(prompt), DataPart('image/png', imageBytes)]),
      ];
      final response = await _visionModel.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim();
      } else {
        throw Exception('Empty response from AI');
      }
    } catch (e) {
      debugPrint('❌ Image follow-up error: $e');

      if (e.toString().contains('429') ||
          e.toString().contains('RESOURCE_EXHAUSTED')) {
        throw Exception('Rate limit reached. Please try again in a moment.');
      }

      throw Exception('Failed to get answer. Please try again.');
    }
  }

  // ============================================
  // PHYSICAL BOOK — ASK AI (free-form chat)
  // ============================================

  /// Free-form question about a book during a physical reading session.
  /// No pre-selected text — the user types or uses shortcut chips.
  Future<String> askBookQuestion({
    required String bookTitle,
    required String question,
    String conversationHistory = '',
  }) async {
    final prompt = '''
You are a helpful literary assistant. The user is currently reading "$bookTitle".

${conversationHistory.isNotEmpty ? 'Previous conversation:\n$conversationHistory\n' : ''}

User's question: "$question"

Provide a helpful, clear, and concise answer. Keep it under 5 sentences.
If the question is about the book's content, characters, themes, or context, give a thoughtful literary response.
If the question is general, still try to relate it to the reading experience.
Return ONLY the answer text, no JSON formatting needed.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _visionModel.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim();
      } else {
        throw Exception('Empty response from AI');
      }
    } catch (e) {
      debugPrint('❌ Book question error: $e');

      if (e.toString().contains('429') ||
          e.toString().contains('RESOURCE_EXHAUSTED')) {
        throw Exception('Rate limit reached. Please try again in a moment.');
      }

      throw Exception('Failed to get answer. Please try again.');
    }
  }

  /// Analyze a photo of a book passage taken during a physical reading session.
  /// Returns a contextual explanation of what's in the image.
  Future<String> analyzePassagePhoto({
    required Uint8List imageBytes,
    required String bookTitle,
  }) async {
    final prompt = '''
You are a literary assistant. The user is reading "$bookTitle" and has taken a photo of a passage or page.

Analyze the content in this image:
- Read and identify any text visible.
- Explain the meaning and significance of the passage.
- If there are difficult words, briefly define them.
- If relevant, mention how it might connect to the book's themes.

Keep your response clear, conversational, and under 6 sentences.
''';

    try {
      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];
      final response = await _visionModel.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim();
      } else {
        throw Exception('Empty response from AI');
      }
    } catch (e) {
      debugPrint('❌ Passage photo analysis error: $e');

      if (e.toString().contains('429') ||
          e.toString().contains('RESOURCE_EXHAUSTED')) {
        throw Exception('Rate limit reached. Please try again in a moment.');
      }

      throw Exception('Failed to analyze passage. Please try again.');
    }
  }

  /// Ask a follow-up question about a passage photo that was already analyzed.
  Future<String> askPassageFollowUp({
    required Uint8List imageBytes,
    required String bookTitle,
    required String previousAnalysis,
    required String question,
    String conversationHistory = '',
  }) async {
    final prompt = '''
You are a literary assistant for the book "$bookTitle".

The user took a photo of a passage and you analyzed it.
Your previous analysis: "$previousAnalysis"

${conversationHistory.isNotEmpty ? 'Previous conversation:\n$conversationHistory\n' : ''}

User's follow-up question: "$question"

Provide a helpful, concise answer. Keep it under 4 sentences.
''';

    try {
      final content = [
        Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)]),
      ];
      final response = await _visionModel.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!.trim();
      } else {
        throw Exception('Empty response from AI');
      }
    } catch (e) {
      debugPrint('❌ Passage follow-up error: $e');

      if (e.toString().contains('429') ||
          e.toString().contains('RESOURCE_EXHAUSTED')) {
        throw Exception('Rate limit reached. Please try again in a moment.');
      }

      throw Exception('Failed to get answer. Please try again.');
    }
  }
}
