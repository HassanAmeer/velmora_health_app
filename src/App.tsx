import { Routes, Route } from 'react-router-dom'
import { AuthProvider } from './contexts/AuthContext'
import MainLayout from './components/Layout/MainLayout'
import LoginPage from './pages/LoginPage'
import Dashboard from './pages/Dashboard/Dashboard'
import SeedPage from './pages/SeedPage'
import UserListPage from './pages/Users/UserListPage'
import UserDetailsPage from './pages/Users/UserDetailsPage'
import UserGameProgressPage from './pages/Users/UserGameProgressPage'
import UserKegelProgressPage from './pages/Users/UserKegelProgressPage'
import SubscriptionsPage from './pages/Subscriptions/SubscriptionsPage'
import AIConfigPage from './pages/AIConfig/AIConfigPage'
import NotificationsPage from './pages/Notifications/NotificationsPage'
import SupportPage from './pages/Support/SupportPage'
import SettingsPage from './pages/Settings/SettingsPage'
import GamesPage from './pages/Games/GamesPage'
import KegelPage from './pages/Kegel/KegelPage'

function App() {
    return (
        <AuthProvider>
            <Routes>
                <Route path="/login" element={<LoginPage />} />
                <Route path="/seed" element={<SeedPage />} />

                <Route path="/" element={<MainLayout />}>
                    <Route index element={<Dashboard />} />

                    <Route path="users" element={<UserListPage />} />
                    <Route path="users/:uid" element={<UserDetailsPage />} />
                    <Route path="users/:uid/game-progress" element={<UserGameProgressPage />} />
                    <Route path="users/:uid/kegel-progress" element={<UserKegelProgressPage />} />

                    <Route path="subscriptions" element={<SubscriptionsPage />} />
                    <Route path="ai-config" element={<AIConfigPage />} />
                    <Route path="games" element={<GamesPage />} />
                    <Route path="kegel" element={<KegelPage />} />
                    <Route path="notifications" element={<NotificationsPage />} />
                    <Route path="support" element={<SupportPage />} />
                    <Route path="settings" element={<SettingsPage />} />
                </Route>
            </Routes>
        </AuthProvider>
    )
}

export default App
