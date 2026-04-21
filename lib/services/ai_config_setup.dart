import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// One-time setup script to initialize AI configuration in Firestore
///
/// Run this once to set up the AI config document
class AIConfigSetup {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize AI configuration in Firestore
  static Future<void> setupAIConfig({
    required String apiKey,
    bool enabled = true,
    String model = 'gemini-2.5-flash',
  }) async {
    try {
      debugPrint('Setting up AI configuration in Firestore...');

      await _firestore.collection('ai_config').doc('settings').set({
        'apiKey': apiKey,
        'enabled': enabled,
        'model': model,
        'maxTokens': 500,
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'systemInstruction':
            '''You are Velmora AI, a professional relationship coach and companion for the Velmora AI app.

ABOUT VELMORA AI APP:
1. COUPLES GAMES (3 Interactive Games):
   - Truth or Truth: Deep questions (15 min, 2 players)
   - Love Language Quiz: Discover love languages (10 min, 2 players)
   - Reflection & Discussion: Meaningful reflections (20 min, 2 players)
   - Games LOCKED in free trial - require subscription
   - Content refreshed monthly

2. KEGEL EXERCISES:
   - Beginner: 5 min, 3 sets
   - Intermediate: 10 min, 5 sets
   - Advanced: 15 min, 7 sets
   - Progress tracking, 30-Day Challenge
   - Benefits: Pelvic floor strength, intimate wellness

3. AI CHAT (You):
   - Free trial: 3 messages/day
   - After limit: 24-hour lockout OR upgrade
   - Premium: Unlimited conversations

4. SUBSCRIPTION:
   - Monthly: \$3.99
   - Quarterly: \$9.99
   - Yearly: \$29.99
   - Premium unlocks: Unlimited AI + all games

5. LANGUAGES: Arabic, English, French

GUIDELINES:
- Be warm, empathetic, non-judgmental
- Educational, respectful advice
- Concise responses (2-4 sentences)
- Suggest professional help for serious issues

WHEN ASKED ABOUT:
- Games: Explain 3 games, mention subscription needed
- Kegel: Explain benefits, 3 levels, tracking
- Subscription: Mention pricing, premium benefits
- Free Trial: 3 messages/day, games locked''',
        'safetySettings': {
          'sexuallyExplicit': 'BLOCK_ONLY_HIGH',
          'hateSpeech': 'BLOCK_MEDIUM_AND_ABOVE',
          'harassment': 'BLOCK_MEDIUM_AND_ABOVE',
          'dangerousContent': 'BLOCK_MEDIUM_AND_ABOVE',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ AI configuration setup complete!');
      debugPrint('AI is now enabled and ready to use.');
    } catch (e) {
      debugPrint('❌ Error setting up AI config: $e');
      rethrow;
    }
  }

  /// Check if AI config exists
  static Future<bool> configExists() async {
    try {
      final doc = await _firestore
          .collection('ai_config')
          .doc('settings')
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking AI config: $e');
      return false;
    }
  }

  /// Update API key
  static Future<void> updateApiKey(String newApiKey) async {
    try {
      await _firestore.collection('ai_config').doc('settings').update({
        'apiKey': newApiKey,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ API key updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating API key: $e');
      rethrow;
    }
  }

  /// Enable/disable AI
  static Future<void> toggleAI(bool enabled) async {
    try {
      await _firestore.collection('ai_config').doc('settings').update({
        'enabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ AI ${enabled ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('❌ Error toggling AI: $e');
      rethrow;
    }
  }

  /// Get current AI config
  static Future<Map<String, dynamic>?> getConfig() async {
    try {
      final doc = await _firestore
          .collection('ai_config')
          .doc('settings')
          .get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting AI config: $e');
      return null;
    }
  }

  /// Setup Firestore security rules (display only - must be set in Firebase Console)
  static String getSecurityRules() {
    return '''
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // AI Configuration - Read only for authenticated users
    match /ai_config/{document} {
      allow read: if request.auth != null;
      allow write: if false; // Only admins via Firebase Console
    }

    // User documents
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      // Chat messages
      match /chatMessages/{messageId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }

    // Games - read only
    match /games/{gameId} {
      allow read: if request.auth != null;
      allow write: if false;
    }
  }
}
''';
  }
}
