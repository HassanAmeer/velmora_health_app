import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:velmora/services/debug_log_service.dart';

class GeminiProvider {
  /// Call Gemini API and return response text
  /// [contents] should be a list of content maps with 'role' and 'parts'
  static Future<String> generateResponse({
    required String apiKey,
    required String model,
    required String systemInstruction,
    required List<Map<String, dynamic>> contents,
    int maxTokens = 500,
    double temperature = 0.7,
    int topK = 40,
    double topP = 0.95,
    Map<String, dynamic>? safetySettings,
  }) async {
    final apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    final body = {
      'systemInstruction': {
        'parts': [
          {'text': systemInstruction},
        ],
      },
      'contents': contents,
      'generationConfig': {
        'maxOutputTokens': maxTokens,
        'temperature': temperature,
        'topK': topK,
        'topP': topP,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': safetySettings?['sexuallyExplicit'] as String? ??
              'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': safetySettings?['hateSpeech'] as String? ??
              'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': safetySettings?['harassment'] as String? ??
              'BLOCK_MEDIUM_AND_ABOVE',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': safetySettings?['dangerousContent'] as String? ??
              'BLOCK_MEDIUM_AND_ABOVE',
        },
      ],
    };

    _printConfig(provider: 'GEMINI', model: model, apiKey: apiKey, systemInstruction: systemInstruction, contents: contents, maxTokens: maxTokens, temperature: temperature, topK: topK, topP: topP, safetySettings: safetySettings);

