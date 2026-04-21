export type UploadMode = 'set' | 'merge' | 'add';

export interface TimestampLike {
    __type: 'Timestamp';
    seconds: number;
    nanoseconds: number;
}

export interface CollectionDocument {
    id?: string;
    data: Record<string, any>;
}

export interface CollectionSeedDefinition {
    path: string;
    uploadMode: UploadMode;
    documents: CollectionDocument[];
}

export interface SubcollectionSeedDefinition {
    path: string;
    uploadMode: UploadMode;
    documentsByUserId: Record<string, CollectionDocument[]>;
}

export interface MigrationDataDefinition {
    collections: {
        users: CollectionSeedDefinition;
        games: CollectionSeedDefinition;
        gameQuestions: CollectionSeedDefinition;
        userGameProgress: CollectionSeedDefinition;
        userGames: CollectionSeedDefinition;
        subscriptionPlans: CollectionSeedDefinition;
        faqs: CollectionSeedDefinition;
    };
    userSubcollections: {
        chatMessages: SubcollectionSeedDefinition;
        kegelDailyCompletions: SubcollectionSeedDefinition;
        kegelSessions: SubcollectionSeedDefinition;
        notifications: SubcollectionSeedDefinition;
    };
    singletonDocs: Array<{
        pathSegments: [string, string, ...string[]];
        data: Record<string, any>;
    }>;
}

const ts = (seconds: number): TimestampLike => ({
    __type: 'Timestamp',
    seconds,
    nanoseconds: 0,
});

