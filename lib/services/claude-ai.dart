import 'package:flutter/foundation.dart';
import 'package:ai_sdk_dart/ai_sdk_dart.dart';
import 'package:ai_sdk_anthropic/ai_sdk_anthropic.dart';
import 'package:velmora/services/debug_log_service.dart';

class ClaudeProvider {
  static Future<String> generateResponse({
    required String apiKey,
    required String model,
    required String systemInstruction,
    required List<Map<String, String>> messages,
    int maxTokens = 500,
    double temperature = 0.7,
  }) async {
    _printConfig(
      provider: 'CLAUDE',
      model: model,
      apiKey: apiKey,
      systemInstruction: systemInstruction,
      messages: messages,
      maxTokens: maxTokens,
      temperature: temperature,
    );

    DebugLogService().addLog(
      DebugLogEntry(
        timestamp: DateTime.now(),
        type: DebugLogType.request,
        provider: 'CLAUDE',
        model: model,
        summary: 'Request — ${messages.length} msgs, $maxTokens tokens',
        details: {
          'Claude API Key': apiKey.length > 8
              ? '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}'
              : '***',
          'Claude Model': model,
          'System': systemInstruction,
          'Messages': messages
              .map((m) => '${m['role']}: ${m['content']}')
              .toList(),
          'Max Tokens': maxTokens,
          'Temperature': temperature,
        },
      ),
    );

    final modelsToTry = _buildModelChain(model);
    final errors = <String>[];

    for (final m in modelsToTry) {
      try {
        debugPrint('📡 Claude attempt: model=$m');
        final provider = AnthropicProvider(apiKey: apiKey);
        final languageModel = provider.call(m);
        final result = await generateText(
          model: languageModel,
          system: systemInstruction.isNotEmpty ? systemInstruction : null,
          messages: messages
              .map(
                (msg) => ModelMessage(
                  role: _parseRole(msg['role'] ?? 'user'),
                  content: msg['content'] ?? '',
                ),
              )
              .toList(),
          maxOutputTokens: maxTokens,
          temperature: temperature,
          maxRetries: 0,
        );
        debugPrint(
          '✅ Claude OK ($m): ${result.text.length > 80 ? result.text.substring(0, 80) : result.text}...',
        );
        DebugLogService().addLog(
          DebugLogEntry(
            timestamp: DateTime.now(),
            type: DebugLogType.response,
            provider: 'CLAUDE',
            model: m,
            summary: 'Success — ${result.text.length} chars',
            details: {
              'Claude Response': result.text,
              'Usage': result.usage != null
                  ? '${result.usage!.inputTokens} in / ${result.usage!.outputTokens} out'
                  : 'N/A',
            },
          ),
        );
        return result.text;
      } catch (e) {
        debugPrint('⚠️ Model $m failed: $e');
        errors.add('$m: $e');
        DebugLogService().addLog(
          DebugLogEntry(
            timestamp: DateTime.now(),
            type: DebugLogType.error,
            provider: 'CLAUDE',
            model: m,
            summary: 'Error — $e',
            details: {
              'Claude Error': e.toString(),
              'Stack Trace': StackTrace.current.toString(),
            },
          ),
        );
      }
    }

    DebugLogService().addLog(
      DebugLogEntry(
        timestamp: DateTime.now(),
        type: DebugLogType.error,
        provider: 'CLAUDE',
        model: model,
        summary: 'All models failed',
        details: {'errors': errors},
      ),
    );
    throw Exception(
      'All Claude models failed.\n${errors.join("\n")}\n'
      'Tried: ${modelsToTry.join(", ")}. Check API key & model in admin.',
    );
  }

  static void _printConfig({
    required String provider,
    required String model,
    required String apiKey,
    required String systemInstruction,
    required List<Map<String, String>> messages,
    required int maxTokens,
    required double temperature,
    int? topK,
    double? topP,
  }) {
    debugPrint('══════════════════════════════════════════════');
    debugPrint('  Provider: $provider');
    debugPrint('  Claude Model: $model');
    debugPrint(
      '  Claude API Key: ${apiKey.length > 8 ? "${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}" : "***"}',
    );
    debugPrint('  Max Tokens: $maxTokens');
    debugPrint('  Temperature: $temperature');
    if (topK != null) debugPrint('  TopK: $topK');
    if (topP != null) debugPrint('  TopP: $topP');
    if (systemInstruction.isNotEmpty) {
      debugPrint('  System Instruction:');
      debugPrint('  ────────────────────────────────────────────');
      for (final line in systemInstruction.split('\n')) {
        debugPrint('  │ $line');
      }
      debugPrint('  ────────────────────────────────────────────');
    }
    debugPrint('  Messages (${messages.length}):');
    for (var i = 0; i < messages.length; i++) {
      final msg = messages[i];
      debugPrint('  [$i] role=${msg['role']}');
      final content = msg['content'] ?? '';
      for (final line in content.split('\n')) {
        debugPrint('       │ $line');
      }
    }
    debugPrint('══════════════════════════════════════════════');
  }

  static ModelMessageRole _parseRole(String role) {
    switch (role) {
      case 'assistant':
        return ModelMessageRole.assistant;
      default:
        return ModelMessageRole.user;
    }
  }

  static Future<String> generateSimple({
    required String apiKey,
    required String model,
    required String prompt,
    int maxTokens = 150,
    double temperature = 0.7,
  }) async {
    return generateResponse(
      apiKey: apiKey,
      model: model,
      systemInstruction: '',
      messages: [
        {'role': 'user', 'content': prompt},
      ],
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  static List<String> _buildModelChain(String primary) {
    final chain = <String>[
      primary,
      if (primary != 'claude-sonnet-4-5-20250929') 'claude-sonnet-4-5-20250929',
      if (primary != 'claude-haiku-4-5-20251001') 'claude-haiku-4-5-20251001',
      if (primary != 'claude-sonnet-4-20250514') 'claude-sonnet-4-20250514',
      'claude-3-haiku-20240307',
    ];
    final seen = <String>{};
    return chain.where((m) => seen.add(m)).toList();
  }
}
