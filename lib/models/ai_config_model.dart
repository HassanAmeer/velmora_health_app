import 'package:cloud_firestore/cloud_firestore.dart';

/// AI Configuration model stored in Firestore
///
/// Document path: ai_config/settings
///
/// This model holds all AI-related settings that can be managed
/// from the admin panel without requiring app updates.
class AIConfigModel {
  // API Configuration
  final String? apiKey;
  final bool enabled;
  final String model;

  // Generation Config
  final int maxTokens;
  final double temperature;
  final int topK;
  final double topP;

  // Safety Settings
  final String sexuallyExplicit;
  final String hateSpeech;
  final String harassment;
  final String dangerousContent;

  // System Instructions
  final String systemInstruction;

  // Metadata
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AIConfigModel({
    this.apiKey,
    this.enabled = true,
    this.model = 'gemini-2.5-flash',
    this.maxTokens = 500,
    this.temperature = 0.7,
    this.topK = 40,
    this.topP = 0.95,
    this.sexuallyExplicit = 'BLOCK_ONLY_HIGH',
    this.hateSpeech = 'BLOCK_MEDIUM_AND_ABOVE',
    this.harassment = 'BLOCK_MEDIUM_AND_ABOVE',
    this.dangerousContent = 'BLOCK_MEDIUM_AND_ABOVE',
    this.systemInstruction = '',
    this.createdAt,
    this.updatedAt,
  });

