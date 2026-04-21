import {
    collection,
    doc,
    getDocs,
    setDoc,
    updateDoc,
    deleteDoc,
    serverTimestamp,
    query,
    orderBy
} from 'firebase/firestore';
import { db } from './firebase';

export interface SubscriptionPlan {
    id: string;
    name: string;
    productId: string;
    durationMonths: number;
    pricePerMonth: number;
    totalPrice: number;
    currency: string;
    badge?: string;
    badgeColor?: string;
    savingsText?: string;
    bottomNote?: string;
    features: string[];
    isActive: boolean;
    isPopular: boolean;
    sortOrder: number;
    name_translations?: Record<string, string>;
    badge_translations?: Record<string, string>;
    savings_translations?: Record<string, string>;
    bottomNote_translations?: Record<string, string>;
    features_translations?: Record<string, string[]>;
    createdAt?: any;
    updatedAt?: any;
}

const COLLECTION = 'subscription_plans';

export const subscriptionPlanService = {
    getPlans: async (): Promise<SubscriptionPlan[]> => {
        const q = query(collection(db, COLLECTION), orderBy('sortOrder', 'asc'));
        const snapshot = await getDocs(q);
        return snapshot.docs.map(d => ({ id: d.id, ...d.data() } as SubscriptionPlan));
    },

    createPlan: async (plan: Omit<SubscriptionPlan, 'id' | 'createdAt' | 'updatedAt'>): Promise<string> => {
        const ref = doc(collection(db, COLLECTION));
        await setDoc(ref, {
            ...plan,
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp()
        });
        return ref.id;
    },

    updatePlan: async (id: string, plan: Partial<SubscriptionPlan>): Promise<void> => {
        await updateDoc(doc(db, COLLECTION, id), {
            ...plan,
            updatedAt: serverTimestamp()
        });
    },

    deletePlan: async (id: string): Promise<void> => {
        await deleteDoc(doc(db, COLLECTION, id));
    },

    seedDefaultPlans: async (): Promise<void> => {
        const defaults: Omit<SubscriptionPlan, 'id'>[] = [
            {
                name: 'Monthly Plan',
                name_translations: {
                    en: 'Monthly Plan',
                    ar: 'الخطة الشهرية',
                    fr: 'Forfait mensuel'
                },
                productId: 'velmora_premium_monthly',
                durationMonths: 1,
                pricePerMonth: 4.99,
                totalPrice: 4.99,
                currency: 'USD',
                badge: '',
                badgeColor: '',
                savingsText: '',
                bottomNote: 'Free for 48 hours, then $4.99/month. Cancel anytime.',
                bottomNote_translations: {
                    en: 'Free for 48 hours, then $4.99/month. Cancel anytime.',
                    ar: 'مجانًا لمدة 48 ساعة، ثم 4.99 دولارًا شهريًا. يمكنك الإلغاء في أي وقت.',
                    fr: 'Gratuit pendant 48 heures, puis 4,99 $/mois. Annulez à tout moment.'
                },
                features: [],
                isActive: true,
                isPopular: false,
                sortOrder: 1,
                createdAt: serverTimestamp(),
                updatedAt: serverTimestamp()
            },
            {
                name: '3-Month Plan',
                name_translations: {
                    en: '3-Month Plan',
                    ar: 'خطة 3 أشهر',
                    fr: 'Forfait 3 mois'
                },
                productId: 'velmora_premium_quarterly',
                durationMonths: 3,
                pricePerMonth: 3.33,
                totalPrice: 9.99,
                currency: 'USD',
                badge: 'SAVE 33%',
                badge_translations: {
                    en: 'SAVE 33%',
                    ar: 'وفر 33%',
                    fr: 'ÉCONOMISEZ 33%'
                },
                badgeColor: '#FF8A00',
                savingsText: 'Save 33% compared to monthly',
                savings_translations: {
                    en: 'Save 33% compared to monthly',
                    ar: 'وفر 33% مقارنة بالخطة الشهرية',
                    fr: 'Économisez 33% par rapport au forfait mensuel'
                },
                bottomNote: 'Start your journey today. Cancel anytime.',
                bottomNote_translations: {
                    en: 'Start your journey today. Cancel anytime.',
                    ar: 'ابدأ رحلتك اليوم. يمكنك الإلغاء في أي وقت.',
                    fr: 'Commencez votre voyage aujourd\'hui. Annulez à tout moment.'
                },
                features: [],
                isActive: true,
                isPopular: false,
                sortOrder: 2,
                createdAt: serverTimestamp(),
                updatedAt: serverTimestamp()
            },
            {
                name: 'Yearly Plan',
                name_translations: {
                    en: 'Yearly Plan',
                    ar: 'الخطة السنوية',
                    fr: 'Forfait annuel'
                },
                productId: 'velmora_premium_yearly',
                durationMonths: 12,
                pricePerMonth: 2.50,
                totalPrice: 29.99,
                currency: 'USD',
                badge: 'BEST VALUE',
                badge_translations: {
                    en: 'BEST VALUE',
                    ar: 'أفضل قيمة',
                    fr: 'MEILLEURE VALEUR'
                },
                badgeColor: '#FF8A00',
                savingsText: 'Save 50% compared to monthly',
                savings_translations: {
                    en: 'Save 50% compared to monthly',
                    ar: 'وفر 50% مقارنة بالخطة الشهرية',
                    fr: 'Économisez 50% par rapport au forfait mensuel'
                },
                bottomNote: 'Our most popular plan. Cancel anytime.',
                bottomNote_translations: {
                    en: 'Our most popular plan. Cancel anytime.',
                    ar: 'خطتنا الأكثر شعبية. يمكنك الإلغاء في أي وقت.',
                    fr: 'Notre forfait le plus populaire. Annulez à tout moment.'
                },
                features: [],
                isActive: true,
                isPopular: true,
                sortOrder: 3,
                createdAt: serverTimestamp(),
                updatedAt: serverTimestamp()
            }
        ];

        for (const plan of defaults) {
            const ref = doc(collection(db, COLLECTION));
            await setDoc(ref, plan);
        }
    }
};