export const migrationData: MigrationDataDefinition = {
    collections: {
        users: {
            path: 'users',
            uploadMode: 'merge',
            documents: [
                {
                    id: 'demo_user_001',
                    data: {
                        uid: 'demo_user_001',
                        email: 'john@example.com',
                        displayName: 'John Doe',
                        subscriptionStatus: 'premium',
                        subscriptionPlan: 'yearly',
                        preferredLanguage: 'en',
                        featuresAccess: { chat: true, games: true, kegel: true },
                        kegel: {
                            weekStreak: 7,
                            longestStreak: 14,
                            totalCompleted: 25,
                            totalMinutes: 125,
                            dailyGoalPercent: 85.7,
                            planProgress: 7,
                            dailyCompletionsToday: 1,
                        },
                        createdAt: ts(1709596800),
                        lastLoginAt: ts(1710115200),
                        updatedAt: ts(1710115200),
                    },
                },
                {
                    id: 'demo_user_002',
                    data: {
                        uid: 'demo_user_002',
                        email: 'jane@example.com',
                        displayName: 'Jane Smith',
                        subscriptionStatus: 'trial',
                        subscriptionPlan: 'monthly',
                        preferredLanguage: 'fr',
                        featuresAccess: { chat: true, games: true, kegel: true },
                        kegel: {
                            weekStreak: 3,
                            longestStreak: 8,
                            totalCompleted: 11,
                            totalMinutes: 55,
                            dailyGoalPercent: 60,
                            planProgress: 3,
                            dailyCompletionsToday: 0,
                        },
                        createdAt: ts(1709683200),
                        lastLoginAt: ts(1710115200),
                        updatedAt: ts(1710115200),
                    },
                },
                {
                    id: 'demo_user_003',
                    data: {
                        uid: 'demo_user_003',
                        email: 'ahmed@example.com',
                        displayName: 'Ahmed Ali',
                        subscriptionStatus: 'free',
                        preferredLanguage: 'ar',
                        featuresAccess: { chat: true, games: true, kegel: true },
                        kegel: {
                            weekStreak: 1,
                            longestStreak: 2,
                            totalCompleted: 4,
                            totalMinutes: 20,
                            dailyGoalPercent: 30,
                            planProgress: 1,
                            dailyCompletionsToday: 0,
                        },
                        createdAt: ts(1709769600),
                        lastLoginAt: ts(1710115200),
                        updatedAt: ts(1710115200),
                    },
                },
            ],
        },
        games: {
            path: 'games',
            uploadMode: 'set',
            documents: [
                {
                    id: 'truth_or_truth',
                    data: {
                        id: 'truth_or_truth',
                        title: 'Truth or Truth',
                        description: 'Answer truthful questions about each other to deepen your connection.',
                        isPremium: false,
                        isActive: true,
                        order: 1,
                        updatedAt: ts(1710115200),
                    },
                },
                {
                    id: 'love_language_quiz',
                    data: {
                        id: 'love_language_quiz',
                        title: 'Love Language Quiz',
                        description: "Discover your and your partner's primary love language.",
                        isPremium: true,
                        isActive: true,
                        order: 2,
                        updatedAt: ts(1710115200),
                    },
                },
                {
                    id: 'would_you_rather',
                    data: {
                        id: 'would_you_rather',
                        title: 'Would You Rather',
                        description: 'Fun dilemmas that reveal how you both think and prioritise.',
                        isPremium: true,
                        isActive: true,
                        order: 3,
                        updatedAt: ts(1710115200),
                    },
                },
                {
                    id: 'memory_lane',
                    data: {
                        id: 'memory_lane',
                        title: 'Memory Lane',
                        description: 'Reminisce about your favourite shared memories together.',
                        isPremium: true,
                        isActive: true,
                        order: 4,
                        updatedAt: ts(1710115200),
                    },
                },
                {
                    id: 'future_planning',
                    data: {
                        id: 'future_planning',
                        title: 'Future Planning',
                        description: 'Plan your dreams and future goals as a couple.',
                        isPremium: true,
                        isActive: true,
                        order: 5,
                        updatedAt: ts(1710115200),
                    },
                },
            ],
        },
        gameQuestions: {
            path: 'game_questions',
            uploadMode: 'set',
            documents: [
                { id: 'tot_q1', data: { gameType: 'truth_or_truth', question: 'What is your happiest memory of us together?', order: 1 } },
                { id: 'tot_q2', data: { gameType: 'truth_or_truth', question: 'What first attracted you to me?', order: 2 } },
                { id: 'tot_q3', data: { gameType: 'truth_or_truth', question: 'What is one thing I do that always makes you smile?', order: 3 } },
                { id: 'll_q1', data: { gameType: 'love_language_quiz', question: 'When your partner is kind to you verbally, how does it make you feel?', order: 1 } },
                { id: 'll_q2', data: { gameType: 'love_language_quiz', question: 'How important is it to you that your partner spends undivided time with you?', order: 2 } },
                { id: 'wyr_q1', data: { gameType: 'would_you_rather', question: 'Would you rather have a spontaneous adventure or a carefully planned romantic getaway?', order: 1 } },
                { id: 'ml_q1', data: { gameType: 'memory_lane', question: 'What is your favorite memory of our first year together?', order: 1 } },
                { id: 'fp_q1', data: { gameType: 'future_planning', question: 'Where do you see us in 5 years?', order: 1 } },
            ],
        },
        userGameProgress: {
            path: 'user_game_progress',
            uploadMode: 'set',
            documents: [
                {
                    id: 'demo_user_001',
                    data: {
                        userId: 'demo_user_001',
                        playedGames: ['truth_or_truth', 'love_language_quiz'],
                        totalScore: 150,
                        createdAt: ts(1709596800),
                        updatedAt: ts(1709856000),
                    },
                },
                {
                    id: 'demo_user_002',
                    data: {
                        userId: 'demo_user_002',
                        playedGames: ['truth_or_truth'],
                        totalScore: 60,
                        createdAt: ts(1709683200),
                        updatedAt: ts(1709942400),
                    },
                },
                {
                    id: 'demo_user_003',
                    data: {
                        userId: 'demo_user_003',
                        playedGames: [],
                        totalScore: 0,
                        createdAt: ts(1709769600),
                        updatedAt: ts(1709769600),
                    },
                },
            ],
        },
        userGames: {
            path: 'user_games',
            uploadMode: 'add',
            documents: [
                { data: { userId: 'demo_user_001', gameId: 'truth_or_truth', gameTitle: 'Truth or Truth', questionsAnswered: 10, totalQuestions: 20, isCompleted: false, startedAt: ts(1709683200), completedAt: null } },
                { data: { userId: 'demo_user_001', gameId: 'love_language_quiz', gameTitle: 'Love Language Quiz', questionsAnswered: 5, totalQuestions: 5, isCompleted: true, startedAt: ts(1709856000), completedAt: ts(1709856600) } },
                { data: { userId: 'demo_user_002', gameId: 'truth_or_truth', gameTitle: 'Truth or Truth', questionsAnswered: 6, totalQuestions: 20, isCompleted: false, startedAt: ts(1709942400), completedAt: null } },
            ],
        },
        subscriptionPlans: {
            path: 'subscription_plans',
            uploadMode: 'set',
            documents: [
                {
                    id: 'monthly',
                    data: {
                        name: 'Monthly Plan',
                        productId: 'velmora_premium_monthly',
                        durationMonths: 1,
                        pricePerMonth: 4.99,
                        totalPrice: 4.99,
                        currency: 'USD',
                        badge: '',
                        badgeColor: '',
                        savingsText: '',
                        features: ['Full AI Chat', 'All Games', 'Kegel Exercises', 'Priority Support'],
                        isActive: true,
                        isPopular: false,
                        sortOrder: 1,
                        createdAt: ts(1710115200),
                        updatedAt: ts(1710115200),
                    },
                },
                {
                    id: 'quarterly',
                    data: {
                        name: '3-Month Plan',
                        productId: 'velmora_premium_quarterly',
                        durationMonths: 3,
                        pricePerMonth: 3.33,
                        totalPrice: 9.99,
                        currency: 'USD',
                        badge: 'SAVE 33%',
                        badgeColor: '#FF8A00',
                        savingsText: 'Save 33% compared to monthly',
                        features: ['Full AI Chat', 'All Games', 'Kegel Exercises', 'Priority Support', 'Exclusive Content'],
                        isActive: true,
                        isPopular: false,
                        sortOrder: 2,
                        createdAt: ts(1710115200),
                        updatedAt: ts(1710115200),
                    },
                },
                {
                    id: 'yearly',
                    data: {
                        name: 'Yearly Plan',
                        productId: 'velmora_premium_yearly',
                        durationMonths: 12,
                        pricePerMonth: 2.5,
                        totalPrice: 29.99,
                        currency: 'USD',
                        badge: 'BEST VALUE',
                        badgeColor: '#FF8A00',
                        savingsText: 'Save 50% compared to monthly',
                        features: ['Full AI Chat', 'All Games', 'Kegel Exercises', 'Priority Support', 'Exclusive Content', 'Early Access'],
                        isActive: true,
                        isPopular: true,
                        sortOrder: 3,
                        createdAt: ts(1710115200),
                        updatedAt: ts(1710115200),
                    },
                },
            ],
        },
        faqs: {
            path: 'admin/faqs/items',
            uploadMode: 'set',
            documents: [
                { id: 'faq_1', data: { question: 'How does the free trial work?', answer: 'You get limited AI chat and basic feature access during trial.', order: 1 } },
                { id: 'faq_2', data: { question: 'How can I cancel my subscription?', answer: 'You can cancel from your app store subscription settings any time.', order: 2 } },
                { id: 'faq_3', data: { question: 'Is my data private?', answer: 'Yes. We use secure storage and only process data required for app functionality.', order: 3 } },
            ],
        },
    },
    userSubcollections: {
        chatMessages: {
            path: 'chatMessages',
            uploadMode: 'set',
            documentsByUserId: {
                demo_user_001: [
                    { id: 'msg_001', data: { message: "Hello! I'm Velmora AI, your relationship wellness assistant. How can I help you today?", isUser: false, timestamp: ts(1709596800) } },
                    { id: 'msg_002', data: { message: 'What games do you have for couples?', isUser: true, timestamp: ts(1709683200) } },
                ],
                demo_user_002: [
                    { id: 'msg_001', data: { message: 'Welcome to Velmora AI! Ready for your first session?', isUser: false, timestamp: ts(1709683200) } },
                ],
                demo_user_003: [
                    { id: 'msg_001', data: { message: 'Hi! Tell me about Kegel routines.', isUser: true, timestamp: ts(1709769600) } },
                    { id: 'msg_002', data: { message: 'Start with beginner routine: 5 minutes daily for one week.', isUser: false, timestamp: ts(1709769900) } },
                ],
            },
        },
        kegelDailyCompletions: {
            path: 'kegel_daily_completions',
            uploadMode: 'set',
            documentsByUserId: {
                demo_user_001: [
                    { id: '2026-03-05', data: { date: '2026-03-05', completions: 1, lastUpdated: ts(1709942400) } },
                    { id: '2026-03-06', data: { date: '2026-03-06', completions: 1, lastUpdated: ts(1710028800) } },
                    { id: '2026-03-07', data: { date: '2026-03-07', completions: 1, lastUpdated: ts(1710115200) } },
                ],
                demo_user_002: [
                    { id: '2026-03-07', data: { date: '2026-03-07', completions: 1, lastUpdated: ts(1710115200) } },
                ],
                demo_user_003: [],
            },
        },
        kegelSessions: {
            path: 'kegel_sessions',
            uploadMode: 'add',
            documentsByUserId: {
                demo_user_001: [
                    { data: { routineType: 'Intermediate Routine', durationMinutes: 8, setsCompleted: 4, completedAt: ts(1710028800), date: '2026-03-06' } },
                    { data: { routineType: 'Intermediate Routine', durationMinutes: 8, setsCompleted: 4, completedAt: ts(1710115200), date: '2026-03-07' } },
                ],
                demo_user_002: [
                    { data: { routineType: 'Beginner Routine', durationMinutes: 5, setsCompleted: 3, completedAt: ts(1710115200), date: '2026-03-07' } },
                ],
                demo_user_003: [
                    { data: { routineType: 'Beginner Routine', durationMinutes: 5, setsCompleted: 3, completedAt: ts(1709769600), date: '2026-03-05' } },
                ],
            },
        },
        notifications: {
            path: 'notifications',
            uploadMode: 'add',
            documentsByUserId: {
                demo_user_001: [
                    { data: { title: 'Premium Subscription Activated', body: 'Thank you for upgrading!', type: 'subscription', isRead: true, timestamp: ts(1709942400) } },
                ],
                demo_user_002: [
                    { data: { title: 'Welcome to Velmora AI!', body: "We're glad you're here.", type: 'system', isRead: false, timestamp: ts(1709683200) } },
                ],
                demo_user_003: [
                    { data: { title: 'First Kegel Routine Complete', body: 'Great consistency—keep it up!', type: 'kegel', isRead: false, timestamp: ts(1709769600) } },
                ],
            },
        },
    },
    singletonDocs: [
        {
            pathSegments: ['ai_config', 'settings'],
            data: {
                enabled: true,
                apiKey: 'PLACEHOLDER_KEY',
                maxTokens: 500,
                model: 'gemini-2.5-flash',
                safetySettings: {
                    dangerousContent: 'BLOCK_MEDIUM_AND_ABOVE',
                    harassment: 'BLOCK_MEDIUM_AND_ABOVE',
                    hateSpeech: 'BLOCK_MEDIUM_AND_ABOVE',
                    sexuallyExplicit: 'BLOCK_MEDIUM_AND_ABOVE',
                },
                systemInstruction: 'You are Velmora AI, a helpful relationship coach.',
                temperature: 0.7,
                topK: 40,
                topP: 0.95,
                updatedAt: ts(1710115200),
            },
        },
        {
            pathSegments: ['admin_settings', 'general'],
            data: {
                supportEmail: 'support@velmora.com',
                updatedAt: ts(1710115200),
            },
        },
        {
            pathSegments: ['admin', 'credentials'],
            data: {
                adminEmail: 'admin@gmail.com',
                adminPassword: '12345678',
                updatedAt: ts(1710115200),
            },
        },
        {
            pathSegments: ['admin', 'legal_docs', 'items', 'terms_of_service'],
            data: {
                sections: [
                    { title: 'Agreement to Terms', content: 'By accessing or using Velmora AI, you agree to these Terms of Service.' },
                    { title: 'Use of Service', content: 'You may use the app for lawful personal wellness purposes only.' },
                ],
                lastUpdated: 'March 9, 2026',
                updatedAt: ts(1710115200),
            },
        },
        {
            pathSegments: ['admin', 'legal_docs', 'items', 'privacy_policy'],
            data: {
                sections: [
                    { title: 'Introduction', content: 'Velmora AI is committed to protecting your privacy.' },
                    { title: 'Data Usage', content: 'We process your data to provide personalized wellness features.' },
                ],
                lastUpdated: 'March 9, 2026',
                updatedAt: ts(1710115200),
            },
        },
    ],
};
