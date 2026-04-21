import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'package:velmora/services/ai_service.dart';
import 'package:flutter/foundation.dart';

class GameContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AIService _aiService = AIService();

  String get _userId => _auth.currentUser?.uid ?? '';

  /// Check if content needs refresh (monthly)
  Future<bool> needsContentRefresh(String gameId) async {
    try {
      final doc = await _firestore
          .collection('game_content_versions')
          .doc('${gameId}_version')
          .get();

      if (!doc.exists) return true;

      final lastRefresh = (doc.data()?['lastRefresh'] as Timestamp?)?.toDate();
      if (lastRefresh == null) return true;

      final now = DateTime.now();
      final daysSinceRefresh = now.difference(lastRefresh).inDays;

      // Refresh every 30 days
      return daysSinceRefresh >= 30;
    } catch (e) {
      print('Error checking content refresh: $e');
      return false;
    }
  }

  /// Get current content version
  Future<int> getCurrentVersion(String gameId) async {
    try {
      final doc = await _firestore
          .collection('game_content_versions')
          .doc('${gameId}_version')
          .get();

      return doc.data()?['version'] ?? 1;
    } catch (e) {
      print('Error getting version: $e');
      return 1;
    }
  }

  /// Refresh game content (Truth or Truth)
  Future<void> refreshTruthOrTruthContent() async {
    try {
      List<Map<String, dynamic>> questions;
      try {
        questions = await _aiService.generateGameContent('truth_or_truth');
      } catch (e) {
        debugPrint(
          'AI generation failed, using default Truth or Truth content: $e',
        );
        questions = _generateDefaultTruthOrTruthQuestions();
      }

      final version = await getCurrentVersion('truth_or_truth');
      final newVersion = version + 1;

      // Save new questions
      final batch = _firestore.batch();

      for (var i = 0; i < questions.length; i++) {
        final docRef = _firestore
            .collection('games')
            .doc('truth_or_truth')
            .collection('questions')
            .doc('q_v${newVersion}_$i');

        batch.set(docRef, {
          ...questions[i],
          'version': newVersion,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Update version
      batch.set(
        _firestore
            .collection('game_content_versions')
            .doc('truth_or_truth_version'),
        {
          'version': newVersion,
          'lastRefresh': FieldValue.serverTimestamp(),
          'questionCount': questions.length,
        },
      );

      await batch.commit();
      print('Truth or Truth content refreshed to version $newVersion');
    } catch (e) {
      print('Error refreshing Truth or Truth content: $e');
    }
  }

  /// Refresh game content (Love Language Quiz)
  Future<void> refreshLoveLanguageContent() async {
    try {
      List<Map<String, dynamic>> questions;
      try {
        questions = await _aiService.generateGameContent('love_language_quiz');
      } catch (e) {
        debugPrint(
          'AI generation failed, using default Love Language content: $e',
        );
        questions = _generateDefaultLoveLanguageQuestions();
      }

      final version = await getCurrentVersion('love_language_quiz');
      final newVersion = version + 1;

      final batch = _firestore.batch();

      for (var i = 0; i < questions.length; i++) {
        final docRef = _firestore
            .collection('games')
            .doc('love_language_quiz')
            .collection('questions')
            .doc('q_v${newVersion}_$i');

        batch.set(docRef, {
          ...questions[i],
          'version': newVersion,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      batch.set(
        _firestore
            .collection('game_content_versions')
            .doc('love_language_quiz_version'),
        {
          'version': newVersion,
          'lastRefresh': FieldValue.serverTimestamp(),
          'questionCount': questions.length,
        },
      );

      await batch.commit();
      print('Love Language Quiz content refreshed to version $newVersion');
    } catch (e) {
      print('Error refreshing Love Language content: $e');
    }
  }

  /// Refresh game content (Reflection & Discussion)
  Future<void> refreshReflectionContent() async {
    try {
      List<Map<String, dynamic>> questions;
      try {
        questions = await _aiService.generateGameContent('reflection_game');
      } catch (e) {
        debugPrint(
          'AI generation failed, using default Reflection content: $e',
        );
        questions = _generateDefaultReflectionQuestions();
      }

      final version = await getCurrentVersion('reflection_game');
      final newVersion = version + 1;

      final batch = _firestore.batch();

      for (var i = 0; i < questions.length; i++) {
        final docRef = _firestore
            .collection('games')
            .doc('reflection_game')
            .collection('questions')
            .doc('q_v${newVersion}_$i');

        batch.set(docRef, {
          ...questions[i],
          'version': newVersion,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      batch.set(
        _firestore
            .collection('game_content_versions')
            .doc('reflection_game_version'),
        {
          'version': newVersion,
          'lastRefresh': FieldValue.serverTimestamp(),
          'questionCount': questions.length,
        },
      );

      await batch.commit();
      print('Reflection content refreshed to version $newVersion');
    } catch (e) {
      print('Error refreshing Reflection content: $e');
    }
  }

  /// Refresh all game content
  Future<void> refreshAllContent() async {
    await refreshTruthOrTruthContent();
    await refreshLoveLanguageContent();
    await refreshReflectionContent();
  }

  /// Generate Truth or Truth questions (Fallback)
  List<Map<String, dynamic>> _generateDefaultTruthOrTruthQuestions() {
    final questionSets = [
      // Set 1: Deep Connection
      [
        'What is one thing you wish I knew about you without having to tell me?',
        'When do you feel most loved by me?',
        'What is your favorite memory of us together?',
        'What is one thing you admire most about our relationship?',
        'How do you think we\'ve grown together as a couple?',
      ],
      // Set 2: Dreams & Future
      [
        'What is one dream you have for our future together?',
        'Where do you see us in 5 years?',
        'What is one adventure you want us to experience together?',
        'What tradition would you like us to start?',
        'What is one goal you want us to achieve as a couple?',
      ],
      // Set 3: Understanding Each Other
      [
        'What is one way I can better support you?',
        'What makes you feel most appreciated in our relationship?',
        'What is your love language and how can I speak it better?',
        'What is one thing that makes you feel closer to me?',
        'How do you prefer to resolve conflicts between us?',
      ],
      // Set 4: Fun & Playful
      [
        'What is the funniest moment we\'ve shared together?',
        'If we could go anywhere right now, where would you choose?',
        'What is one thing that always makes you smile about us?',
        'What song reminds you of our relationship?',
        'What is your favorite thing we do together?',
      ],
    ];

    // Randomly select a set
    final random = Random();
    final selectedSet = questionSets[random.nextInt(questionSets.length)];

    return selectedSet.asMap().entries.map((entry) {
      return {
        'id': 'q${entry.key + 1}',
        'question': entry.value,
        'category': 'connection',
        'difficulty': 'medium',
      };
    }).toList();
  }

  /// Generate Love Language questions (Fallback)
  List<Map<String, dynamic>> _generateDefaultLoveLanguageQuestions() {
    final questions = [
      {
        'id': 'q1',
        'question': 'I feel most loved when my partner...',
        'options': [
          {'text': 'Tells me they love me', 'language': 'words_of_affirmation'},
          {'text': 'Spends quality time with me', 'language': 'quality_time'},
          {'text': 'Gives me thoughtful gifts', 'language': 'receiving_gifts'},
          {'text': 'Does helpful things for me', 'language': 'acts_of_service'},
          {'text': 'Hugs and kisses me', 'language': 'physical_touch'},
        ],
      },
      {
        'id': 'q2',
        'question': 'What makes me feel most appreciated is...',
        'options': [
          {
            'text': 'Hearing compliments and praise',
            'language': 'words_of_affirmation',
          },
          {
            'text': 'Having their undivided attention',
            'language': 'quality_time',
          },
          {
            'text': 'Receiving surprise presents',
            'language': 'receiving_gifts',
          },
          {
            'text': 'Having them help with tasks',
            'language': 'acts_of_service',
          },
          {
            'text': 'Physical affection and closeness',
            'language': 'physical_touch',
          },
        ],
      },
      {
        'id': 'q3',
        'question': 'I feel most connected when we...',
        'options': [
          {
            'text': 'Have deep conversations',
            'language': 'words_of_affirmation',
          },
          {'text': 'Do activities together', 'language': 'quality_time'},
          {'text': 'Exchange meaningful gifts', 'language': 'receiving_gifts'},
          {'text': 'Work together on projects', 'language': 'acts_of_service'},
          {'text': 'Cuddle and hold hands', 'language': 'physical_touch'},
        ],
      },
      {
        'id': 'q4',
        'question': 'What hurts me most is when my partner...',
        'options': [
          {
            'text': 'Criticizes or insults me',
            'language': 'words_of_affirmation',
          },
          {'text': 'Is distracted or too busy', 'language': 'quality_time'},
          {'text': 'Forgets special occasions', 'language': 'receiving_gifts'},
          {
            'text': 'Doesn\'t help when I need it',
            'language': 'acts_of_service',
          },
          {'text': 'Avoids physical contact', 'language': 'physical_touch'},
        ],
      },
      {
        'id': 'q5',
        'question': 'I show love best by...',
        'options': [
          {
            'text': 'Expressing my feelings verbally',
            'language': 'words_of_affirmation',
          },
          {'text': 'Spending time together', 'language': 'quality_time'},
          {'text': 'Giving thoughtful gifts', 'language': 'receiving_gifts'},
          {'text': 'Doing things to help', 'language': 'acts_of_service'},
          {'text': 'Physical affection', 'language': 'physical_touch'},
        ],
      },
    ];

    return questions;
  }

  /// Generate Reflection questions (Fallback)
  List<Map<String, dynamic>> _generateDefaultReflectionQuestions() {
    final questionSets = [
      // Set 1: Gratitude & Appreciation
      [
        'What is one thing you\'re grateful for about our relationship today?',
        'What quality do you most appreciate in your partner?',
        'What is a recent moment that made you feel lucky to be together?',
        'How has your partner positively influenced your life?',
        'What is one way your partner makes your life better?',
        'What do you admire most about how your partner handles challenges?',
        'What is your favorite thing your partner does for you?',
        'How does your partner inspire you to be a better person?',
        'What is one thing your partner does that always makes you smile?',
        'What aspect of your relationship are you most proud of?',
      ],
      // Set 2: Growth & Future
      [
        'What is one area where you\'d like to grow as a couple?',
        'What is a goal you want to achieve together this year?',
        'How can you better support each other\'s personal growth?',
        'What new experience would you like to share together?',
        'What tradition would you like to create as a couple?',
        'How do you envision your relationship evolving?',
        'What skill would you like to learn together?',
        'What is one way you can strengthen your communication?',
        'What adventure do you want to embark on together?',
        'How can you make more quality time for each other?',
      ],
    ];

    final random = Random();
    final selectedSet = questionSets[random.nextInt(questionSets.length)];

    return selectedSet.asMap().entries.map((entry) {
      return {
        'id': 'q${entry.key + 1}',
        'question': entry.value,
        'category': 'reflection',
        'order': entry.key + 1,
      };
    }).toList();
  }

  /// Mark content as viewed by user
  Future<void> markContentViewed(String gameId, int version) async {
    try {
      if (_userId.isEmpty) return;

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('game_content_views')
          .doc(gameId)
          .set({
            'lastViewedVersion': version,
            'viewedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error marking content viewed: $e');
    }
  }

  /// Check if user has new content available
  Future<bool> hasNewContent(String gameId) async {
    try {
      if (_userId.isEmpty) return false;

      final currentVersion = await getCurrentVersion(gameId);

      final userDoc = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('game_content_views')
          .doc(gameId)
          .get();

      if (!userDoc.exists) return true;

      final lastViewedVersion = userDoc.data()?['lastViewedVersion'] ?? 0;
      return currentVersion > lastViewedVersion;
    } catch (e) {
      print('Error checking new content: $e');
      return false;
    }
  }

  /// Get content refresh schedule
  Map<String, dynamic> getRefreshSchedule() {
    return {
      'frequency': 'monthly',
      'nextRefresh': DateTime.now().add(const Duration(days: 30)),
      'games': [
        {
          'id': 'truth_or_truth',
          'name': 'Truth or Truth',
          'refreshEnabled': true,
        },
        {
          'id': 'love_language_quiz',
          'name': 'Love Language Quiz',
          'refreshEnabled': true,
        },
        {
          'id': 'reflection_game',
          'name': 'Reflection & Discussion',
          'refreshEnabled': true,
        },
      ],
    };
  }
}
