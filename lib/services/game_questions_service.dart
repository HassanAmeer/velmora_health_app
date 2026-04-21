import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:velmora/models/game_question.dart';

/// Service to manage game questions with AI generation and local storage
class GameQuestionsService {
  static const String _questionsPrefix = 'game_questions_';
  static const String _lastGeneratedPrefix = 'last_generated_';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get questions for a specific game
  /// Returns AI-generated questions if available and not expired, otherwise default questions
  Future<List<GameQuestion>> getQuestions(String gameId) async {
    try {
      print('🔍 [GameQuestions] Getting questions for: $gameId');

      // Check if we need to generate new questions
      final shouldGenerate = await _shouldGenerateNewQuestions(gameId);
      print('🔍 [GameQuestions] Should generate new: $shouldGenerate');

      if (shouldGenerate) {
        // Try to generate new questions with AI
        try {
          await _generateQuestionsWithAI(gameId);
        } catch (e) {
          print('⚠️ [GameQuestions] AI generation failed: $e');
        }
      }

      // Load questions from local storage
      final storedQuestions = await _loadQuestionsFromLocal(gameId);
      print('🔍 [GameQuestions] Stored questions: ${storedQuestions.length}');

      if (storedQuestions.isNotEmpty) {
        print(
          '✅ [GameQuestions] Returning ${storedQuestions.length} stored questions',
        );
        return storedQuestions;
      }

      // Fallback to default questions
      final defaultQuestions = _getDefaultQuestions(gameId);
      print(
        '✅ [GameQuestions] Returning ${defaultQuestions.length} default questions',
      );
      return defaultQuestions;
    } catch (e, stackTrace) {
      print('❌ [GameQuestions] ERROR: $e');
      print('❌ [GameQuestions] Stack: $stackTrace');

      // Always return default questions on error
      try {
        return _getDefaultQuestions(gameId);
      } catch (e2) {
        print('❌ [GameQuestions] FATAL: Cannot load defaults: $e2');
        return [];
      }
    }
  }

