import React, { createContext, useContext, useEffect, useState } from 'react';
import { onAuthStateChanged } from 'firebase/auth';
import { auth } from '../services/firebase';
import { authService, AdminUser } from '../services/authService';

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
    const [loading, setLoading] = useState(true);
    const [role, setRole] = useState<'Super Admin' | 'Moderator' | null>(null);

    const checkDevMode = async () => {
        if (authService.isDevMode()) {
            const devUser = authService.getCurrentUser();
            if (devUser) {
                const adminRole = await authService.getAdminRole(devUser.uid);
                setUser(devUser as AdminUser);
                setRole(adminRole || null);
                setLoading(false);
                return true;
            }
        }
        return false;
    };

    const login = async (email: string, pass: string) => {
        setLoading(true);
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
                setLoading(false);
            }
            // For regular Firebase login, onAuthStateChanged will handle the state update
            return result;
        } catch (error) {
            setLoading(false);
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
            const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
                console.log('AuthContext: onAuthStateChanged fired', { hasUser: !!firebaseUser });
                setLoading(true);

                if (firebaseUser) {
                    if (!authService.isSessionValid()) {
                        console.log('AuthContext: Session invalid in listener. Logging out...');
                        await authService.logout();
                        setUser(null);
                        setRole(null);
                        setLoading(false);
                        return;
                    }

                    console.log('AuthContext: Fetching admin role for', firebaseUser.uid);
                    try {
                        const adminRole = await authService.getAdminRole(firebaseUser.uid);
                        setUser({ ...firebaseUser } as AdminUser);
                        setRole(adminRole || null);
                    } catch (error) {
                        console.error('AuthContext: Error fetching admin role:', error);
                        setUser(null);
                        setRole(null);
                    }
                } else {
                    setUser(null);
                    setRole(null);
                }
                setLoading(false);
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
            {loading ? (
                <div className="flex h-screen w-full items-center justify-center bg-slate-50 dark:bg-slate-900">
                    <div className="text-center">
                        <div className="h-12 w-12 animate-spin rounded-full border-4 border-primary border-t-transparent mx-auto"></div>
                        <p className="mt-4 font-medium text-slate-600 dark:text-slate-400">Initializing Velmora Admin...</p>
                    </div>
                </div>
            ) : (
                children
            )}
        </AuthContext.Provider>
    );
};
