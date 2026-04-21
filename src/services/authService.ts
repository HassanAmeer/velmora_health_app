import {
    signInWithEmailAndPassword,
    signOut,
    User
} from 'firebase/auth';
import { auth, db } from './firebase';
import { doc, getDoc } from 'firebase/firestore';

export interface AdminUser extends User {
    role?: 'Super Admin' | 'Moderator';
}

const SESSION_TIMEOUT = 12 * 60 * 60 * 1000; // 12 hours in milliseconds
const SESSION_KEY = 'admin_session_timestamp';
const DEV_LOGIN_KEY = 'dev_login_mode';

export const authService = {
    login: async (email: string, pass: string) => {
        const normalizedEmail = email.trim().toLowerCase();

        // 1. Fetch current admin credentials from Firestore
        let adminEmail = 'dev@gmail.com';
        let adminPassword = '12345678';

        try {
            const adminDoc = await getDoc(doc(db, 'admin', 'credentials'));
            if (adminDoc.exists()) {
                const data = adminDoc.data();
                adminEmail = data.adminEmail || adminEmail;
                adminPassword = data.adminPassword || adminPassword;
            }
        } catch (e) {
            console.log('Using default dev credentials (could not fetch from Firestore)');
        }

        // 2. Developer/Local shortcut login check
        if ((normalizedEmail === 'dev@gmail.com' && pass === '12345678') ||
            (normalizedEmail === adminEmail.trim().toLowerCase() && pass === adminPassword)) {

            localStorage.setItem(SESSION_KEY, Date.now().toString());
            localStorage.setItem(DEV_LOGIN_KEY, 'true');

            // Create a mock user for dev mode
            return {
                user: {
                    uid: 'dev-user',
                    email: normalizedEmail,
                    displayName: 'Local Admin',
                }
            };
        }

        // 3. Real Firebase Authentication fallback
        localStorage.removeItem(DEV_LOGIN_KEY);
        localStorage.setItem(SESSION_KEY, Date.now().toString());

        const result = await signInWithEmailAndPassword(auth, email, pass);
        return result;
    },

    logout: async () => {
        // Clear session timestamp
        localStorage.removeItem(SESSION_KEY);
        const isDevMode = localStorage.getItem(DEV_LOGIN_KEY) === 'true';
        localStorage.removeItem(DEV_LOGIN_KEY);

        // Only sign out from Firebase if not in dev mode
        if (!isDevMode) {
            await signOut(auth);
        }
    },

    getCurrentUser: () => {
        // Check if in dev mode
        const isDevMode = localStorage.getItem(DEV_LOGIN_KEY) === 'true';
        if (isDevMode) {
            return {
                uid: 'dev-user',
                email: 'adm@developer.local',
                displayName: 'Developer',
            } as User;
        }
        return auth.currentUser;
    },

    getAdminRole: async (uid: string): Promise<'Super Admin' | 'Moderator' | undefined> => {
        // Dev mode always gets Super Admin
        if (uid === 'dev-user') {
            return 'Super Admin';
        }

        const adminDoc = await getDoc(doc(db, 'admin', uid));
        if (adminDoc.exists()) {
            return adminDoc.data().role;
        }
        return undefined;
    },

    isDevMode: (): boolean => {
        const isDev = localStorage.getItem(DEV_LOGIN_KEY) === 'true';
        console.log('authService.isDevMode:', isDev);
        return isDev;
    },

    // Check if session is still valid
    isSessionValid: (): boolean => {
        const sessionTimestamp = localStorage.getItem(SESSION_KEY);
        if (!sessionTimestamp) {
            console.log('authService.isSessionValid: No timestamp found');
            return false;
        }

        const loginTime = parseInt(sessionTimestamp, 10);
        const currentTime = Date.now();
        const timeDiff = currentTime - loginTime;
        const isValid = timeDiff < SESSION_TIMEOUT;

        console.log('authService.isSessionValid:', isValid, {
            loginTime,
            currentTime,
            timeDiff,
            timeout: SESSION_TIMEOUT
        });

        return isValid;
    },

    // Get remaining session time in minutes
    getRemainingSessionTime: (): number => {
        const sessionTimestamp = localStorage.getItem(SESSION_KEY);
        if (!sessionTimestamp) {
            return 0;
        }

        const loginTime = parseInt(sessionTimestamp, 10);
        const currentTime = Date.now();
        const timeDiff = currentTime - loginTime;
        const remainingMs = SESSION_TIMEOUT - timeDiff;

        return Math.max(0, Math.floor(remainingMs / (60 * 1000))); // Convert to minutes
    }
};
