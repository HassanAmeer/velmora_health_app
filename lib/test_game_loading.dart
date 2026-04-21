import 'package:flutter/material.dart';
import 'package:velmora/services/game_questions_service.dart';

/// Test script to verify game question loading
/// Run this to diagnose issues with game data loading
class GameLoadingTest {
  static Future<void> runTests() async {
    print('\n========================================');
    print('🧪 GAME LOADING TEST SUITE');
    print('========================================\n');

    final service = GameQuestionsService();
    final gameIds = [
      'truth_or_truth',
      'love_language_quiz',
      'reflection_game',
      'couples_challenge',
      'would_you_rather',
      'date_night_ideas',
      'relationship_quiz',
      'compliment_game',
    ];

    int passed = 0;
    int failed = 0;

    for (final gameId in gameIds) {
      print('📋 Testing: $gameId');
      print('─────────────────────────────────────');

      try {
        // Test 1: Load questions
        final questions = await service.getQuestions(gameId);

        if (questions.isEmpty) {
          print('❌ FAIL: No questions loaded');
          failed++;
          continue;
        }

        print('✅ Loaded ${questions.length} questions');

        // Test 2: Validate question structure
        bool hasErrors = false;
        for (int i = 0; i < questions.length; i++) {
          final q = questions[i];

          // Check question text
          if (q.question.isEmpty) {
            print('❌ Question $i: Empty question text');
            hasErrors = true;
          }

          // Check for love language quiz specific requirements
          if (gameId == 'love_language_quiz') {
            if (q.options == null || q.options!.isEmpty) {
              print('❌ Question $i: Missing options for love language quiz');
              hasErrors = true;
            } else {
              // Validate options have language field
              for (int j = 0; j < q.options!.length; j++) {
                final opt = q.options![j];
                if (opt.language == null || opt.language!.isEmpty) {
                  print('❌ Question $i, Option $j: Missing language field');
                  hasErrors = true;
                }
                if (opt.text.isEmpty) {
                  print('❌ Question $i, Option $j: Empty text');
                  hasErrors = true;
                }
              }
            }
          }

          // Check for relationship quiz specific requirements
          if (gameId == 'relationship_quiz') {
            if (q.options == null || q.options!.isEmpty) {
              print('❌ Question $i: Missing options for relationship quiz');
              hasErrors = true;
            }
          }

          // Check for would you rather specific requirements
          if (gameId == 'would_you_rather') {
            if ((q.optionA == null || q.optionA!.isEmpty) ||
                (q.optionB == null || q.optionB!.isEmpty)) {
              print('❌ Question $i: Missing optionA or optionB');
              hasErrors = true;
            }
          }

          // Check for date night ideas specific requirements
          if (gameId == 'date_night_ideas') {
            if (q.title == null || q.title!.isEmpty) {
              print('❌ Question $i: Missing title for date night idea');
              hasErrors = true;
            }
            if (q.description == null || q.description!.isEmpty) {
              print('❌ Question $i: Missing description');
              hasErrors = true;
            }
          }

          // Check for compliment game specific requirements
          if (gameId == 'compliment_game') {
            if (q.prompt == null || q.prompt!.isEmpty) {
              print('❌ Question $i: Missing prompt for compliment game');
              hasErrors = true;
            }
          }
        }

        if (hasErrors) {
          print('❌ FAIL: Validation errors found');
          failed++;
        } else {
          print('✅ PASS: All validations passed');
          passed++;
        }
      } catch (e, stackTrace) {
        print('❌ FAIL: Exception thrown: $e');
        print('Stack trace: $stackTrace');
        failed++;
      }

      print('');
    }

    print('========================================');
    print('📊 TEST RESULTS');
    print('========================================');
    print('✅ Passed: $passed');
    print('❌ Failed: $failed');
    print('📈 Total: ${passed + failed}');
    print('========================================\n');

    if (failed > 0) {
      print('⚠️  Some tests failed. Please review the errors above.');
    } else {
      print('🎉 All tests passed! Game loading is working correctly.');
    }
  }

  /// Test a specific game in isolation
  static Future<void> testSingleGame(String gameId) async {
    print('\n========================================');
    print('🧪 TESTING SINGLE GAME: $gameId');
    print('========================================\n');

    final service = GameQuestionsService();

    try {
      print('📋 Loading questions...');
      final questions = await service.getQuestions(gameId);

      print('✅ Loaded ${questions.length} questions\n');

      for (int i = 0; i < questions.length; i++) {
        final q = questions[i];
        print('Question ${i + 1}:');
        print('  Text: ${q.question}');
        print('  Category: ${q.category ?? "N/A"}');

        if (q.options != null && q.options!.isNotEmpty) {
          print('  Options (${q.options!.length}):');
          for (int j = 0; j < q.options!.length; j++) {
            final opt = q.options![j];
            print(
              '    ${j + 1}. ${opt.text} (language: ${opt.language ?? "N/A"})',
            );
          }
        }

        if (q.optionA != null) {
          print('  Option A: ${q.optionA}');
        }
        if (q.optionB != null) {
          print('  Option B: ${q.optionB}');
        }

        if (q.title != null) {
          print('  Title: ${q.title}');
        }
        if (q.description != null) {
          print('  Description: ${q.description}');
        }

        if (q.prompt != null) {
          print('  Prompt: ${q.prompt}');
        }
        if (q.hint != null) {
          print('  Hint: ${q.hint}');
        }

        print('');
      }

      print('✅ Test completed successfully');
    } catch (e, stackTrace) {
      print('❌ Test failed with error: $e');
      print('Stack trace: $stackTrace');
    }

    print('========================================\n');
  }
}

/// Widget to run tests from the app
class GameLoadingTestScreen extends StatefulWidget {
  const GameLoadingTestScreen({super.key});

  @override
  State<GameLoadingTestScreen> createState() => _GameLoadingTestScreenState();
}

class _GameLoadingTestScreenState extends State<GameLoadingTestScreen> {
  bool _isRunning = false;
  String _output = 'Press "Run Tests" to start';

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _output = 'Running tests...\n';
    });

    await GameLoadingTest.runTests();

    setState(() {
      _isRunning = false;
      _output = 'Tests completed. Check console for results.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Loading Test'),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Game Loading Diagnostic Tool',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This tool tests if game questions are loading correctly from Firebase and local storage.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isRunning ? null : _runTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isRunning
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Run Tests',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _output,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
