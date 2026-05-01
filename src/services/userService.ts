import {
    collection,
    query,
    where,
    orderBy,
    limit,
    getDocs,
    doc,
    getDoc,
    updateDoc,
    deleteDoc
} from 'firebase/firestore';
import { db } from './firebase';

export interface UserProfile {
    uid: string;
    displayName: string;
    email: string;
    password?: string;
    photoURL?: string;
    subscriptionStatus: 'free' | 'trial' | 'premium';
    deleted?: boolean;
    subscriptionType?: string;
    subscriptionExpiryDate?: any;
    trialStartTime?: any;
    trialEndTime?: any;
    isPremium?: boolean;
    hasUsed48HourTrial?: boolean;
    cancellationRequested?: boolean;
    cancellationRequestedAt?: any;
    preferredLanguage: string;
    lastLoginAt: any;
    createdAt: any;
    featuresAccess?: Record<string, boolean>;
    isBanned?: boolean;
    authProvider?: string;
}

export interface UserGameSession {
    id: string;
    userId?: string;
    gameType?: string;
    gameId?: string;
    status?: string;
    score?: number;
    startedAt?: any;
    completedAt?: any;
}

export interface UserKegelSummary {
    weekStreak?: number;
    totalCompleted?: number;
    totalMinutes?: number;
    dailyGoalPercent?: number;
    longestStreak?: number;
    lastSessionDate?: any;
}

export interface UserKegelSession {
    id: string;
    routineType?: string;
    durationMinutes?: number;
    setsCompleted?: number;
    completedAt?: any;
    date?: string;
}

export interface UserKegelDailyCompletion {
    id: string;
    date?: string;
    completions?: number;
    lastUpdated?: any;
}

export interface UserGameProgress {
    playedGames?: any[];
    sessions?: any[];
    totalScore?: number;
}

export interface UserGameProgressData {
    aggregate: UserGameProgress | null;
    gameSessions: UserGameSession[];
}

export interface UserKegelProgressData {
    summary: UserKegelSummary | null;
    sessions: UserKegelSession[];
    dailyCompletions: UserKegelDailyCompletion[];
}

const fetchUserGameSessions = async (uid: string): Promise<UserGameSession[]> => {
    const sessionsQuery = query(
        collection(db, 'user_games'),
        where('userId', '==', uid),
        orderBy('startedAt', 'desc')
    );

    const sessionsSnapshot = await getDocs(sessionsQuery);
    return sessionsSnapshot.docs.map(sessionDoc => ({
        id: sessionDoc.id,
        ...(sessionDoc.data() as Omit<UserGameSession, 'id'>)
    }));
};

const fetchUserKegelSessions = async (uid: string): Promise<UserKegelSession[]> => {
    const sessionsQuery = query(
        collection(db, 'users', uid, 'kegel_sessions'),
        orderBy('completedAt', 'desc')
    );

    const sessionsSnapshot = await getDocs(sessionsQuery);
    return sessionsSnapshot.docs.map(sessionDoc => ({
        id: sessionDoc.id,
        ...(sessionDoc.data() as Omit<UserKegelSession, 'id'>)
    }));
};

const fetchUserKegelDailyCompletions = async (uid: string): Promise<UserKegelDailyCompletion[]> => {
    const dailyQuery = query(
        collection(db, 'users', uid, 'kegel_daily_completions'),
        orderBy('date', 'desc')
    );

    const dailySnapshot = await getDocs(dailyQuery);
    return dailySnapshot.docs.map(dailyDoc => ({
        id: dailyDoc.id,
        ...(dailyDoc.data() as Omit<UserKegelDailyCompletion, 'id'>)
    }));
};

const fetchUserGameProgressAggregate = async (uid: string): Promise<UserGameProgress | null> => {
    const progressDoc = await getDoc(doc(db, 'user_game_progress', uid));
    if (!progressDoc.exists()) {
        return null;
    }

    return progressDoc.data() as UserGameProgress;
};

const fetchUserKegelSummary = async (uid: string): Promise<UserKegelSummary | null> => {
    const userDoc = await getDoc(doc(db, 'users', uid));
    if (!userDoc.exists()) {
        return null;
    }

    const data = userDoc.data() as { kegel?: UserKegelSummary };
    return data.kegel ?? null;
};

const createUserGameProgressFallback = async (uid: string): Promise<UserGameProgressData> => {
    return {
        aggregate: await fetchUserGameProgressAggregate(uid),
        gameSessions: await fetchUserGameSessions(uid)
    };
};

const createUserKegelProgressFallback = async (uid: string): Promise<UserKegelProgressData> => {
    return {
        summary: await fetchUserKegelSummary(uid),
        sessions: await fetchUserKegelSessions(uid),
        dailyCompletions: await fetchUserKegelDailyCompletions(uid)
    };
};

const getUserGameProgress = async (uid: string): Promise<UserGameProgressData> => {
    try {
        return await createUserGameProgressFallback(uid);
    } catch (error) {
        console.error('Error loading user game progress:', error);
        return {
            aggregate: null,
            gameSessions: []
        };
    }
};

const getUserKegelProgress = async (uid: string): Promise<UserKegelProgressData> => {
    try {
        return await createUserKegelProgressFallback(uid);
    } catch (error) {
        console.error('Error loading user kegel progress:', error);
        return {
            summary: null,
            sessions: [],
            dailyCompletions: []
        };
    }
};

const getUserById = async (uid: string) => {
    const userDoc = await getDoc(doc(db, 'users', uid));
    if (userDoc.exists()) {
        return { uid: userDoc.id, ...userDoc.data() } as UserProfile;
    }
    return null;
};

const updateUserSubscription = async (uid: string, status: 'free' | 'trial' | 'premium') => {
    await updateDoc(doc(db, 'users', uid), { subscriptionStatus: status });
};

const updateUser = async (uid: string, data: Partial<UserProfile>) => {
    await updateDoc(doc(db, 'users', uid), data);
};

const deleteUser = async (uid: string) => {
    await updateDoc(doc(db, 'users', uid), { deleted: true });
};

const restoreUser = async (uid: string) => {
    await updateDoc(doc(db, 'users', uid), { deleted: false });
};

const permanentlyDeleteUser = async (uid: string) => {
    // Delete from Firestore
    await deleteDoc(doc(db, 'users', uid));
    
    // Note: Deleting from Firebase Auth directly from the frontend is not possible 
    // for other users due to security restrictions. This usually requires a 
    // Cloud Function using the Firebase Admin SDK.
    // If you have a Cloud Function for this, you can call it here.
    console.log(`User ${uid} deleted from Firestore. Auth deletion requires Cloud Functions.`);
};

const getUsers = async (pageSize = 10) => {
    const q = query(collection(db, 'users'), limit(pageSize));
    const querySnapshot = await getDocs(q);

    return querySnapshot.docs
        .map(doc => ({ uid: doc.id, ...doc.data() } as UserProfile));
};

export const userService = {
    getUsers,
    getUserById,
    updateUserSubscription,
    updateUser,
    deleteUser,
    restoreUser,
    permanentlyDeleteUser,
    getUserGameProgress,
    getUserKegelProgress
};

export {
    getUsers,
    getUserById,
    updateUserSubscription,
    updateUser,
    deleteUser,
    restoreUser,
    permanentlyDeleteUser,
    getUserGameProgress,
    getUserKegelProgress
};