  factory AIConfigModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AIConfigModel(
      apiKey: data['apiKey'] as String?,
      enabled: data['enabled'] as bool? ?? true,
      model: data['model'] as String? ?? 'gemini-2.5-flash',
      maxTokens: data['maxTokens'] as int? ?? 500,
      temperature: (data['temperature'] as num?)?.toDouble() ?? 0.7,
      topK: data['topK'] as int? ?? 40,
      topP: (data['topP'] as num?)?.toDouble() ?? 0.95,
      systemInstruction: data['systemInstruction'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      // Safety settings
      sexuallyExplicit: (data['safetySettings'] as Map<String, dynamic>?)?['sexuallyExplicit'] as String? ?? 'BLOCK_ONLY_HIGH',
      hateSpeech: (data['safetySettings'] as Map<String, dynamic>?)?['hateSpeech'] as String? ?? 'BLOCK_MEDIUM_AND_ABOVE',
      harassment: (data['safetySettings'] as Map<String, dynamic>?)?['harassment'] as String? ?? 'BLOCK_MEDIUM_AND_ABOVE',
      dangerousContent: (data['safetySettings'] as Map<String, dynamic>?)?['dangerousContent'] as String? ?? 'BLOCK_MEDIUM_AND_ABOVE',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'apiKey': apiKey,
      'enabled': enabled,
      'model': model,
      'maxTokens': maxTokens,
      'temperature': temperature,
      'topK': topK,
      'topP': topP,
      'systemInstruction': systemInstruction,
      'safetySettings': {
        'sexuallyExplicit': sexuallyExplicit,
        'hateSpeech': hateSpeech,
        'harassment': harassment,
        'dangerousContent': dangerousContent,
      },
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AIConfigModel copyWith({
    String? apiKey,
    bool? enabled,
    String? model,
    int? maxTokens,
    double? temperature,
    int? topK,
    double? topP,
    String? sexuallyExplicit,
    String? hateSpeech,
    String? harassment,
    String? dangerousContent,
    String? systemInstruction,
  }) {
    return AIConfigModel(
      apiKey: apiKey ?? this.apiKey,
      enabled: enabled ?? this.enabled,
      model: model ?? this.model,
      maxTokens: maxTokens ?? this.maxTokens,
      temperature: temperature ?? this.temperature,
      topK: topK ?? this.topK,
      topP: topP ?? this.topP,
      sexuallyExplicit: sexuallyExplicit ?? this.sexuallyExplicit,
      hateSpeech: hateSpeech ?? this.hateSpeech,
      harassment: harassment ?? this.harassment,
      dangerousContent: dangerousContent ?? this.dangerousContent,
      systemInstruction: systemInstruction ?? this.systemInstruction,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Get API URL based on model
  String getApiUrl() {
    return 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
  }

  /// Get safety settings map for API call
  Map<String, String> getSafetySettingsMap() {
    return {
      'HARM_CATEGORY_SEXUALLY_EXPLICIT': sexuallyExplicit,
      'HARM_CATEGORY_HATE_SPEECH': hateSpeech,
      'HARM_CATEGORY_HARASSMENT': harassment,
      'HARM_CATEGORY_DANGEROUS_CONTENT': dangerousContent,
    };
  }

  /// Check if API key is configured
  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  /// Default system instruction for Velmora AI
  static String getDefaultSystemInstruction() {
    return '''You are Velmora AI, a professional relationship coach and companion for the Velmora AI app.

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
- Free Trial: 3 messages/day, 24-hour lockout, games locked''';
  }
}

/// Message Limits model stored in Firestore
///
/// Document path: app_settings/message_limits
///
/// Controls daily message limits for different subscription tiers.
class MessageLimitsModel {
  final int freeDailyLimit;
  final int premiumDailyLimit; // -1 for unlimited
  final bool enableDailyReset;
  final int resetHour; // Hour of day for reset (0-23)

  // Rate limiting
  final int messagesPerMinute;
  final int messagesPerHour;

  // Feature flags
  final bool aiEnabled;
  final bool gamesEnabled;
  final bool kegelEnabled;

  MessageLimitsModel({
    this.freeDailyLimit = 3,
    this.premiumDailyLimit = -1,
    this.enableDailyReset = true,
    this.resetHour = 0,
    this.messagesPerMinute = 10,
    this.messagesPerHour = 100,
    this.aiEnabled = true,
    this.gamesEnabled = true,
    this.kegelEnabled = true,
  });

  factory MessageLimitsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MessageLimitsModel(
      freeDailyLimit: data['freeDailyLimit'] as int? ?? 3,
      premiumDailyLimit: data['premiumDailyLimit'] as int? ?? -1,
      enableDailyReset: data['enableDailyReset'] as bool? ?? true,
      resetHour: data['resetHour'] as int? ?? 0,
      messagesPerMinute: data['messagesPerMinute'] as int? ?? 10,
      messagesPerHour: data['messagesPerHour'] as int? ?? 100,
      aiEnabled: data['aiEnabled'] as bool? ?? true,
      gamesEnabled: data['gamesEnabled'] as bool? ?? true,
      kegelEnabled: data['kegelEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'freeDailyLimit': freeDailyLimit,
      'premiumDailyLimit': premiumDailyLimit,
      'enableDailyReset': enableDailyReset,
      'resetHour': resetHour,
      'messagesPerMinute': messagesPerMinute,
      'messagesPerHour': messagesPerHour,
      'aiEnabled': aiEnabled,
      'gamesEnabled': gamesEnabled,
      'kegelEnabled': kegelEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  MessageLimitsModel copyWith({
    int? freeDailyLimit,
    int? premiumDailyLimit,
    bool? enableDailyReset,
    int? resetHour,
    int? messagesPerMinute,
    int? messagesPerHour,
    bool? aiEnabled,
    bool? gamesEnabled,
    bool? kegelEnabled,
  }) {
    return MessageLimitsModel(
      freeDailyLimit: freeDailyLimit ?? this.freeDailyLimit,
      premiumDailyLimit: premiumDailyLimit ?? this.premiumDailyLimit,
      enableDailyReset: enableDailyReset ?? this.enableDailyReset,
      resetHour: resetHour ?? this.resetHour,
      messagesPerMinute: messagesPerMinute ?? this.messagesPerMinute,
      messagesPerHour: messagesPerHour ?? this.messagesPerHour,
      aiEnabled: aiEnabled ?? this.aiEnabled,
      gamesEnabled: gamesEnabled ?? this.gamesEnabled,
      kegelEnabled: kegelEnabled ?? this.kegelEnabled,
    );
  }

  /// Check if user has unlimited messages
  bool hasUnlimitedMessages(bool isPremium) {
    if (isPremium) {
      return premiumDailyLimit == -1;
    }
    return false;
  }

  /// Get daily limit for user
  int getDailyLimit(bool isPremium) {
    if (isPremium) {
      return premiumDailyLimit == -1 ? 999999 : premiumDailyLimit;
    }
    return freeDailyLimit;
  }
}
