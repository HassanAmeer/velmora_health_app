import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velmora/models/game_question.dart';
import 'package:flutter/foundation.dart';

/// Debug version of GameQuestionsService with extensive logging
class GameQuestionsServiceDebug {
  static const String _questionsPrefix = 'game_questions_';
  static const String _lastGeneratedPrefix = 'last_generated_';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get questions for a specific game with detailed logging
  Future<List<GameQuestion>> getQuestions(String gameId) async {
    debugPrint('🔍 [GameQuestions] Starting getQuestions for gameId: $gameId');

    try {
      // Check if we need to generate new questions
      debugPrint('🔍 [GameQuestions] Checking if should generate new questions...');
      final shouldGenerate = await _shouldGenerateNewQuestions(gameId);
      debugPrint('🔍 [GameQuestions] Should generate: $shouldGenerate');

      if (shouldGenerate) {
        debugPrint('🔍 [GameQuestions] Attempting to generate questions with AI...');
        try {
          await _generateQuestionsWithAI(gameId);
          debugPrint('✅ [GameQuestions] AI generation completed');
        } catch (e) {
          debugPrint('❌ [GameQuestions] AI generation failed: $e');
        }
      }

      // Load questions from local storage
      debugPrint('🔍 [GameQuestions] Loading questions from local storage...');
      final storedQuestions = await _loadQuestionsFromLocal(gameId);
      debugPrint('🔍 [GameQuestions] Stored questions count: ${storedQuestions.length}');

      if (storedQuestions.isNotEmpty) {
        debugPrint('✅ [GameQuestions] Returning ${storedQuestions.length} stored questions');
        return storedQuestions;
      }

      // Fallback to default questions
      debugPrint('🔍 [GameQuestions] No stored questions, using defaults...');
      final defaultQuestions = _getDefaultQuestions(gameId);
      debugPrint('✅ [GameQuestions] Returning ${defaultQuestions.length} default questions');
      return defaultQuestions;
    } catch (e, stackTrace) {
      debugPrint('❌ [GameQuestions] CRITICAL ERROR in getQuestions: $e');
      debugPrint('❌ [GameQuestions] Stack trace: $stackTrace');

      // Always return default questions on error
      try {
        final defaultQuestions = _getDefaultQuestions(gameId);
        debugPrint('⚠️ [GameQuestions] Returning ${defaultQuestions.length} default questions after error');
        return defaultQuestions;
      } catch (e2) {
        debugPrint('❌ [GameQuestions] FATAL: Cannot even load default questions: $e2');
        return [];
      }
    }
  }

