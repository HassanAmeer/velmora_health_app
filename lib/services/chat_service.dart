import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velmora/services/limit_service.dart';
import 'package:velmora/services/analytics_service.dart';
import 'package:velmora/services/notification_service.dart';
import 'package:velmora/services/rate_limit_service.dart';
import 'package:velmora/services/ai_service.dart';
import 'package:flutter/material.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LimitService _limitService = LimitService();
  final RateLimitService _rateLimitService = RateLimitService();
  final AnalyticsService _analyticsService = AnalyticsService();
  final NotificationService _notificationService = NotificationService();
  final AIService _aiService = AIService();

  String? get currentUserId => _auth.currentUser?.uid;

  /// Get chat messages stream
  Stream<QuerySnapshot> getChatMessages() {
    if (currentUserId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chatMessages')
        .orderBy('timestamp', descending: false)
        .limit(50)
        .snapshots();
  }

  /// Send a message
  Future<void> sendMessage(String message, {String? languageCode}) async {
    debugPrint(' ✉️ ChatService.sendMessage: languageCode=$languageCode');
    if (currentUserId == null || message.trim().isEmpty) return;

    try {
      // Check rate limit
      final rateLimitResult = await _rateLimitService.checkRateLimit(
        'ai_message',
      );
      if (!rateLimitResult.allowed) {
        throw rateLimitResult.reason ?? 'Rate limit exceeded';
      }

      // Check if user can send AI message (legacy limit service)
      final canSend = await _limitService.canSendAIMessage();
      if (!canSend) {
        throw 'Daily AI message limit reached. Upgrade to Premium for unlimited access!';
      }

      // Add user message
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chatMessages')
          .add({
            'message': message.trim(),
            'isUser': true,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // Log analytics
      await _analyticsService.logChatMessage(false, message.length);

      // Generate AI response
      await _generateAIResponse(message.trim(), languageCode: languageCode);

      // Record rate limit action
      await _rateLimitService.recordAction(
        'ai_message',
        metadata: {'messageLength': message.length},
      );

      // Increment message count (legacy)
      await _limitService.incrementAIMessageCount();

      // Check if limit reached after this message
      final isLimitReached = await _limitService.isLimitReached();
      if (isLimitReached) {
        await _notificationService.showAILimitReachedNotification();
        await _analyticsService.logAILimitReached();
      }
    } catch (e) {
      throw 'Failed to send message: $e';
    }
  }

  /// Generate AI response using Gemini AI via Firebase Cloud Functions
  Future<void> _generateAIResponse(String userMessage, {String? languageCode}) async {
    if (currentUserId == null) return;

    String aiResponse;

    String language = 'en';
    try {
      if (languageCode != null) {
        language = languageCode;
      } else {
        // Get user language for localization
        final userDoc = await _firestore.collection('users').doc(currentUserId).get();
        language = userDoc.data()?['preferredLanguage'] ?? 'en';
      }
      debugPrint(' 🤖 ChatService: Requesting AI response in $language');
      // Call real AI service
      aiResponse = await _aiService.generateResponse(userMessage, languageCode: language);
    } catch (e, st) {
      debugPrint(' 💥 AI service failed: $e, st:$st');

      // Localized error messages
      if (language == 'ar') {
        aiResponse = "معذرة، أواجه مشكلة في الاتصال بذكائي الاصطناعي الآن. يرجى الاتصال بالمسؤول.\n\nخطأ: $e";
      } else if (language == 'fr') {
        aiResponse = "Désolé, j'ai du mal à me connecter à mon cerveau IA en ce moment. Veuillez contacter l'administrateur.\n\nErreur: $e";
      } else {
        aiResponse = "I'm sorry, I'm having trouble connecting to my AI brain right now. Please contact to the Admin.\n\nError: $e";
      }
    }

    // Add AI response to Firestore
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chatMessages')
        .add({
          'message': aiResponse,
          'isUser': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
    debugPrint(' 💾 AI Response saved to Firestore successfully');

    // Notify user of AI interaction
    await _notificationService.addInAppNotification(
      title: 'New AI Insight',
      body: 'Your AI companion has replied to your recent message.',
      type: 'ai_chat',
    );

    // Log analytics
    await _analyticsService.logChatMessage(true, aiResponse.length);
  }

  /// Check if user can send message
  Future<bool> canSendMessage() async {
    return await _limitService.canSendAIMessage();
  }

  /// Get remaining messages
  Future<int> getRemainingMessages() async {
    return await _limitService.getRemainingAIMessages();
  }

  /// Get reset time
  String getResetTime() {
    return _limitService.getResetTimeFormatted();
  }

  /// Delete a single message
  Future<void> deleteMessage(String messageId) async {
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('chatMessages')
          .doc(messageId)
          .delete();
    } catch (e) {
      throw 'Failed to delete message: $e';
    }
  }
}