    DebugLogService().addLog(DebugLogEntry(
      timestamp: DateTime.now(),
      type: DebugLogType.request,
      provider: 'GEMINI',
      model: model,
      summary: 'Request — ${contents.length} msgs, $maxTokens tokens',
      details: {
        'Gemini API Key': apiKey.length > 8
            ? '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}'
            : '***',
        'Gemini Model': model,
        'System': systemInstruction,
        'Contents': contents,
        'Max Tokens': maxTokens,
        'Temperature': temperature,
        'TopK': topK,
        'TopP': topP,
      },
    ));

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final text =
              data['candidates'][0]['content']['parts'][0]['text'] as String;
          debugPrint(
              '✅ Gemini OK: ${text.length > 80 ? text.substring(0, 80) : text}...');
          debugPrint('📄 Full response:\n$text');
          DebugLogService().addLog(DebugLogEntry(
            timestamp: DateTime.now(),
            type: DebugLogType.response,
            provider: 'GEMINI',
            model: model,
            summary: 'Success — ${text.length} chars',
            details: {'Gemini Response': text},
          ));
          return text;
        }
        throw Exception('Invalid response format from Gemini API');
      }

      debugPrint('📥 Body: ${response.body}');

      final errorData = jsonDecode(response.body);
      final errorMessage =
          errorData['error']?['message'] as String? ?? 'Unknown error';

      String error;
      if (response.statusCode == 403) {
        error = 'Gemini API key invalid/expired. Check admin panel.';
      } else if (response.statusCode == 400) {
        error = 'Invalid Gemini request: $errorMessage';
      } else if (response.statusCode == 429) {
        error = 'Rate limit exceeded. Try again later.';
      } else {
        error = 'Gemini API error: $errorMessage';
      }

      DebugLogService().addLog(DebugLogEntry(
        timestamp: DateTime.now(),
        type: DebugLogType.error,
        provider: 'GEMINI',
        model: model,
        summary: 'Error — $error',
        details: {'Gemini Status': response.statusCode, 'Gemini Body': response.body},
      ));
      throw Exception(error);
    } catch (e) {
      if (e is Exception) rethrow;
      DebugLogService().addLog(DebugLogEntry(
        timestamp: DateTime.now(),
        type: DebugLogType.error,
        provider: 'GEMINI',
        model: model,
        summary: 'Error — $e',
        details: {'Gemini Error': e.toString()},
      ));
      rethrow;
    }
  }

  /// Simple prompt call (no history, just one user message)
  static Future<String> generateSimple({
    required String apiKey,
    required String model,
    required String prompt,
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    final contents = [
      {
        'parts': [
          {'text': prompt},
        ],
      },
    ];

    final apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

    final body = {
      'contents': contents,
      'generationConfig': {
        'maxOutputTokens': maxTokens,
        'temperature': temperature,
      },
    };

    _printConfig(provider: 'GEMINI', model: model, apiKey: apiKey, systemInstruction: '', contents: contents, maxTokens: maxTokens, temperature: temperature);

    DebugLogService().addLog(DebugLogEntry(
      timestamp: DateTime.now(),
      type: DebugLogType.request,
      provider: 'GEMINI',
      model: model,
      summary: 'Simple Request — $maxTokens tokens',
      details: {
        'Gemini API Key': apiKey.length > 8
            ? '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}'
            : '***',
        'Gemini Model': model,
        'Prompt': prompt,
        'Max Tokens': maxTokens,
        'Temperature': temperature,
      },
    ));

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final text =
              data['candidates'][0]['content']['parts'][0]['text'] as String;
          debugPrint(
              '✅ Gemini OK: ${text.length > 80 ? text.substring(0, 80) : text}...');
          debugPrint('📄 Full response:\n$text');
          DebugLogService().addLog(DebugLogEntry(
            timestamp: DateTime.now(),
            type: DebugLogType.response,
            provider: 'GEMINI',
            model: model,
            summary: 'Success — ${text.length} chars',
            details: {'Gemini Response': text},
          ));
          return text;
        }
        throw Exception('Invalid response format from Gemini API');
      }

      debugPrint('📥 Body: ${response.body}');

      try {
        final errorData = jsonDecode(response.body);
        throw Exception(
            'Gemini API error: ${errorData['error']?['message'] ?? response.body}');
      } catch (_) {
        throw Exception('Gemini API error: ${response.body}');
      }
    } catch (e) {
      DebugLogService().addLog(DebugLogEntry(
        timestamp: DateTime.now(),
        type: DebugLogType.error,
        provider: 'GEMINI',
        model: model,
        summary: 'Error — $e',
        details: {'Gemini Error': e.toString()},
      ));
      rethrow;
    }
  }

  static void _printConfig({
    required String provider,
    required String model,
    required String apiKey,
    required String systemInstruction,
    required List<Map<String, dynamic>> contents,
    required int maxTokens,
    required double temperature,
    int? topK,
    double? topP,
    Map<String, dynamic>? safetySettings,
  }) {
    debugPrint('══════════════════════════════════════════════');
    debugPrint('  Provider: $provider');
    debugPrint('  Gemini Model: $model');
    debugPrint('  Gemini API Key: ${apiKey.length > 8 ? "${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}" : "***"}');
    debugPrint('  Max Tokens: $maxTokens');
    debugPrint('  Temperature: $temperature');
    if (topK != null) debugPrint('  TopK: $topK');
    if (topP != null) debugPrint('  TopP: $topP');
    if (safetySettings != null) {
      debugPrint('  Safety Settings: $safetySettings');
    }
    if (systemInstruction.isNotEmpty) {
      debugPrint('  System Instruction:');
      debugPrint('  ────────────────────────────────────────────');
      for (final line in systemInstruction.split('\n')) {
        debugPrint('  │ $line');
      }
      debugPrint('  ────────────────────────────────────────────');
    }
    debugPrint('  Contents (${contents.length}):');
    for (var i = 0; i < contents.length; i++) {
      final c = contents[i];
      debugPrint('  [$i] role=${c['role']}');
      final parts = c['parts'] as List?;
      if (parts != null) {
        for (final part in parts) {
          final text = part['text'] as String? ?? '';
          for (final line in text.split('\n')) {
            debugPrint('       │ $line');
          }
        }
      }
    }
    debugPrint('══════════════════════════════════════════════');
  }
}