  Future<bool> _shouldGenerateNewQuestions(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastGeneratedStr = prefs.getString('$_lastGeneratedPrefix$gameId');
      debugPrint('🔍 [GameQuestions] Last generated timestamp: $lastGeneratedStr');

      if (lastGeneratedStr == null) {
        debugPrint('🔍 [GameQuestions] Never generated before');
        return true;
      }

      final lastGenerated = DateTime.parse(lastGeneratedStr);
      final now = DateTime.now();
      debugPrint('🔍 [GameQuestions] Last: ${lastGenerated.toString()}, Now: ${now.toString()}');

      if (now.year > lastGenerated.year ||
          (now.year == lastGenerated.year && now.month > lastGenerated.month)) {
        debugPrint('🔍 [GameQuestions] New month detected, should regenerate');
        return true;
      }

      debugPrint('🔍 [GameQuestions] Same month, no need to regenerate');
      return false;
    } catch (e) {
      debugPrint('❌ [GameQuestions] Error checking generation status: $e');
      return false;
    }
  }

  Future<void> _generateQuestionsWithAI(String gameId) async {
    try {
      debugPrint('🔍 [GameQuestions] Fetching AI config from Firestore...');
      final aiConfigDoc = await _firestore.collection('ai_config').doc('settings').get();

      if (!aiConfigDoc.exists) {
        debugPrint('⚠️ [GameQuestions] AI config document does not exist');
        return;
      }

      final aiConfig = aiConfigDoc.data();
      if (aiConfig == null) {
        debugPrint('⚠️ [GameQuestions] AI config data is null');
        return;
      }

      debugPrint('🔍 [GameQuestions] AI config loaded: ${aiConfig.keys.join(", ")}');

      final enabled = aiConfig['enabled'] ?? false;
      debugPrint('🔍 [GameQuestions] AI enabled: $enabled');

      if (!enabled) {
        debugPrint('⚠️ [GameQuestions] AI is disabled in config');
        return;
      }

      final apiKey = aiConfig['apiKey'] as String?;
      debugPrint('🔍 [GameQuestions] API key present: ${apiKey != null && apiKey.isNotEmpty}');

      if (apiKey == null || apiKey == 'PLACEHOLDER_KEY' || apiKey.isEmpty) {
        debugPrint('⚠️ [GameQuestions] Invalid or missing API key');
        return;
      }

      debugPrint('🔍 [GameQuestions] Generating prompt for game: $gameId');
      final prompt = _getPromptForGame(gameId);
      debugPrint('🔍 [GameQuestions] Calling Gemini API...');

      final questions = await _callGeminiAPI(apiKey, prompt, aiConfig);
      debugPrint('🔍 [GameQuestions] API returned ${questions.length} questions');

      if (questions.isNotEmpty) {
        debugPrint('🔍 [GameQuestions] Saving questions to local storage...');
        await _saveQuestionsToLocal(gameId, questions);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          '$_lastGeneratedPrefix$gameId',
          DateTime.now().toIso8601String(),
        );
        debugPrint('✅ [GameQuestions] Questions saved and timestamp updated');
      } else {
        debugPrint('⚠️ [GameQuestions] No questions generated by AI');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [GameQuestions] Error in _generateQuestionsWithAI: $e');
      debugPrint('❌ [GameQuestions] Stack trace: $stackTrace');
    }
  }

  Future<List<GameQuestion>> _callGeminiAPI(
    String apiKey,
    String prompt,
    Map<String, dynamic> aiConfig,
  ) async {
    try {
      debugPrint('🔍 [GameQuestions] Gemini API call - placeholder implementation');
      // Placeholder - actual API implementation would go here
      return [];
    } catch (e) {
      debugPrint('❌ [GameQuestions] Gemini API error: $e');
      return [];
    }
  }

  String _getPromptForGame(String gameId) {
    // Same as original implementation
    switch (gameId) {
      case 'truth_or_truth':
        return 'Generate 10 deep questions for couples...';
      case 'love_language_quiz':
        return 'Generate 10 love language quiz questions...';
      default:
        return 'Generate 10 meaningful questions for couples.';
    }
  }

  Future<List<GameQuestion>> _loadQuestionsFromLocal(String gameId) async {
    try {
      debugPrint('🔍 [GameQuestions] Getting SharedPreferences instance...');
      final prefs = await SharedPreferences.getInstance();

      debugPrint('🔍 [GameQuestions] Reading key: $_questionsPrefix$gameId');
      final questionsJson = prefs.getString('$_questionsPrefix$gameId');

      debugPrint('🔍 [GameQuestions] Raw JSON length: ${questionsJson?.length ?? 0}');
      debugPrint('🔍 [GameQuestions] JSON is null: ${questionsJson == null}');
      debugPrint('🔍 [GameQuestions] JSON is empty: ${questionsJson?.isEmpty ?? true}');

      if (questionsJson == null || questionsJson.isEmpty || questionsJson == 'null') {
        debugPrint('⚠️ [GameQuestions] No valid JSON found in local storage');
        return [];
      }

      debugPrint('🔍 [GameQuestions] Decoding JSON...');
      final dynamic decoded = json.decode(questionsJson);

      debugPrint('🔍 [GameQuestions] Decoded type: ${decoded.runtimeType}');

      if (decoded is! List) {
        debugPrint('❌ [GameQuestions] Decoded data is not a List, it is: ${decoded.runtimeType}');
        return [];
      }

      debugPrint('🔍 [GameQuestions] Decoded list length: ${decoded.length}');
      debugPrint('🔍 [GameQuestions] Converting to GameQuestion objects...');

      final questions = <GameQuestion>[];
      for (int i = 0; i < decoded.length; i++) {
        try {
          final item = decoded[i];
          debugPrint('🔍 [GameQuestions] Processing item $i, type: ${item.runtimeType}');

          if (item is Map) {
            final question = GameQuestion.fromJson(Map<String, dynamic>.from(item));
            questions.add(question);
            debugPrint('✅ [GameQuestions] Item $i converted successfully');
          } else {
            debugPrint('⚠️ [GameQuestions] Item $i is not a Map, skipping');
          }
        } catch (e) {
          debugPrint('❌ [GameQuestions] Error converting item $i: $e');
        }
      }

      debugPrint('✅ [GameQuestions] Successfully loaded ${questions.length} questions from local');
      return questions;
    } catch (e, stackTrace) {
      debugPrint('❌ [GameQuestions] Error loading from local storage: $e');
      debugPrint('❌ [GameQuestions] Stack trace: $stackTrace');
      return [];
    }
  }

  Future<void> _saveQuestionsToLocal(
    String gameId,
    List<GameQuestion> questions,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final questionsJson = json.encode(questions.map((q) => q.toJson()).toList());
      await prefs.setString('$_questionsPrefix$gameId', questionsJson);
      debugPrint('✅ [GameQuestions] Saved ${questions.length} questions to local storage');
    } catch (e) {
      debugPrint('❌ [GameQuestions] Error saving to local storage: $e');
    }
  }

  List<GameQuestion> _getDefaultQuestions(String gameId) {
    debugPrint('🔍 [GameQuestions] Getting default questions for: $gameId');

    try {
      final List<Map<String, dynamic>> data = _getQuestionsData(gameId);
      debugPrint('🔍 [GameQuestions] Raw data count: ${data.length}');

      if (data.isEmpty) {
        debugPrint('⚠️ [GameQuestions] No default data found for gameId: $gameId');
        return [];
      }

      final questions = <GameQuestion>[];
      for (int i = 0; i < data.length; i++) {
        try {
          final question = GameQuestion.fromJson(data[i]);
          questions.add(question);
        } catch (e) {
          debugPrint('❌ [GameQuestions] Error parsing default question $i: $e');
        }
      }

      debugPrint('✅ [GameQuestions] Parsed ${questions.length} default questions');
      return questions;
    } catch (e, stackTrace) {
      debugPrint('❌ [GameQuestions] CRITICAL ERROR in _getDefaultQuestions: $e');
      debugPrint('❌ [GameQuestions] Stack trace: $stackTrace');
      return [];
    }
  }

  List<Map<String, dynamic>> _getQuestionsData(String gameId) {
    switch (gameId) {
      case 'truth_or_truth':
        return [
          {'question': 'What is your favorite memory of us together?', 'category': 'memories'},
          {'question': 'What do you appreciate most about our relationship?', 'category': 'appreciation'},
          {'question': 'What is one thing you would like us to do together?', 'category': 'future'},
          {'question': 'What makes you feel most loved by me?', 'category': 'love'},
          {'question': 'What is something you have always wanted to tell me?', 'category': 'communication'},
        ];

      case 'love_language_quiz':
        return [
          {
            'question': 'Which scenario makes you feel more loved?',
            'category': 'preference',
            'options': [
              {'text': 'Receiving a thoughtful gift', 'language': 'receiving_gifts', 'isCorrect': false},
              {'text': 'Spending uninterrupted time together', 'language': 'quality_time', 'isCorrect': false},
              {'text': 'Hearing "I love you" and compliments', 'language': 'words_of_affirmation', 'isCorrect': false},
              {'text': 'Having someone help with tasks', 'language': 'acts_of_service', 'isCorrect': false},
              {'text': 'Physical affection like hugs', 'language': 'physical_touch', 'isCorrect': false},
            ],
          },
          {
            'question': 'What makes you feel most appreciated?',
            'category': 'appreciation',
            'options': [
              {'text': 'Words of encouragement', 'language': 'words_of_affirmation', 'isCorrect': false},
              {'text': 'Help with responsibilities', 'language': 'acts_of_service', 'isCorrect': false},
              {'text': 'Undivided attention', 'language': 'quality_time', 'isCorrect': false},
              {'text': 'Surprise presents', 'language': 'receiving_gifts', 'isCorrect': false},
              {'text': 'Physical closeness', 'language': 'physical_touch', 'isCorrect': false},
            ],
          },
        ];

      default:
        debugPrint('⚠️ [GameQuestions] Unknown gameId: $gameId, returning empty list');
        return [];
    }
  }
}
