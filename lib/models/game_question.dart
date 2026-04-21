class GameQuestion {
  final String id;
  final String question;
  final String? category;
  final String? optionA;
  final String? optionB;
  final String? description;
  final String? title;
  final String? budget;
  final String? prompt;
  final String? hint;
  final List<QuizOption>? options;

  // Translation fields
  final Map<String, String>? questionTranslations;
  final Map<String, String>? descriptionTranslations;
  final Map<String, String>? titleTranslations;
  final Map<String, String>? promptTranslations;
  final Map<String, String>? hintTranslations;
  final Map<String, String>? optionATranslations;
  final Map<String, String>? optionBTranslations;

  GameQuestion({
    required this.id,
    required this.question,
    this.category,
    this.optionA,
    this.optionB,
    this.description,
    this.title,
    this.budget,
    this.prompt,
    this.hint,
    this.options,
    this.questionTranslations,
    this.descriptionTranslations,
    this.titleTranslations,
    this.promptTranslations,
    this.hintTranslations,
    this.optionATranslations,
    this.optionBTranslations,
  });

  factory GameQuestion.fromJson(Map<String, dynamic> json, {String? id}) {
    // Determine the main text based on common keys
    String qText =
        json['question'] ??
        json['prompt'] ??
        json['title'] ??
        json['description'] ??
        '';

    // Map the most appropriate translations to questionTranslations
    Map<String, String>? qTranslations = json['question_translations'] != null
        ? Map<String, String>.from(json['question_translations'])
        : json['prompt_translations'] != null
        ? Map<String, String>.from(json['prompt_translations'])
        : json['title_translations'] != null
        ? Map<String, String>.from(json['title_translations'])
        : null;

    return GameQuestion(
      id: id ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      question: qText,
      category: json['category'] as String?,
      optionA: json['optionA'] as String?,
      optionB: json['optionB'] as String?,
      description: json['description'] as String?,
      title: json['title'] as String?,
      budget: json['budget'] as String?,
      prompt: json['prompt'] as String?,
      hint: json['hint'] as String?,
      options: json['options'] != null
          ? (json['options'] as List)
                .map((i) => QuizOption.fromJson(Map<String, dynamic>.from(i)))
                .toList()
          : null,
      questionTranslations: qTranslations,
      descriptionTranslations: json['description_translations'] != null
          ? Map<String, String>.from(json['description_translations'])
          : null,
      titleTranslations: json['title_translations'] != null
          ? Map<String, String>.from(json['title_translations'])
          : null,
      promptTranslations: json['prompt_translations'] != null
          ? Map<String, String>.from(json['prompt_translations'])
          : null,
      hintTranslations: json['hint_translations'] != null
          ? Map<String, String>.from(json['hint_translations'])
          : null,
      optionATranslations: json['optionA_translations'] != null
          ? Map<String, String>.from(json['optionA_translations'])
          : null,
      optionBTranslations: json['optionB_translations'] != null
          ? Map<String, String>.from(json['optionB_translations'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'category': category,
      'optionA': optionA,
      'optionB': optionB,
      'description': description,
      'title': title,
      'budget': budget,
      'prompt': prompt,
      'hint': hint,
      'options': options?.map((e) => e.toJson()).toList(),
      'question_translations': questionTranslations,
      'description_translations': descriptionTranslations,
      'title_translations': titleTranslations,
      'prompt_translations': promptTranslations,
      'hint_translations': hintTranslations,
      'optionA_translations': optionATranslations,
      'optionB_translations': optionBTranslations,
    };
  }

  /// Get localized content for a specific field and language
  String getLocalizedQuestion(String languageCode) {
    return questionTranslations?[languageCode] ?? question;
  }

  String? getLocalizedDescription(String languageCode) {
    return descriptionTranslations?[languageCode] ?? description;
  }

  String? getLocalizedTitle(String languageCode) {
    return titleTranslations?[languageCode] ?? title;
  }

  String? getLocalizedPrompt(String languageCode) {
    return promptTranslations?[languageCode] ?? prompt;
  }

  String? getLocalizedHint(String languageCode) {
    return hintTranslations?[languageCode] ?? hint;
  }

  String? getLocalizedOptionA(String languageCode) {
    return optionATranslations?[languageCode] ?? optionA;
  }

  String? getLocalizedOptionB(String languageCode) {
    return optionBTranslations?[languageCode] ?? optionB;
  }
}

class QuizOption {
  final String text;
  final bool isCorrect;
  final String? language;
  final Map<String, String>? textTranslations;

  QuizOption({
    required this.text,
    required this.isCorrect,
    this.language,
    this.textTranslations,
  });

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      text: json['text'] ?? json['language'] ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      language: json['language'] as String?,
      textTranslations: json['text_translations'] != null
          ? Map<String, String>.from(json['text_translations'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isCorrect': isCorrect,
      'language': language,
      'text_translations': textTranslations,
    };
  }

  String getLocalizedText(String languageCode) {
    return textTranslations?[languageCode] ?? text;
  }
}
