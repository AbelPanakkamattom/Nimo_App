import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiAIService {
  GeminiAIService._();

  // =========================================================
  // CONFIGURATION
  // =========================================================

  static const String _modelName = 'gemini-1.5-flash';

  // =========================================================
  // API KEY
  // =========================================================

  static String get _apiKey {
    return dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
  }

  // =========================================================
  // MODEL
  // =========================================================

  static GenerativeModel get _model {
    if (_apiKey.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY not found in .env file.',
      );
    }

    return GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
    );
  }

  // =========================================================
  // GENERATE RESPONSE
  // =========================================================

  static Future<String> generateResponse(
      String prompt,
      ) async {
    final text = prompt.trim();

    if (text.isEmpty) {
      return 'Please enter a message.';
    }

    try {
      final response =
      await _model.generateContent([
        Content.text(text),
      ]);

      final output =
          response.text?.trim() ?? '';

      if (output.isEmpty) {
        return 'No response generated.';
      }

      return output;
    } on GenerativeAIException catch (e) {
      debugPrint('GEMINI API ERROR: $e');
      return 'Gemini API error: ${e.message}';
    } catch (e) {
      debugPrint('GEMINI UNKNOWN ERROR: $e');
      return 'Failed to generate response.';
    }
  }

  // =========================================================
  // TEST API KEY
  // =========================================================

  static Future<bool> testConnection() async {
    try {
      final response =
      await _model.generateContent([
        Content.text('Say "Connected successfully."'),
      ]);

      return (response.text ?? '')
          .toLowerCase()
          .contains('connected');
    } catch (e) {
      debugPrint('GEMINI TEST ERROR: $e');
      return false;
    }
  }

  // =========================================================
  // CHECK IF API KEY EXISTS
  // =========================================================

  static bool get hasApiKey =>
      _apiKey.isNotEmpty;
}