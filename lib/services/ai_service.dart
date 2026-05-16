import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:velmora/services/gemini-ai.dart';
import 'package:velmora/services/claude-ai.dart';

/// AI Service for Gemini AI integration with Firestore control
///
/// AI configuration is stored in Firestore for remote control
/// API key is stored securely in Firestore config document
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Provider selection
  String _provider = 'gemini';

  // Gemini API configuration
  String? _apiKey;
  String _model = 'gemini-2.5-flash';
  String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  // Claude API configuration
  String? _claudeApiKey;
  String _claudeModel = 'claude-sonnet-4-5-20250929';

  // AI Settings from Firestore
  Map<String, dynamic> _aiSettings = {};
  bool _isInitialized = false;

  // Requirement 9.3: Cap context window to 3-5 messages
  static const int _chatHistoryLimit = 4;

  /// Initialize the AI service - load config from Firestore
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadAIConfig();
      _isInitialized = true;
      debugPrint('AI Service initialized');
    } catch (e) {
      debugPrint('Error initializing AI service: $e');
    }
  }

  /// Load AI configuration from Firestore
  /// Config is stored in: ai_config/doc
  Future<void> _loadAIConfig() async {
    try {
      // Load AI configuration from Firestore
      final configDoc = await _firestore
          .collection('ai_config')
          .doc('settings')
          .get();

      if (configDoc.exists) {
        _aiSettings = configDoc.data() ?? {};
        _apiKey = _aiSettings['apiKey'] as String?;

        // Provider selection
        _provider = (_aiSettings['provider'] as String? ?? 'gemini').toLowerCase();

        // Claude config
        _claudeApiKey = _aiSettings['claudeApiKey'] as String?;
        final rawClaudeModel = _aiSettings['claudeModel'] as String?;
        if (rawClaudeModel != null && rawClaudeModel.trim().isNotEmpty) {
          _claudeModel = rawClaudeModel.trim();
          // Auto-correct known deprecated model names
          if (_claudeModel == 'claude-3-5-sonnet-20240620' || _claudeModel == 'claude-3-5-sonnet-20241022') {
            _claudeModel = 'claude-sonnet-4-5-20250929';
            debugPrint('⚠️ Auto-corrected deprecated Claude model to $_claudeModel');
          }
        } else {
          _claudeModel = 'claude-sonnet-4-5-20250929';
        }

        // Gemini model configuration
        final rawModel = _aiSettings['model'];
        String? model = rawModel as String?;
        if (model != null && model.trim().isNotEmpty) {
          model = model.trim();
          if (model.startsWith('models/')) {
            model = model.replaceFirst('models/', '');
          }
          _model = model;
        } else {
          _model = 'gemini-2.5-flash';
        }

        // Build Gemini API URL
        _apiUrl =
            'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

        debugPrint('🔮 [AI] Provider: $_provider | Gemini Model: $_model | Claude Model: $_claudeModel');
      }

      // Fallback: If no config in Firestore, set to null
      if (_apiKey == null || _apiKey!.isEmpty) {
        _apiKey = null;
      }
      if (_claudeApiKey == null || _claudeApiKey!.isEmpty) {
        _claudeApiKey = null;
      }
    } catch (e) {
      debugPrint('Error loading AI config: $e');
      _apiKey = null;
    }
  }

  /// Update AI config in Firestore (for admin use)
  Future<void> updateAIConfig(Map<String, dynamic> config) async {
    try {
      await _firestore.collection('ai_config').doc('settings').update(config);
      await _loadAIConfig(); // Reload config
      debugPrint('AI config updated');
    } catch (e) {
      debugPrint('Error updating AI config: $e');
      rethrow;
    }
  }

  String? get currentUserId => _auth.currentUser?.uid;

  /// Get conversation history for a user (sliding window - last 5 messages)
  Future<List<Map<String, dynamic>>> _getConversationHistory() async {
    if (currentUserId == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chatMessages')
          .orderBy('timestamp', descending: true)
          .limit(_chatHistoryLimit)
          .get();

      final history = <Map<String, dynamic>>[];

      // Reverse to get chronological order
      for (var doc in snapshot.docs.reversed) {
        final data = doc.data();
        history.add({
          'role': (data['isUser'] == true) ? 'user' : 'model',
          'content': data['message'] ?? '',
        });
      }

      return history;
    } catch (e) {
      debugPrint('Error getting conversation history: $e');
      return [];
    }
  }

  /// Get user's preferred language
  Future<String> _getUserLanguage() async {
    if (currentUserId == null) return 'en';

    try {
      final doc = await _firestore.collection('users').doc(currentUserId).get();
      return doc.data()?['preferredLanguage'] ?? 'en';
    } catch (e) {
      debugPrint('Error getting language: $e');
      return 'en';
    }
  }

  /// Generate AI response using the active provider (Gemini or Claude)
  Future<String> generateResponse(
    String userMessage, {
    String? languageCode,
  }) async {
    await _loadAIConfig();

    if (_aiSettings['enabled'] == false) {
      throw Exception('AI chat is currently disabled by admin');
    }

    try {
      final history = await _getConversationHistory();
      final language = languageCode ?? await _getUserLanguage();

      String userContext = '';
      if (currentUserId != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUserId)
            .get();
        final userData = userDoc.data() ?? {};
        final name = userData['name'] ?? 'User';
        final partnerName = userData['partnerName'] ?? 'Partner';
        userContext =
            'You are speaking with $name. Their partner\'s name is $partnerName.';
      }

      final systemInstruction =
          _aiSettings['systemInstruction'] as String? ??
          'You are Velmora AI, a helpful relationship coach.';
      final languageName = _getLanguageName(language);
      final maxTokens = _aiSettings['maxTokens'] as int? ?? 500;
      final temperature =
          (_aiSettings['temperature'] as num?)?.toDouble() ?? 0.7;

      if (_provider == 'claude') {
        if (_claudeApiKey == null || _claudeApiKey!.isEmpty) {
          throw Exception('Claude API key not configured in admin panel.');
        }
        debugPrint('🔮 [AI] Active Provider: CLAUDE | Model: $_claudeModel');

        final fullSystem = '''
CRITICAL: ALL RESPONSES MUST BE IN $languageName. DO NOT USE ANY OTHER LANGUAGE.

$systemInstruction

$userContext

LANGUAGE LOCK:
You are strictly required to respond in $languageName.''';

        final messages = <Map<String, String>>[];
        for (var msg in history) {
          messages.add({
            'role': msg['role'] == 'model' ? 'assistant' : 'user',
            'content': msg['content'] as String,
          });
        }
        messages.add({'role': 'user', 'content': userMessage});

        final response = await ClaudeProvider.generateResponse(
          apiKey: _claudeApiKey!,
          model: _claudeModel,
          systemInstruction: fullSystem,
          messages: messages,
          maxTokens: maxTokens,
          temperature: temperature,
        );
        debugPrint('✅ [AI] Response received from CLAUDE');
        return response;
      } else {
        if (_apiKey == null || _apiKey!.isEmpty) {
          throw Exception('Gemini API key not configured in admin panel.');
        }
        debugPrint('🔮 [AI] Active Provider: GEMINI | Model: $_model');

        final fullSystem = '''
CRITICAL: ALL RESPONSES MUST BE IN $languageName. DO NOT USE ANY OTHER LANGUAGE.

$systemInstruction

$userContext

LANGUAGE LOCK:
You are strictly required to respond in $languageName. This is the most important rule.
Even if historical messages are in another language, you MUST respond in $languageName only.''';

        final contents = <Map<String, dynamic>>[];
        contents.add({
          'role': 'user',
          'parts': [
            {'text': '[SYSTEM: Interface language is $languageName. Respond ONLY in $languageName.]'},
          ],
        });
        contents.add({
          'role': 'model',
          'parts': [
            {'text': 'Understood. I will respond only in $languageName.'},
          ],
        });
        for (var msg in history) {
          contents.add({
            'role': msg['role'],
            'parts': [{'text': msg['content']}],
          });
        }
        contents.add({
          'role': 'user',
          'parts': [
            {'text': 'User Message: $userMessage\n\n(Answer strictly in $languageName only.)'},
          ],
        });

        final topK = _aiSettings['topK'] as int? ?? 40;
        final topP = (_aiSettings['topP'] as num?)?.toDouble() ?? 0.95;
        final safetySettings =
            _aiSettings['safetySettings'] as Map<String, dynamic>?;

        final response = await GeminiProvider.generateResponse(
          apiKey: _apiKey!,
          model: _model,
          systemInstruction: fullSystem,
          contents: contents,
          maxTokens: maxTokens,
          temperature: temperature,
          topK: topK,
          topP: topP,
          safetySettings: safetySettings,
        );
        debugPrint('✅ [AI] Response received from GEMINI');
        return response;
      }
    } catch (e, stackTrace) {
      debugPrint('generateResponse: 💥 AI error: $e, st: $stackTrace');
      throw Exception('Failed to generate response. Please try again.');
    }
  }

  /// Get language name from code
  String _getLanguageName(String code) {
    switch (code) {
      case 'ar':
        return 'Arabic';
      case 'fr':
        return 'French';
      default:
        return 'English';
    }
  }

  /// Check if AI service is available
  Future<bool> isAvailable() async {
    try {
      await _loadAIConfig();
      if (_aiSettings['enabled'] == false) return false;
      if (_provider == 'claude') {
        return _claudeApiKey != null && _claudeApiKey!.isNotEmpty;
      }
      return _apiKey != null && _apiKey!.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get AI settings (for admin/debugging)
  Map<String, dynamic> get settings => Map.unmodifiable(_aiSettings);

  /// Generate game content based on game ID
  Future<List<Map<String, dynamic>>> generateGameContent(String gameId) async {
    await _loadAIConfig();

    if (_provider == 'claude') {
      if (_claudeApiKey == null || _claudeApiKey!.isEmpty) {
        throw Exception('Claude API key not configured.');
      }
    } else {
      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception('Gemini API key not configured.');
      }
    }

    String prompt = '';
    switch (gameId) {
      case 'truth_or_truth':
        prompt = '''Generate 15 "Truth or Truth" questions for couples. 
        The questions should be deep, meaningful, and varied (covering intimacy, future, daily life, emotional bonding).
        Return ONLY a JSON array of objects with the following structure:
        [
          {
            "id": "q1",
            "question": "The question text here",
            "question_translations": {"en": "...", "ar": "...", "fr": "..."},
            "category": "connection",
            "difficulty": "medium"
          }
        ]
        Categories can be: connection, future, understanding, fun.
        Difficulties can be: easy, medium, deep.''';
        break;
      case 'love_language_quiz':
        prompt = '''Generate 5 "Love Language Quiz" questions for couples.
        Each question must have exactly 5 options, one for each love language: words_of_affirmation, quality_time, receiving_gifts, acts_of_service, physical_touch.
        Return ONLY a JSON array of objects with the following structure:
        [
          {
            "id": "q1",
            "question": "Question text here",
            "question_translations": {"en": "...", "ar": "...", "fr": "..."},
            "options": [
              {"text": "Option text", "language": "words_of_affirmation", "text_translations": {"en": "...", "ar": "...", "fr": "..."}},
              {"text": "Option text", "language": "quality_time", "text_translations": {"en": "...", "ar": "...", "fr": "..."}},
              {"text": "Option text", "language": "receiving_gifts", "text_translations": {"en": "...", "ar": "...", "fr": "..."}},
              {"text": "Option text", "language": "acts_of_service", "text_translations": {"en": "...", "ar": "...", "fr": "..."}},
              {"text": "Option text", "language": "physical_touch", "text_translations": {"en": "...", "ar": "...", "fr": "..."}}
            ]
          }
        ]''';
        break;
      case 'reflection_game':
        prompt = '''Generate 10 reflection prompts for couples.
        The prompts should encourage meaningful discussion and shared growth.
        Return ONLY a JSON array of objects with the following structure:
        [
          {
            "id": "q1",
            "question": "Reflection prompt text here",
            "question_translations": {"en": "...", "ar": "...", "fr": "..."},
            "category": "reflection",
            "order": 1
          }
        ]''';
        break;
      default:
        throw Exception('Unknown game ID: $gameId');
    }

    final apiPrompt =
        "$prompt\n\nIMPORTANT: Return ONLY valid JSON. No markdown formatting, no backticks.";
    final maxTokens = _aiSettings['maxTokens'] as int? ?? 1000;
    final temperature =
        (_aiSettings['temperature'] as num?)?.toDouble() ?? 0.7;

    try {
      String response;
      if (_provider == 'claude') {
        debugPrint('🔮 [AI-Game] Active Provider: CLAUDE | Model: $_claudeModel');
        response = await ClaudeProvider.generateSimple(
          apiKey: _claudeApiKey!,
          model: _claudeModel,
          prompt: apiPrompt,
          maxTokens: maxTokens,
          temperature: temperature,
        );
        debugPrint('✅ [AI-Game] Response received from CLAUDE');
      } else {
        debugPrint('🔮 [AI-Game] Active Provider: GEMINI | Model: $_model');
        response = await GeminiProvider.generateSimple(
          apiKey: _apiKey!,
          model: _model,
          prompt: apiPrompt,
          maxTokens: maxTokens,
          temperature: temperature,
        );
        debugPrint('✅ [AI-Game] Response received from GEMINI');
      }

      String cleanJson = response.trim();
      if (cleanJson.startsWith('```json')) {
        cleanJson = cleanJson.substring(7, cleanJson.lastIndexOf('```')).trim();
      } else if (cleanJson.startsWith('```')) {
        cleanJson = cleanJson.substring(3, cleanJson.lastIndexOf('```')).trim();
      }

      final List<dynamic> decoded = jsonDecode(cleanJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error generating game content for $gameId: $e');
      rethrow;
    }
  }
}
