import React, { createContext, useContext, useEffect, useState } from 'react';
import { onAuthStateChanged } from 'firebase/auth';
import { auth } from '../services/firebase';
import { authService, AdminUser } from '../services/authService';
import SkeletonLoader from '../components/Layout/SkeletonLoader';

interface AuthContextType {
    user: AdminUser | null;
    loading: boolean;
    role: 'Super Admin' | 'Moderator' | null;
    login: (email: string, pass: string) => Promise<any>;
    logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType>({
    user: null,
    loading: true,
    role: null,
    login: async () => { },
    logout: async () => { },
});

export const useAuth = () => useContext(AuthContext);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
    const [user, setUser] = useState<AdminUser | null>(null);
    const [loading, setLoading] = useState(false);
    // `initializing` is ONLY for the very first app startup check.
    // It must NEVER be set to true during a login attempt.
    const [initializing, setInitializing] = useState(true);
    const [role, setRole] = useState<'Super Admin' | 'Moderator' | null>(null);

    const checkDevMode = async () => {
        if (authService.isDevMode()) {
            const devUser = authService.getCurrentUser();
            if (devUser) {
                const adminRole = await authService.getAdminRole(devUser.uid);
                setUser(devUser as AdminUser);
                setRole(adminRole || null);
                setInitializing(false);
                return true;
            }
        }
        return false;
    };

    const login = async (email: string, pass: string) => {
        // DO NOT touch global loading/initializing here.
        // LoginPage manages its own loading spinner.
        try {
            const result = await authService.login(email, pass);
            // If it's dev mode, we need to manually update state because onAuthStateChanged won't fire
            if (authService.isDevMode()) {
                const devUser = authService.getCurrentUser();
                if (devUser) {
                    const adminRole = await authService.getAdminRole(devUser.uid);
                    setUser(devUser as AdminUser);
                    setRole(adminRole || null);
                }
            }
            // For regular Firebase login, onAuthStateChanged will handle the state update
            return result;
        } catch (error) {
            // Re-throw so LoginPage can show the toast
            throw error;
        }
    };

    const logout = async () => {
        await authService.logout();
        setUser(null);
        setRole(null);
    };

    useEffect(() => {
        const initAuth = async () => {
            const isDevMode = await checkDevMode();
            if (isDevMode) return;

            // Normal Firebase auth flow
            let isFirstCheck = true;
            const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
                // Only show full-screen loader on the FIRST check (app startup)
                // Never on subsequent calls triggered by login/logout attempts
                if (!isFirstCheck) {
                    if (firebaseUser) {
                        if (!authService.isSessionValid()) {
                            await authService.logout();
                            setUser(null);
                            setRole(null);
                            return;
                        }
                        try {
                            const adminRole = await authService.getAdminRole(firebaseUser.uid);
                            setUser({ ...firebaseUser } as AdminUser);
                            setRole(adminRole || null);
                        } catch (error) {
                            setUser(null);
                            setRole(null);
                        }
                    } else {
                        setUser(null);
                        setRole(null);
                    }
                    return;
                }

                // First check only
                isFirstCheck = false;
                if (firebaseUser) {
                    if (!authService.isSessionValid()) {
                        await authService.logout();
                        setUser(null);
                        setRole(null);
                        setInitializing(false);
                        return;
                    }
                    try {
                        const adminRole = await authService.getAdminRole(firebaseUser.uid);
                        setUser({ ...firebaseUser } as AdminUser);
                        setRole(adminRole || null);
                    } catch (error) {
                        setUser(null);
                        setRole(null);
                    }
                } else {
                    setUser(null);
                    setRole(null);
                }
                setInitializing(false);
            });

            return unsubscribe;
        };

        const unsubscribePromise = initAuth();

        const sessionCheckInterval = setInterval(() => {
            if (authService.isDevMode()) {
                if (!authService.isSessionValid()) {
                    logout();
                }
            } else if (auth.currentUser && !authService.isSessionValid()) {
                logout();
            }
        }, 60000);

        return () => {
            unsubscribePromise.then(unsubscribe => {
                if (unsubscribe && typeof unsubscribe === 'function') unsubscribe();
            });
            clearInterval(sessionCheckInterval);
        };
    }, []);

    return (
        <AuthContext.Provider value={{ user, loading, role, login, logout }}>
            {initializing ? (
                <SkeletonLoader type="layout" />
            ) : (
                children
            )}
        </AuthContext.Provider>
    );
};