  /// Check if we should generate new questions (once per month)
  Future<bool> _shouldGenerateNewQuestions(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastGeneratedStr = prefs.getString('$_lastGeneratedPrefix$gameId');

      if (lastGeneratedStr == null) {
        return true; // Never generated before
      }

      final lastGenerated = DateTime.parse(lastGeneratedStr);
      final now = DateTime.now();

      // Check if it's a new month
      if (now.year > lastGenerated.year ||
          (now.year == lastGenerated.year && now.month > lastGenerated.month)) {
        return true;
      }

      return false;
    } catch (e) {
      return false; // Don't generate on error
    }
  }

  /// Generate new questions using AI and store in local storage
  Future<void> _generateQuestionsWithAI(String gameId) async {
    try {
      // Get AI configuration
      final aiConfigDoc = await _firestore
          .collection('ai_config')
          .doc('settings')
          .get();

      if (!aiConfigDoc.exists || aiConfigDoc.data() == null) {
        print('AI config not found');
        return;
      }

      final aiConfig = aiConfigDoc.data()!;
      final enabled = aiConfig['enabled'] ?? false;

      if (!enabled) {
        print('AI is disabled');
        return;
      }

      final apiKey = aiConfig['apiKey'] as String?;
      if (apiKey == null || apiKey == 'PLACEHOLDER_KEY') {
        print('Invalid API key');
        return;
      }

      // Generate questions based on game type
      final prompt = _getPromptForGame(gameId);
      final questions = await _callGeminiAPI(apiKey, prompt, aiConfig);

      if (questions.isNotEmpty) {
        // Save to local storage
        await _saveQuestionsToLocal(gameId, questions);

        // Update last generated timestamp
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          '$_lastGeneratedPrefix$gameId',
          DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('Error generating questions with AI: $e');
      // Silently fail - will use default questions
    }
  }

  /// Call Gemini API to generate questions
  Future<List<GameQuestion>> _callGeminiAPI(
    String apiKey,
    String prompt,
    Map<String, dynamic> aiConfig,
  ) async {
    try {
      final model = aiConfig['model'] as String? ?? 'gemini-2.5-flash';
      final apiUrl =
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey';

      final maxTokens = aiConfig['maxTokens'] as int? ?? 1000;
      final temperature = (aiConfig['temperature'] as num?)?.toDouble() ?? 0.7;

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'maxOutputTokens': maxTokens,
          'temperature': temperature,
        },
      };

      print('🚀 [GameQuestions] Calling Gemini API for game content...');
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          String text = data['candidates'][0]['content']['parts'][0]['text'];

          // Clean up response if it contains markdown
          text = text.trim();
          if (text.startsWith('```json')) {
            text = text.substring(7, text.lastIndexOf('```')).trim();
          } else if (text.startsWith('```')) {
            text = text.substring(3, text.lastIndexOf('```')).trim();
          }

          try {
            final List<dynamic> decoded = jsonDecode(text);
            return decoded
                .map((q) => GameQuestion.fromJson(Map<String, dynamic>.from(q)))
                .toList();
          } catch (e) {
            print('❌ [GameQuestions] JSON Parse Error: $e');
            print('❌ [GameQuestions] Raw Response: $text');
            return [];
          }
        }
      } else {
        print(
          '❌ [GameQuestions] API Error (${response.statusCode}): ${response.body}',
        );
      }
      return [];
    } catch (e) {
      print('❌ [GameQuestions] Exception calling Gemini API: $e');
      return [];
    }
  }

  /// Get prompt for specific game type
  String _getPromptForGame(String gameId) {
    const translationFormat =
        '"question_translations": {"en": "...", "ar": "...", "fr": "..."}';

    switch (gameId) {
      case 'truth_or_truth':
        return '''Generate 10 deep, meaningful questions for couples to ask each other in a "Truth or Truth" game.
The questions should promote intimacy, understanding, and meaningful conversation.
Return as JSON array with format: [{"question": "English text", "category": "...", $translationFormat}]''';

      case 'love_language_quiz':
        return '''Generate 10 quiz questions to help couples discover their love languages.
Include questions about acts of service, quality time, physical touch, words of affirmation, and receiving gifts.
Return as JSON array with format: [{"question": "English text", "category": "...", $translationFormat, "options": [{"text": "...", "isCorrect": false, "language": "...", "text_translations": {"en": "...", "ar": "...", "fr": "..."}}]}]''';

      case 'reflection_game':
        return '''Generate 10 reflection prompts for couples to discuss and deepen their connection.
Focus on gratitude, future planning, and understanding each other better.
Return as JSON array with format: [{"question": "English text", "category": "...", $translationFormat}]''';

      case 'couples_challenge':
        return '''Generate 10 fun couple challenges with descriptions.
Return as JSON array with format: [{"question": "Challenge Name", "description": "...", "question_translations": {"en": "...", "ar": "...", "fr": "..."}, "description_translations": {"en": "...", "ar": "...", "fr": "..."}}]''';

      case 'would_you_rather':
        return '''Generate 10 "Would You Rather" scenarios for couples with two options.
Return as JSON array with format: [{"question": "English text", "optionA": "...", "optionB": "...", $translationFormat, "optionA_translations": {"en": "...", "ar": "...", "fr": "..."}, "optionB_translations": {"en": "...", "ar": "...", "fr": "..."}}]''';

      case 'date_night_ideas':
        return '''Generate 10 creative date night ideas with titles, descriptions, and budget levels.
Return as JSON array with format: [{"title": "...", "description": "...", "budget": "Low/Medium/High", "title_translations": {"en": "...", "ar": "...", "fr": "..."}, "description_translations": {"en": "...", "ar": "...", "fr": "..."}}]''';

      case 'relationship_quiz':
        return '''Generate 10 relationship quiz questions with multiple choice options where one is correct.
Return as JSON array with format: [{"question": "...", $translationFormat, "options": [{"text": "...", "isCorrect": true/false, "text_translations": {"en": "...", "ar": "...", "fr": "..."}}]}]''';

      case 'compliment_game':
        return '''Generate 10 compliment prompts to help partners express appreciation.
Return as JSON array with format: [{"prompt": "...", "hint": "...", "prompt_translations": {"en": "...", "ar": "...", "fr": "..."}, "hint_translations": {"en": "...", "ar": "...", "fr": "..."}}]''';

      default:
        return 'Generate 10 meaningful questions for couples with English, Arabic, and French translations.';
    }
  }

  /// Load questions from local storage
  Future<List<GameQuestion>> _loadQuestionsFromLocal(String gameId) async {
    try {
      print('🔍 [GameQuestions] Loading from local storage: $gameId');
      final prefs = await SharedPreferences.getInstance();
      final questionsJson = prefs.getString('$_questionsPrefix$gameId');

      if (questionsJson == null ||
          questionsJson.isEmpty ||
          questionsJson == 'null') {
        print('⚠️ [GameQuestions] No local storage data found');
        return [];
      }

      print(
        '🔍 [GameQuestions] Decoding JSON (length: ${questionsJson.length})',
      );
      final dynamic decoded = json.decode(questionsJson);

      if (decoded is! List) {
        print(
          '❌ [GameQuestions] Decoded data is not a List: ${decoded.runtimeType}',
        );
        return [];
      }

      print('🔍 [GameQuestions] Parsing ${decoded.length} items');
      final questions = <GameQuestion>[];

      for (int i = 0; i < decoded.length; i++) {
        try {
          final item = decoded[i];
          if (item is Map) {
            final question = GameQuestion.fromJson(
              Map<String, dynamic>.from(item),
            );
            questions.add(question);
          }
        } catch (e) {
          print('⚠️ [GameQuestions] Failed to parse item $i: $e');
        }
      }

      print(
        '✅ [GameQuestions] Loaded ${questions.length} questions from local',
      );
      return questions;
    } catch (e, stackTrace) {
      print('❌ [GameQuestions] Error loading from local: $e');
      print('❌ [GameQuestions] Stack: $stackTrace');
      return [];
    }
  }

  /// Save questions to local storage
  Future<void> _saveQuestionsToLocal(
    String gameId,
    List<GameQuestion> questions,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final questionsJson = json.encode(
        questions.map((q) => q.toJson()).toList(),
      );
      await prefs.setString('$_questionsPrefix$gameId', questionsJson);
    } catch (e) {
      print('Error saving questions to local storage: $e');
    }
  }

  /// Get default hardcoded questions for each game
  List<GameQuestion> _getDefaultQuestions(String gameId) {
    final List<Map<String, dynamic>> data = _getQuestionsData(gameId);
    return data.map((q) => GameQuestion.fromJson(q)).toList();
  }

  List<Map<String, dynamic>> _getQuestionsData(String gameId) {
    switch (gameId) {
      case 'truth_or_truth':
        return [
          {
            'question': 'What is your favorite memory of us together?',
            'category': 'memories',
            'question_translations': {
              'en': 'What is your favorite memory of us together?',
              'ar': 'ما هي ذكرى مفضلة لديك لنا معاً؟',
              'fr': 'Quel est votre souvenir préféré de nous ensemble ?',
            },
          },
          {
            'question': 'What do you appreciate most about our relationship?',
            'category': 'appreciation',
            'question_translations': {
              'en': 'What do you appreciate most about our relationship?',
              'ar': 'ما الذي تقدره أكثر في علاقتنا؟',
              'fr': 'Qu\'apprécies-tu le plus dans notre relation ?',
            },
          },
          {
            'question': 'What is one thing you would like us to do together?',
            'category': 'future',
            'question_translations': {
              'en': 'What is one thing you would like us to do together?',
              'ar': 'ما هو الشيء الوحيد الذي تود أن نفعله معاً؟',
              'fr':
                  'Quelle est la chose que vous aimeriez que nous fassions ensemble ?',
            },
          },
          {
            'question': 'What makes you feel most loved by me?',
            'category': 'love',
            'question_translations': {
              'en': 'What makes you feel most loved by me?',
              'ar': 'ما الذي يجعلك تشعر بأنك محبوب من قبلي أكثر من غيره؟',
              'fr': 'Qu\'est-ce qui te fait te sentir le plus aimé par moi ?',
            },
          },
          {
            'question': 'What is something you have always wanted to tell me?',
            'category': 'communication',
            'question_translations': {
              'en': 'What is something you have always wanted to tell me?',
              'ar': 'ما هو الشيء الذي أردت دائماً إخباري به؟',
              'fr': 'Quelle est la chose que tu as toujours voulu me dire ?',
            },
          },
          {
            'question': 'What is your biggest dream for our future together?',
            'category': 'future',
            'question_translations': {
              'en': 'What is your biggest dream for our future together?',
              'ar': 'ما هو حلمك الأكبر لمستقبلنا معاً؟',
              'fr': 'Quel est ton plus grand rêve pour notre avenir ensemble ?',
            },
          },
          {
            'question': 'What is one thing I do that always makes you smile?',
            'category': 'happiness',
            'question_translations': {
              'en': 'What is one thing I do that always makes you smile?',
              'ar': 'ما هو الشيء الوحيد الذي أفعله ويجعلك تبتسم دائماً؟',
              'fr':
                  'Quelle est la chose que je fais qui te fait toujours sourire ?',
            },
          },
          {
            'question':
                'What is your favorite thing about spending time with me?',
            'category': 'quality_time',
            'question_translations': {
              'en': 'What is your favorite thing about spending time with me?',
              'ar': 'ما هو الشيء المفضل لديك في قضاء الوقت معي؟',
              'fr':
                  'Quelle est votre chose préférée dans le fait de passer du temps avec moi ?',
            },
          },
          {
            'question': 'How do you feel when we are apart?',
            'category': 'connection',
            'question_translations': {
              'en': 'How do you feel when we are apart?',
              'ar': 'كيف تشعر عندما نكون افترقنا؟',
              'fr': 'Comment te sens-tu quand nous sommes séparés ?',
            },
          },
          {
            'question': 'What is one thing you admire about me?',
            'category': 'admiration',
            'question_translations': {
              'en': 'What is one thing you admire about me?',
              'ar': 'ما هو الشيء الوحيد الذي تعجب به فيّ؟',
              'fr': 'Quelle est la chose que tu admires chez moi ?',
            },
          },
        ];

      case 'love_language_quiz':
        return [
          {
            'question': 'Which scenario makes you feel more loved?',
            'category': 'preference',
            'question_translations': {
              'en': 'Which scenario makes you feel more loved?',
              'ar': 'أي سيناريو يجعلك تشعر بأنك محبوب أكثر؟',
              'fr': 'Quel scénario vous fait vous sentir plus aimé ?',
            },
            'options': [
              {
                'text': 'Receiving a thoughtful gift',
                'language': 'receiving_gifts',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Receiving a thoughtful gift',
                  'ar': 'تلقي هدية مدروسة',
                  'fr': 'Recevoir un cadeau attentionné',
                },
              },
              {
                'text': 'Spending uninterrupted time together',
                'language': 'quality_time',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Spending uninterrupted time together',
                  'ar': 'قضاء وقت غير متقطع معاً',
                  'fr': 'Passer du temps ininterrompu ensemble',
                },
              },
              {
                'text': 'Hearing "I love you" and compliments',
                'language': 'words_of_affirmation',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Hearing "I love you" and compliments',
                  'ar': 'سماع "أنا أحبك" ومجاملات',
                  'fr': 'Entendre "Je t\'aime" et des compliments',
                },
              },
              {
                'text': 'Having someone help with tasks',
                'language': 'acts_of_service',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Having someone help with tasks',
                  'ar': 'أن يساعدني أحدهم في المهام',
                  'fr': 'Avoir quelqu\'un qui aide aux tâches',
                },
              },
              {
                'text': 'Physical affection like hugs',
                'language': 'physical_touch',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Physical affection like hugs',
                  'ar': 'المودة الجسدية مثل العناق',
                  'fr': 'Affection physique comme des câlins',
                },
              },
            ],
          },
          {
            'question': 'What makes you feel most appreciated?',
            'category': 'appreciation',
            'question_translations': {
              'en': 'What makes you feel most appreciated?',
              'ar': 'ما الذي يجعلك تشعر بتقدير أكبر؟',
              'fr': 'Qu\'est-ce qui vous fait vous sentir le plus apprécié ?',
            },
            'options': [
              {
                'text': 'Words of encouragement',
                'language': 'words_of_affirmation',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Words of encouragement',
                  'ar': 'كلمات تشجيع',
                  'fr': 'Paroles d\'encouragement',
                },
              },
              {
                'text': 'Help with responsibilities',
                'language': 'acts_of_service',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Help with responsibilities',
                  'ar': 'المساعدة في المسؤوليات',
                  'fr': 'Aide aux responsabilités',
                },
              },
              {
                'text': 'Undivided attention',
                'language': 'quality_time',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Undivided attention',
                  'ar': 'انتباه كامل',
                  'fr': 'Attention exclusive',
                },
              },
              {
                'text': 'Surprise presents',
                'language': 'receiving_gifts',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Surprise presents',
                  'ar': 'هدايا مفاجئة',
                  'fr': 'Cadeaux surprises',
                },
              },
              {
                'text': 'Physical closeness',
                'language': 'physical_touch',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Physical closeness',
                  'ar': 'القرب الجسدي',
                  'fr': 'Proximité physique',
                },
              },
            ],
          },
          {
            'question': 'How do you prefer to show love?',
            'category': 'expression',
            'question_translations': {
              'en': 'How do you prefer to show love?',
              'ar': 'كيف تفضل إظهار الحب؟',
              'fr': 'Comment préférez-vous montrer votre amour ?',
            },
            'options': [
              {
                'text': 'Saying loving words',
                'language': 'words_of_affirmation',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Saying loving words',
                  'ar': 'قول كلمات محبة',
                  'fr': 'Dire des mots d\'amour',
                },
              },
              {
                'text': 'Doing helpful things',
                'language': 'acts_of_service',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Doing helpful things',
                  'ar': 'القيام بأشياء مفيدة',
                  'fr': 'Faire des choses utiles',
                },
              },
              {
                'text': 'Giving meaningful gifts',
                'language': 'receiving_gifts',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Giving meaningful gifts',
                  'ar': 'تقديم هدايا ذات معنى',
                  'fr': 'Offrir des cadeaux significatifs',
                },
              },
              {
                'text': 'Spending quality time',
                'language': 'quality_time',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Spending quality time',
                  'ar': 'قضاء وقت ممتع',
                  'fr': 'Passer du temps de qualité',
                },
              },
              {
                'text': 'Physical touch',
                'language': 'physical_touch',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Physical touch',
                  'ar': 'اللمس الجسدي',
                  'fr': 'Toucher physique',
                },
              },
            ],
          },
        ];

      case 'reflection_game':
        return [
          {
            'question':
                'What are three things you are grateful for in our relationship?',
            'category': 'gratitude',
            'question_translations': {
              'en':
                  'What are three things you are grateful for in our relationship?',
              'ar': 'ما هي ثلاثة أشياء تشعر بالامتنان لها في علاقتنا؟',
              'fr':
                  'Quelles sont les trois choses pour lesquelles vous êtes reconnaissant dans notre relation ?',
            },
          },
          {
            'question': 'Where do you see us in five years?',
            'category': 'future',
            'question_translations': {
              'en': 'Where do you see us in five years?',
              'ar': 'أين ترانا بعد خمس سنوات؟',
              'fr': 'Où nous voyez-vous dans cinq ans ?',
            },
          },
          {
            'question': 'What is one challenge we have overcome together?',
            'category': 'growth',
            'question_translations': {
              'en': 'What is one challenge we have overcome together?',
              'ar': 'ما هو التحدي الواحد الذي تجاوزناه معاً؟',
              'fr': 'Quel est le défi que nous avons surmonté ensemble ?',
            },
          },
          {
            'question': 'How have I helped you become a better person?',
            'category': 'impact',
            'question_translations': {
              'en': 'How have I helped you become a better person?',
              'ar': 'كيف ساعدتك لأصبح شخصاً أفضل؟',
              'fr': 'Comment t\'ai-je aidé à devenir une meilleure personne ?',
            },
          },
        ];

      case 'couples_challenge':
        return [
          {
            'question': 'Would You Rather',
            'description': 'Fun scenarios to explore preferences together',
            'question_translations': {
              'en': 'Would You Rather',
              'ar': 'ماذا تفضل',
              'fr': 'Tu préfères',
            },
            'description_translations': {
              'en': 'Fun scenarios to explore preferences together',
              'ar': 'سيناريوهات ممتعة لاستكشاف التفضيلات معاً',
              'fr':
                  'Des scénarios amusants pour explorer vos préférences ensemble',
            },
          },
          {
            'question': 'Dance Together',
            'description': 'Put on your favorite song and dance for 2 minutes',
            'question_translations': {
              'en': 'Dance Together',
              'ar': 'الرقص معاً',
              'fr': 'Danser ensemble',
            },
            'description_translations': {
              'en': 'Put on your favorite song and dance for 2 minutes',
              'ar': 'شغل أغنيتك المفضلة وارقص لمدة دقيقتين',
              'fr': 'Mettez votre chanson préférée et dansez pendant 2 minutes',
            },
          },
          {
            'question': 'Compliment Battle',
            'description':
                'Take turns giving each other compliments for 3 minutes',
            'question_translations': {
              'en': 'Compliment Battle',
              'ar': 'معركة المجاملات',
              'fr': 'Bataille de compliments',
            },
            'description_translations': {
              'en': 'Take turns giving each other compliments for 3 minutes',
              'ar':
                  'تبادلا الأدوار في تقديم المجاملات لبعضكما البعض لمدة 3 دقائق',
              'fr': 'Donnez-vous des compliments tour à tour pendant 3 minutes',
            },
          },
          {
            'question': 'Memory Lane',
            'description':
                'Share your favorite memory together and why it\'s special',
            'question_translations': {
              'en': 'Memory Lane',
              'ar': 'ممر الذكريات',
              'fr': 'Allée des souvenirs',
            },
            'description_translations': {
              'en': 'Share your favorite memory together and why it\'s special',
              'ar': 'شاركا ذكرياتكما المفضلة معاً ولماذا هي مميزة',
              'fr':
                  'Partagez votre souvenir préféré ensemble et pourquoi il est spécial',
            },
          },
          {
            'question': 'Future Planning',
            'description': 'Describe your dream vacation together in detail',
            'question_translations': {
              'en': 'Future Planning',
              'ar': 'تخطيط المستقبل',
              'fr': 'Planification future',
            },
            'description_translations': {
              'en': 'Describe your dream vacation together in detail',
              'ar': 'صفا عطلتكما الحلم معاً بالتفصيل',
              'fr': 'Décrivez en détail vos vacances de rêve ensemble',
            },
          },
          {
            'question': 'Gratitude Circle',
            'description': 'List 5 things you appreciate about each other',
            'question_translations': {
              'en': 'Gratitude Circle',
              'ar': 'دائرة الامتنان',
              'fr': 'Cercle de gratitude',
            },
            'description_translations': {
              'en': 'List 5 things you appreciate about each other',
              'ar': 'اذكرا 5 أشياء تقدرانها في بعضكما البعض',
              'fr': 'Listez 5 choses que vous appréciez l\'un chez l\'autre',
            },
          },
          {
            'question': 'Eye Contact',
            'description':
                'Maintain eye contact for 60 seconds without laughing',
            'question_translations': {
              'en': 'Eye Contact',
              'ar': 'التواصل البصري',
              'fr': 'Contact visuel',
            },
            'description_translations': {
              'en': 'Maintain eye contact for 60 seconds without laughing',
              'ar': 'حافظا على التواصل البصري لمدة 60 ثانية دون الضحك',
              'fr': 'Maintenez un contact visuel pendant 60 secondes sans rire',
            },
          },
          {
            'question': 'Love Letter',
            'description': 'Write a short love note to each other (2 minutes)',
            'question_translations': {
              'en': 'Love Letter',
              'ar': 'رسالة حب',
              'fr': 'Lettre d\'amour',
            },
            'description_translations': {
              'en': 'Write a short love note to each other (2 minutes)',
              'ar': 'اكتبا رسالة حب قصيرة لبعضكما البعض (دقيقتين)',
              'fr': 'Écrivez-vous une courte note d\'amour (2 minutes)',
            },
          },
          {
            'question': 'Dream Date',
            'description':
                'Plan your perfect date night together with no budget limit',
            'question_translations': {
              'en': 'Dream Date',
              'ar': 'موعد الأحلام',
              'fr': 'Rendez-vous de rêve',
            },
            'description_translations': {
              'en':
                  'Plan your perfect date night together with no budget limit',
              'ar': 'خططا لموعدكما الليلي المثالي معاً بدون قيود على الميزانية',
              'fr':
                  'Planifiez votre soirée de rendez-vous parfaite ensemble sans limite de budget',
            },
          },
          {
            'question': 'Bucket List',
            'description':
                'Share 3 things you want to do together before next year',
            'question_translations': {
              'en': 'Bucket List',
              'ar': 'قائمة الأمنيات',
              'fr': 'Liste de choses à faire',
            },
            'description_translations': {
              'en': 'Share 3 things you want to do together before next year',
              'ar': 'شاركا 3 أشياء ترغبان في القيام بها معاً قبل العام المقبل',
              'fr':
                  'Partagez 3 choses que vous voulez faire ensemble avant l\'année prochaine',
            },
          },
        ];

      case 'would_you_rather':
        return [
          {
            'question':
                'Would you rather plan a surprise date or be surprised?',
            'optionA': 'Plan a surprise date',
            'optionB': 'Be surprised',
            'question_translations': {
              'en': 'Would you rather plan a surprise date or be surprised?',
              'ar': 'هل تفضل التخطيط لموعد مفاجئ أو أن تُفاجأ؟',
              'fr':
                  'Préféreriez-vous organiser un rendez-vous surprise ou être surpris ?',
            },
            'optionA_translations': {
              'en': 'Plan a surprise date',
              'ar': 'خطط لموعد مفاجئ',
              'fr': 'Planifier un rendez-vous surprise',
            },
            'optionB_translations': {
              'en': 'Be surprised',
              'ar': 'كن متفاجئاً',
              'fr': 'Être surpris',
            },
          },
          {
            'question':
                'Would you rather have a romantic dinner or a fun adventure?',
            'optionA': 'Romantic dinner',
            'optionB': 'Fun adventure',
            'question_translations': {
              'en':
                  'Would you rather have a romantic dinner or a fun adventure?',
              'ar': 'هل تفضل تناول عشاء رومانسي أو خوض مغامرة ممتعة؟',
              'fr':
                  'Préféreriez-vous un dîner romantique ou une aventure amusante ?',
            },
            'optionA_translations': {
              'en': 'Romantic dinner',
              'ar': 'عشاء رومانسي',
              'fr': 'Dîner romantique',
            },
            'optionB_translations': {
              'en': 'Fun adventure',
              'ar': 'مغامرة ممتعة',
              'fr': 'Aventure amusante',
            },
          },
          {
            'question':
                'Would you rather watch a movie at home or go to the cinema?',
            'optionA': 'Watch at home',
            'optionB': 'Go to cinema',
            'question_translations': {
              'en':
                  'Would you rather watch a movie at home or go to the cinema?',
              'ar': 'هل تفضل مشاهدة فيلم في المنزل أم الذهاب إلى السينما؟',
              'fr':
                  'Préféreriez-vous regarder un film à la maison ou aller au cinéma ?',
            },
            'optionA_translations': {
              'en': 'Watch at home',
              'ar': 'شاهد في المنزل',
              'fr': 'Regarder à la maison',
            },
            'optionB_translations': {
              'en': 'Go to cinema',
              'ar': 'اذهب إلى السينما',
              'fr': 'Aller au cinéma',
            },
          },
          {
            'question': 'Would you rather cook together or order takeout?',
            'optionA': 'Cook together',
            'optionB': 'Order takeout',
            'question_translations': {
              'en': 'Would you rather cook together or order takeout?',
              'ar': 'هل تفضلان الطهي معاً أم طلب الطعام الجاهز؟',
              'fr':
                  'Préféreriez-vous cuisiner ensemble ou commander à emporter ?',
            },
            'optionA_translations': {
              'en': 'Cook together',
              'ar': 'اطبخوا معاً',
              'fr': 'Cuisiner ensemble',
            },
            'optionB_translations': {
              'en': 'Order takeout',
              'ar': 'اطلبوا طعاماً جاهزاً',
              'fr': 'Commander à emporter',
            },
          },
          {
            'question': 'Would you rather go for a walk or have a picnic?',
            'optionA': 'Go for a walk',
            'optionB': 'Have a picnic',
            'question_translations': {
              'en': 'Would you rather go for a walk or have a picnic?',
              'ar': 'هل تفضلان الذهاب في نزهة أم تناول نزهة؟',
              'fr': 'Préféreriez-vous faire une promenade ou pique-niquer ?',
            },
            'optionA_translations': {
              'en': 'Go for a walk',
              'ar': 'اذهبوا في نزهة',
              'fr': 'Faire une promenade',
            },
            'optionB_translations': {
              'en': 'Have a picnic',
              'ar': 'تناولوا نزهة',
              'fr': 'Pique-niquer',
            },
          },
          {
            'question':
                'Would you rather play a game or have deep conversations?',
            'optionA': 'Play a game',
            'optionB': 'Deep conversations',
            'question_translations': {
              'en': 'Would you rather play a game or have deep conversations?',
              'ar': 'هل تفضلان لعب لعبة أم إجراء محادثات عميقة؟',
              'fr':
                  'Préféreriez-vous jouer à un jeu ou avoir des conversations profondes ?',
            },
            'optionA_translations': {
              'en': 'Play a game',
              'ar': 'العبوا لعبة',
              'fr': 'Jouer à un jeu',
            },
            'optionB_translations': {
              'en': 'Deep conversations',
              'ar': 'محادثات عميقة',
              'fr': 'Conversations profondes',
            },
          },
          {
            'question':
                'Would you rather exchange gifts or spend quality time?',
            'optionA': 'Exchange gifts',
            'optionB': 'Quality time',
            'question_translations': {
              'en': 'Would you rather exchange gifts or spend quality time?',
              'ar': 'هل تفضلان تبادل الهدايا أم قضاء وقت ممتع؟',
              'fr':
                  'Préféreriez-vous échanger des cadeaux ou passer du temps de qualité ?',
            },
            'optionA_translations': {
              'en': 'Exchange gifts',
              'ar': 'تبادلوا الهدايا',
              'fr': 'Échanger des cadeaux',
            },
            'optionB_translations': {
              'en': 'Quality time',
              'ar': 'وقت ممتع',
              'fr': 'Temps de qualité',
            },
          },
          {
            'question': 'Would you rather dance together or sing together?',
            'optionA': 'Dance together',
            'optionB': 'Sing together',
            'question_translations': {
              'en': 'Would you rather dance together or sing together?',
              'ar': 'هل تفضلان الرقص معاً أم الغناء معاً؟',
              'fr': 'Préféreriez-vous danser ensemble ou chanter ensemble ?',
            },
            'optionA_translations': {
              'en': 'Dance together',
              'ar': 'الرقص معاً',
              'fr': 'Danser ensemble',
            },
            'optionB_translations': {
              'en': 'Sing together',
              'ar': 'الغناء معاً',
              'fr': 'Chanter ensemble',
            },
          },
          {
            'question': 'Would you rather stay in pajamas all day or dress up?',
            'optionA': 'Pajamas all day',
            'optionB': 'Dress up',
            'question_translations': {
              'en': 'Would you rather stay in pajamas all day or dress up?',
              'ar':
                  'هل تفضلان البقاء في البيجامة طوال اليوم أم ارتداء ملابس أنيقة؟',
              'fr':
                  'Préféreriez-vous rester en pyjama toute la journée ou vous habiller ?',
            },
            'optionA_translations': {
              'en': 'Pajamas all day',
              'ar': 'بيجامة طوال اليوم',
              'fr': 'Pyjama toute la journée',
            },
            'optionB_translations': {
              'en': 'Dress up',
              'ar': 'ارتدوا ملابس أنيقة',
              'fr': 'S\'habiller',
            },
          },
          {
            'question':
                'Would you rather take photos together or just enjoy the moment?',
            'optionA': 'Take photos',
            'optionB': 'Enjoy the moment',
            'question_translations': {
              'en':
                  'Would you rather take photos together or just enjoy the moment?',
              'ar': 'هل تفضلان التقاط الصور معاً أم الاستمتاع باللحظة فقط؟',
              'fr':
                  'Préféreriez-vous prendre des photos ensemble ou simplement profiter du moment ?',
            },
            'optionA_translations': {
              'en': 'Take photos',
              'ar': 'التقطوا الصور',
              'fr': 'Prendre des photos',
            },
            'optionB_translations': {
              'en': 'Enjoy the moment',
              'ar': 'استمتعوا باللحظة',
              'fr': 'Profiter du moment',
            },
          },
        ];

      case 'date_night_ideas':
        return [
          {
            'title': 'Stargazing Picnic',
            'description':
                'Pack a blanket, snacks, and gaze at the stars together',
            'budget': 'Low',
            'title_translations': {
              'en': 'Stargazing Picnic',
              'ar': 'نزهة مراقبة النجوم',
              'fr': 'Pique-nique sous les étoiles',
            },
            'description_translations': {
              'en': 'Pack a blanket, snacks, and gaze at the stars together',
              'ar': 'احزم بطانية وبعض الوجبات الخفيفة وتأمل النجوم معاً',
              'fr':
                  'Préparez une couverture, des collations et contemplez les étoiles ensemble',
            },
          },
          {
            'title': 'Cooking Class',
            'description': 'Learn to make a new cuisine together',
            'budget': 'Medium',
            'title_translations': {
              'en': 'Cooking Class',
              'ar': 'درس طبخ',
              'fr': 'Cours de cuisine',
            },
            'description_translations': {
              'en': 'Learn to make a new cuisine together',
              'ar': 'تعلما طهي صنف جديد معاً',
              'fr': 'Apprenez à préparer une nouvelle cuisine ensemble',
            },
          },
          {
            'title': 'Sunset Beach Walk',
            'description': 'Enjoy a romantic walk along the shore at sunset',
            'budget': 'Low',
            'title_translations': {
              'en': 'Sunset Beach Walk',
              'ar': 'نزهة شاطئية عند الغروب',
              'fr': 'Promenade sur la plage au coucher du soleil',
            },
            'description_translations': {
              'en': 'Enjoy a romantic walk along the shore at sunset',
              'ar': 'استمتعا بنزهة رومانسية على طول الشاطئ عند غروب الشمس',
              'fr':
                  'Profitez d\'une promenade romantique le long du rivage au coucher du soleil',
            },
          },
          {
            'title': 'Wine Tasting',
            'description': 'Visit a local winery or create a home tasting',
            'budget': 'Medium',
            'title_translations': {
              'en': 'Wine Tasting',
              'ar': 'تذوق النبيذ',
              'fr': 'Dégustation de vin',
            },
            'description_translations': {
              'en': 'Visit a local winery or create a home tasting',
              'ar': 'زورا مصنع نبيذ محلي أو قوما بتجربة تذوق في المنزل',
              'fr':
                  'Visitez une cave locale ou organisez une dégustation à domicile',
            },
          },
          {
            'title': 'Amusement Park',
            'description': 'Relive childhood with rides and games',
            'budget': 'High',
            'title_translations': {
              'en': 'Amusement Park',
              'ar': 'مدينة الملاهي',
              'fr': 'Parc d\'attractions',
            },
            'description_translations': {
              'en': 'Relive childhood with rides and games',
              'ar': 'استعيدا ذكريات الطفولة مع الألعاب والركوب',
              'fr': 'Revivez votre enfance avec des manèges et des jeux',
            },
          },
          {
            'title': 'Art Museum Visit',
            'description': 'Explore art and discuss your favorites',
            'budget': 'Low',
            'title_translations': {
              'en': 'Art Museum Visit',
              'ar': 'زيارة متحف فني',
              'fr': 'Visite de musée d\'art',
            },
            'description_translations': {
              'en': 'Explore art and discuss your favorites',
              'ar': 'استكشفا الفن وناقشا مفضلاتكما',
              'fr': 'Explorez l\'art et discutez de vos œuvres préférées',
            },
          },
          {
            'title': 'Couples Spa Night',
            'description': 'Create a spa experience at home with massages',
            'budget': 'Low',
            'title_translations': {
              'en': 'Couples Spa Night',
              'ar': 'ليلة سبا للزوجين',
              'fr': 'Soirée spa en couple',
            },
            'description_translations': {
              'en': 'Create a spa experience at home with massages',
              'ar': 'اصنعا تجربة سبا في المنزل مع التدليك',
              'fr': 'Créez une expérience spa à la maison avec des massages',
            },
          },
          {
            'title': 'Road Trip Adventure',
            'description': 'Drive to a nearby town you have never visited',
            'budget': 'Medium',
            'title_translations': {
              'en': 'Road Trip Adventure',
              'ar': 'مغامرة رحلة برية',
              'fr': 'Aventure en road trip',
            },
            'description_translations': {
              'en': 'Drive to a nearby town you have never visited',
              'ar': 'قودا إلى بلدة قريبة لم تزوراها من قبل',
              'fr':
                  'Conduisez vers une ville voisine que vous n\'avez jamais visitée',
            },
          },
          {
            'title': 'Fine Dining Experience',
            'description': 'Dress up and enjoy a fancy dinner',
            'budget': 'High',
            'title_translations': {
              'en': 'Fine Dining Experience',
              'ar': 'تجربة عشاء فاخرة',
              'fr': 'Expérience gastronomique',
            },
            'description_translations': {
              'en': 'Dress up and enjoy a fancy dinner',
              'ar': 'ارتديا ملابس أنيقة واستمتعا بعشاء فاخر',
              'fr': 'Habillez-vous et profitez d\'un dîner chic',
            },
          },
          {
            'title': 'DIY Pizza Night',
            'description': 'Make personalized pizzas and get creative',
            'budget': 'Low',
            'title_translations': {
              'en': 'DIY Pizza Night',
              'ar': 'ليلة بيتزا منزلية',
              'fr': 'Soirée pizza DIY',
            },
            'description_translations': {
              'en': 'Make personalized pizzas and get creative',
              'ar': 'اصنعا بيتزا مخصصة وكونا مبدعين',
              'fr': 'Faites des pizzas personnalisées et soyez créatifs',
            },
          },
        ];

      case 'relationship_quiz':
        return [
          {
            'question':
                'What is your partner\'s favorite way to spend a weekend?',
            'question_translations': {
              'en': 'What is your partner\'s favorite way to spend a weekend?',
              'ar': 'ما هي الطريقة المفضلة لشريكك لقضاء عطلة نهاية الأسبوع؟',
              'fr':
                  'Quelle est la façon préférée de votre partenaire de passer un week-end ?',
            },
            'options': [
              {
                'text': 'Going out and exploring',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Going out and exploring',
                  'ar': 'الخروج والاستكشاف',
                  'fr': 'Sortir et explorer',
                },
              },
              {
                'text': 'Relaxing at home',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Relaxing at home',
                  'ar': 'الاسترخاء في المنزل',
                  'fr': 'Se détendre à la maison',
                },
              },
              {
                'text': 'It depends on their mood',
                'isCorrect': true,
                'text_translations': {
                  'en': 'It depends on their mood',
                  'ar': 'يعتمد على مزاجهم',
                  'fr': 'Cela dépend de leur humeur',
                },
              },
              {
                'text': 'Working on projects',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Working on projects',
                  'ar': 'العمل على المشاريع',
                  'fr': 'Travailler sur des projets',
                },
              },
            ],
          },
          {
            'question': 'What is your partner\'s love language?',
            'question_translations': {
              'en': 'What is your partner\'s love language?',
              'ar': 'ما هي لغة الحب لشريكك؟',
              'fr': 'Quelle est la langue d\'amour de votre partenaire ?',
            },
            'options': [
              {
                'text': 'Words of affirmation',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Words of affirmation',
                  'ar': 'كلمات التوكيد',
                  'fr': 'Paroles valorisantes',
                },
              },
              {
                'text': 'Acts of service',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Acts of service',
                  'ar': 'أعمال الخدمة',
                  'fr': 'Services rendus',
                },
              },
              {
                'text': 'Quality time',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Quality time',
                  'ar': 'وقت ممتع',
                  'fr': 'Temps de qualité',
                },
              },
              {
                'text': 'Physical touch',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Physical touch',
                  'ar': 'اللمس الجسدي',
                  'fr': 'Toucher physique',
                },
              },
              {
                'text': 'Receiving gifts',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Receiving gifts',
                  'ar': 'تلقي الهدايا',
                  'fr': 'Cadeaux',
                },
              },
            ],
          },
          {
            'question': 'What makes your partner feel most appreciated?',
            'question_translations': {
              'en': 'What makes your partner feel most appreciated?',
              'ar': 'ما الذي يجعل شريكك يشعر بتقدير أكبر؟',
              'fr':
                  'Qu\'est-ce qui fait que votre partenaire se sent le plus apprécié ?',
            },
            'options': [
              {
                'text': 'When you help with chores',
                'isCorrect': false,
                'text_translations': {
                  'en': 'When you help with chores',
                  'ar': 'عندما تساعد في الأعمال المنزلية',
                  'fr': 'Quand vous aidez aux tâches ménagères',
                },
              },
              {
                'text': 'When you give compliments',
                'isCorrect': false,
                'text_translations': {
                  'en': 'When you give compliments',
                  'ar': 'عندما تقدم المجاملات',
                  'fr': 'Quand vous faites des compliments',
                },
              },
              {
                'text': 'When you spend time together',
                'isCorrect': false,
                'text_translations': {
                  'en': 'When you spend time together',
                  'ar': 'عندما تقضون وقتاً معاً',
                  'fr': 'Quand vous passez du temps ensemble',
                },
              },
              {
                'text': 'Only they can tell you',
                'isCorrect': true,
                'text_translations': {
                  'en': 'Only they can tell you',
                  'ar': 'هم فقط من يمكنهم إخبارك',
                  'fr': 'Seuls eux peuvent vous le dire',
                },
              },
            ],
          },
          {
            'question': 'What is your partner\'s biggest dream?',
            'question_translations': {
              'en': 'What is your partner\'s biggest dream?',
              'ar': 'ما هو أكبر حلم لشريكك؟',
              'fr': 'Quel est le plus grand rêve de votre partenaire ?',
            },
            'options': [
              {
                'text': 'Career success',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Career success',
                  'ar': 'النجاح المهني',
                  'fr': 'Réussite professionnelle',
                },
              },
              {
                'text': 'Starting a family',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Starting a family',
                  'ar': 'تكوين أسرة',
                  'fr': 'Fonder une famille',
                },
              },
              {
                'text': 'Traveling the world',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Traveling the world',
                  'ar': 'السفر حول العالم',
                  'fr': 'Voyager autour du monde',
                },
              },
              {
                'text': 'Ask them and find out',
                'isCorrect': true,
                'text_translations': {
                  'en': 'Ask them and find out',
                  'ar': 'اسألهم واكتشف',
                  'fr': 'Demandez-leur et découvrez',
                },
              },
            ],
          },
          {
            'question': 'How does your partner prefer to resolve conflicts?',
            'question_translations': {
              'en': 'How does your partner prefer to resolve conflicts?',
              'ar': 'كيف يفضل شريكك حل النزاعات؟',
              'fr':
                  'Comment votre partenaire préfère-t-il résoudre les conflits ?',
            },
            'options': [
              {
                'text': 'Talk immediately',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Talk immediately',
                  'ar': 'تحدث فوراً',
                  'fr': 'Parler immédiatement',
                },
              },
              {
                'text': 'Take space then talk',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Take space then talk',
                  'ar': 'خذ مساحة ثم تحدث',
                  'fr': 'Prendre de l\'espace puis parler',
                },
              },
              {
                'text': 'Write about it first',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Write about it first',
                  'ar': 'اكتب عنها أولاً',
                  'fr': 'Écrire à ce sujet d\'abord',
                },
              },
              {
                'text': 'Every person is different',
                'isCorrect': true,
                'text_translations': {
                  'en': 'Every person is different',
                  'ar': 'كل شخص مختلف',
                  'fr': 'Chaque personne est différente',
                },
              },
            ],
          },
          {
            'question': 'What is your partner\'s favorite meal?',
            'question_translations': {
              'en': 'What is your partner\'s favorite meal?',
              'ar': 'ما هي وجبة شريكك المفضلة؟',
              'fr': 'Quel est le plat préféré de votre partenaire ?',
            },
            'options': [
              {
                'text': 'Italian food',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Italian food',
                  'ar': 'طعام إيطالي',
                  'fr': 'Cuisine italienne',
                },
              },
              {
                'text': 'Asian cuisine',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Asian cuisine',
                  'ar': 'مطبخ آسيوي',
                  'fr': 'Cuisine asiatique',
                },
              },
              {
                'text': 'Home-cooked comfort food',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Home-cooked comfort food',
                  'ar': 'طعام منزلي مريح',
                  'fr': 'Plat réconfortant fait maison',
                },
              },
              {
                'text': 'Think about what they love',
                'isCorrect': true,
                'text_translations': {
                  'en': 'Think about what they love',
                  'ar': 'فكر فيما يحبونه',
                  'fr': 'Pensez à ce qu\'ils aiment',
                },
              },
            ],
          },
          {
            'question': 'What activity makes your partner happiest?',
            'question_translations': {
              'en': 'What activity makes your partner happiest?',
              'ar': 'ما هو النشاط الذي يجعل شريكك الأكثر سعادة؟',
              'fr': 'Quelle activité rend votre partenaire le plus heureux ?',
            },
            'options': [
              {
                'text': 'Being outdoors',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Being outdoors',
                  'ar': 'الوجود في الهواء الطلق',
                  'fr': 'Être en plein air',
                },
              },
              {
                'text': 'Creative projects',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Creative projects',
                  'ar': 'المشاريع الإبداعية',
                  'fr': 'Projets créatifs',
                },
              },
              {
                'text': 'Social gatherings',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Social gatherings',
                  'ar': 'التجمعات الاجتماعية',
                  'fr': 'Réunions sociales',
                },
              },
              {
                'text': 'Reflect on their joy',
                'isCorrect': true,
                'text_translations': {
                  'en': 'Reflect on their joy',
                  'ar': 'تأمل في سعادتهم',
                  'fr': 'Réfléchissez à leur joie',
                },
              },
            ],
          },
          {
            'question': 'What is your partner most proud of?',
            'question_translations': {
              'en': 'What is your partner most proud of?',
              'ar': 'ما هو أكثر شيء يفخر به شريكك؟',
              'fr': 'De quoi votre partenaire est-il le plus fier ?',
            },
            'options': [
              {
                'text': 'Their career',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Their career',
                  'ar': 'مسيرتهم المهنية',
                  'fr': 'Leur carrière',
                },
              },
              {
                'text': 'Their relationships',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Their relationships',
                  'ar': 'علاقاتهم',
                  'fr': 'Leurs relations',
                },
              },
              {
                'text': 'Personal achievements',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Personal achievements',
                  'ar': 'الإنجازات الشخصية',
                  'fr': 'Réalisations personnelles',
                },
              },
              {
                'text': 'Consider their values',
                'isCorrect': true,
                'text_translations': {
                  'en': 'Consider their values',
                  'ar': 'فكر في قيمهم',
                  'fr': 'Considérez leurs valeurs',
                },
              },
            ],
          },
          {
            'question': 'How does your partner show love?',
            'question_translations': {
              'en': 'How does your partner show love?',
              'ar': 'كيف يظهر شريكك الحب؟',
              'fr': 'Comment votre partenaire montre-t-il son amour ?',
            },
            'options': [
              {
                'text': 'Through gifts',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Through gifts',
                  'ar': 'من خلال الهدايا',
                  'fr': 'Par des cadeaux',
                },
              },
              {
                'text': 'Through actions',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Through actions',
                  'ar': 'من خلال الأفعال',
                  'fr': 'Par des actions',
                },
              },
              {
                'text': 'Through words',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Through words',
                  'ar': 'من خلال الكلمات',
                  'fr': 'Par des mots',
                },
              },
              {
                'text': 'Observe their behavior',
                'isCorrect': true,
                'text_translations': {
                  'en': 'Observe their behavior',
                  'ar': 'راقب سلوكهم',
                  'fr': 'Observez leur comportement',
                },
              },
            ],
          },
          {
            'question': 'What does your partner need most right now?',
            'question_translations': {
              'en': 'What does your partner need most right now?',
              'ar': 'ماذا يحتاج شريكك أكثر الآن؟',
              'fr':
                  'De quoi votre partenaire a-t-il le plus besoin en ce moment ?',
            },
            'options': [
              {
                'text': 'More time together',
                'isCorrect': false,
                'text_translations': {
                  'en': 'More time together',
                  'ar': 'المزيد من الوقت معاً',
                  'fr': 'Plus de temps ensemble',
                },
              },
              {
                'text': 'Support with stress',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Support with stress',
                  'ar': 'الدعم في التعامل مع التوتر',
                  'fr': 'Soutien face au stress',
                },
              },
              {
                'text': 'Encouragement',
                'isCorrect': false,
                'text_translations': {
                  'en': 'Encouragement',
                  'ar': 'التشجيع',
                  'fr': 'Encouragement',
                },
              },
              {
                'text': 'Open communication',
                'isCorrect': true,
                'text_translations': {
                  'en': 'Open communication',
                  'ar': 'التواصل المفتوح',
                  'fr': 'Communication ouverte',
                },
              },
            ],
          },
        ];

      case 'compliment_game':
        return [
          {
            'prompt':
                'Share what you look forward to most about your future together',
            'hint': 'Think about your dreams',
            'prompt_translations': {
              'en':
                  'Share what you look forward to most about your future together',
              'ar': 'شارك أكثر ما تتطلع إليه في مستقبلكما معاً',
              'fr':
                  'Partagez ce que vous attendez avec le plus d\'impatience de votre avenir ensemble',
            },
            'hint_translations': {
              'en': 'Think about your dreams',
              'ar': 'فكر في أحلامك',
              'fr': 'Pensez à vos rêves',
            },
          },
          {
            'prompt':
                'What is one quality in your partner that you admire most?',
            'hint': 'Think about their character',
            'prompt_translations': {
              'en': 'What is one quality in your partner that you admire most?',
              'ar': 'ما هي الصفة الواحدة في شريكك التي تعجبك أكثر؟',
              'fr':
                  'Quelle est la qualité que tu admires le plus chez ton partenaire ?',
            },
            'hint_translations': {
              'en': 'Think about their character',
              'ar': 'فكر في شخصيتهم',
              'fr': 'Pensez à leur caractère',
            },
          },
          {
            'prompt':
                'Mention a time when your partner made you feel really special',
            'hint': 'Recall a specific moment',
            'prompt_translations': {
              'en':
                  'Mention a time when your partner made you feel really special',
              'ar': 'اذكر وقتاً جعلك فيه شريكك تشعر بخصوصية حقيقية',
              'fr':
                  'Mentionnez un moment où votre partenaire vous a fait vous sentir vraiment spécial',
            },
            'hint_translations': {
              'en': 'Recall a specific moment',
              'ar': 'تذكر لحظة محددة',
              'fr': 'Rappelez-vous un moment précis',
            },
          },
          {
            'prompt':
                'What is something your partner does that always makes you smile?',
            'hint': 'Think about their habits',
            'prompt_translations': {
              'en':
                  'What is something your partner does that always makes you smile?',
              'ar': 'ما هو الشيء الذي يفعله شريكك ويجعلك تبتسم دائماً؟',
              'fr':
                  'Qu\'est-ce que ton partenaire fait qui te fait toujours sourire ?',
            },
            'hint_translations': {
              'en': 'Think about their habits',
              'ar': 'فكر في عاداتهم',
              'fr': 'Pensez à leurs habitudes',
            },
          },
          {
            'prompt': 'Tell your partner why you are proud of them',
            'hint': 'Think about their achievements',
            'prompt_translations': {
              'en': 'Tell your partner why you are proud of them',
              'ar': 'أخبر شريكك لماذا أنت فخور به',
              'fr': 'Dites à votre partenaire pourquoi vous êtes fier d\'eux',
            },
            'hint_translations': {
              'en': 'Think about their achievements',
              'ar': 'فكر في إنجازاتهم',
              'fr': 'Pensez à leurs réalisations',
            },
          },
        ];

      default:
        return [
          {
            'question': 'What do you love most about us?',
            'category': 'general',
          },
        ];
    }
  }

  /// Clear stored questions for a game (for testing)
  Future<void> clearStoredQuestions(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_questionsPrefix$gameId');
      await prefs.remove('$_lastGeneratedPrefix$gameId');
    } catch (e) {
      print('Error clearing questions: $e');
    }
  }
}
