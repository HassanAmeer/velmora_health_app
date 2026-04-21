import React, { useEffect, useMemo, useState } from 'react';
import {
    Alert,
    Box,
    Card,
    CardContent,
    Chip,
    Divider,
    Grid,
    LinearProgress,
    Skeleton,
    Stack,
    Typography
} from '@mui/material';
import {
    PeopleAlt,
    Star,
    SportsEsports,
    FitnessCenter,
    WorkspacePremium,
    TrendingUp,
    Insights
} from '@mui/icons-material';
import {
    Bar,
    BarChart,
    CartesianGrid,
    Cell,
    Legend,
    Pie,
    PieChart,
    ResponsiveContainer,
    Tooltip,
    XAxis,
    YAxis
} from 'recharts';
import { collection, getCountFromServer, query, where } from 'firebase/firestore';
import { db } from '../../services/firebase';

interface DashboardStats {
    totalUsers: number;
    premiumUsers: number;
    freeUsers: number;
    trialUsers: number;
    totalGames: number;
    premiumGames: number;
    totalKegels: number;
    premiumKegels: number;
    usersWithKegelProgress: number;
    usersWithGameProgress: number;
}

interface MetricCardProps {
    title: string;
    value: string;
    subtitle: string;
    icon: React.ReactNode;
    accent: string;
    loading: boolean;
}

const initialStats: DashboardStats = {
    totalUsers: 0,
    premiumUsers: 0,
    freeUsers: 0,
    trialUsers: 0,
    totalGames: 0,
    premiumGames: 0,
    totalKegels: 0,
    premiumKegels: 0,
    usersWithKegelProgress: 0,
    usersWithGameProgress: 0
};

const numberFormatter = new Intl.NumberFormat();

const MetricCard: React.FC<MetricCardProps> = ({ title, value, subtitle, icon, accent, loading }) => (
    <Card
        sx={{
            height: '100%',
            borderRadius: 3,
            border: '1px solid',
            borderColor: 'divider',
            boxShadow: '0 12px 30px rgba(15, 23, 42, 0.08)',
            transition: 'transform 0.2s ease, box-shadow 0.2s ease',
            '&:hover': {
                transform: 'translateY(-3px)',
                boxShadow: '0 18px 36px rgba(15, 23, 42, 0.12)'
            }
        }}
    >
        <CardContent>
            <Stack direction="row" justifyContent="space-between" alignItems="flex-start" spacing={2}>
                <Box sx={{ flexGrow: 1 }}>
                    <Typography variant="overline" color="text.secondary" sx={{ fontWeight: 700 }}>
                        {title}
                    </Typography>
                    {loading ? (
                        <Skeleton animation="wave" width="55%" height={44} sx={{ my: 0.5 }} />
                    ) : (
                        <Typography variant="h4" sx={{ fontWeight: 800, lineHeight: 1.1, my: 0.5 }}>
                            {value}
                        </Typography>
                    )}
                    {loading ? (
                        <Skeleton animation="wave" width="70%" height={20} />
                    ) : (
                        <Typography variant="body2" color="text.secondary">
                            {subtitle}
                        </Typography>
                    )}
                </Box>
                <Box
                    sx={{
                        width: 46,
                        height: 46,
                        borderRadius: 2.5,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: '#fff',
                        bgcolor: accent,
                        boxShadow: `0 10px 24px ${accent}55`
                    }}
                >
                    {icon}
                </Box>
            </Stack>
        </CardContent>
    </Card>
);

import SkeletonLoader from '../../components/Layout/SkeletonLoader';

const Dashboard: React.FC = () => {
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [stats, setStats] = useState<DashboardStats>(initialStats);

    useEffect(() => {
        const loadDashboardStats = async () => {
            setLoading(true);
            setError(null);

            try {
                const usersCollection = collection(db, 'users');
                const gamesCollection = collection(db, 'games');
                const kegelCollection = collection(db, 'kegel_exercises');
                const gameProgressCollection = collection(db, 'user_game_progress');

                const [
                    totalUsersSnap,
                    premiumUsersSnap,
                    freeUsersSnap,
                    trialUsersSnap,
                    totalGamesSnap,
                    premiumGamesSnap,
                    totalKegelsSnap,
                    premiumKegelsSnap,
                    usersWithKegelProgressSnap,
                    usersWithGameProgressSnap
                ] = await Promise.all([
                    getCountFromServer(usersCollection),
                    getCountFromServer(query(usersCollection, where('subscriptionStatus', '==', 'premium'))),
                    getCountFromServer(query(usersCollection, where('subscriptionStatus', '==', 'free'))),
                    getCountFromServer(query(usersCollection, where('subscriptionStatus', '==', 'trial'))),
                    getCountFromServer(gamesCollection),
                    getCountFromServer(query(gamesCollection, where('isPremium', '==', true))),
                    getCountFromServer(kegelCollection),
                    getCountFromServer(query(kegelCollection, where('isPremium', '==', true))),
                    getCountFromServer(query(usersCollection, where('kegel.totalCompleted', '>', 0))),
                    getCountFromServer(gameProgressCollection)
                ]);

                setStats({
                    totalUsers: totalUsersSnap.data().count,
                    premiumUsers: premiumUsersSnap.data().count,
                    freeUsers: freeUsersSnap.data().count,
                    trialUsers: trialUsersSnap.data().count,
                    totalGames: totalGamesSnap.data().count,
                    premiumGames: premiumGamesSnap.data().count,
                    totalKegels: totalKegelsSnap.data().count,
                    premiumKegels: premiumKegelsSnap.data().count,
                    usersWithKegelProgress: usersWithKegelProgressSnap.data().count,
                    usersWithGameProgress: usersWithGameProgressSnap.data().count
                });
            } catch (err) {
                const message = err instanceof Error ? err.message : 'Failed to load dashboard data';
                setError(message);
            } finally {
                setLoading(false);
            }
        };

        void loadDashboardStats();
    }, []);

    const premiumUserRate = stats.totalUsers > 0 ? (stats.premiumUsers / stats.totalUsers) * 100 : 0;
    const kegelProgressRate = stats.totalUsers > 0 ? (stats.usersWithKegelProgress / stats.totalUsers) * 100 : 0;
    const gameProgressRate = stats.totalUsers > 0 ? (stats.usersWithGameProgress / stats.totalUsers) * 100 : 0;

    const subscriptionData = useMemo(
        () => [
            { name: 'Free', value: stats.freeUsers },
            { name: 'Trial', value: stats.trialUsers },
            { name: 'Premium', value: stats.premiumUsers }
        ],
        [stats.freeUsers, stats.premiumUsers, stats.trialUsers]
    );

    const contentData = useMemo(
        () => [
            {
                name: 'Games',
                premium: stats.premiumGames,
                free: Math.max(stats.totalGames - stats.premiumGames, 0)
            },
            {
                name: 'Kegels',
                premium: stats.premiumKegels,
                free: Math.max(stats.totalKegels - stats.premiumKegels, 0)
            }
        ],
        [stats.premiumGames, stats.premiumKegels, stats.totalGames, stats.totalKegels]
    );

    const progressData = useMemo(
        () => [
            {
                name: 'Kegel Progress',
                progressed: stats.usersWithKegelProgress,
                noProgress: Math.max(stats.totalUsers - stats.usersWithKegelProgress, 0)
            },
            {
                name: 'Game Progress',
                progressed: stats.usersWithGameProgress,
                noProgress: Math.max(stats.totalUsers - stats.usersWithGameProgress, 0)
            }
        ],
        [stats.totalUsers, stats.usersWithGameProgress, stats.usersWithKegelProgress]
    );

    return (
        <Stack spacing={3}>
            <Card
                sx={{
                    borderRadius: 4,
                    color: '#fff',
                    background: 'linear-gradient(135deg, #4F46E5 0%, #7C3AED 60%, #DB2777 100%)',
                    boxShadow: '0 20px 40px rgba(79, 70, 229, 0.35)'
                }}
            >
                <CardContent sx={{ p: { xs: 2.5, md: 3.5 } }}>
                    <Stack direction={{ xs: 'column', md: 'row' }} justifyContent="space-between" spacing={2} alignItems={{ xs: 'flex-start', md: 'center' }}>
                        <Box>
                            <Typography variant="h4" sx={{ fontWeight: 800, mb: 1 }}>
                                Dashboard Overview
                            </Typography>
                            <Typography variant="body1" sx={{ opacity: 0.9 }}>
                                Monitor user growth, premium usage, content mix, and engagement progress.
                            </Typography>
                        </Box>
                        <Chip icon={<Insights sx={{ color: '#fff !important', paddingX: '7px' }} />} label="Live Metrics" sx={{ color: '#fff', bgcolor: 'rgba(255,255,255,0.2)', fontWeight: 700 }} />
                    </Stack>
                </CardContent>
            </Card>

            {error && <Alert severity="error">{error}</Alert>}

            {loading ? (
                <SkeletonLoader type="dashboard" />
            ) : (
                <Grid container rowSpacing={2.5} columnSpacing={0}>
                    <Grid item xs={12} sm={6} lg={3}>
                        <MetricCard
                            title="Total Users"
                            value={numberFormatter.format(stats.totalUsers)}
                            subtitle={`${numberFormatter.format(stats.freeUsers)} free • ${numberFormatter.format(stats.trialUsers)} trial`}
                            icon={<PeopleAlt />}
                            accent="#4F46E5"
                            loading={loading}
                        />
                    </Grid>
                    <Grid item xs={12} sm={6} lg={3}>
                        <MetricCard
                            title="Premium Users"
                            value={numberFormatter.format(stats.premiumUsers)}
                            subtitle={`${premiumUserRate.toFixed(1)}% conversion`}
                            icon={<Star />}
                            accent="#F59E0B"
                            loading={loading}
                        />
                    </Grid>
                    <Grid item xs={12} sm={6} lg={3}>
                        <MetricCard
                            title="Total Games"
                            value={numberFormatter.format(stats.totalGames)}
                            subtitle={`${numberFormatter.format(stats.premiumGames)} premium games`}
                            icon={<SportsEsports />}
                            accent="#2563EB"
                            loading={loading}
                        />
                    </Grid>
                    <Grid item xs={12} sm={6} lg={3}>
                        <MetricCard
                            title="Total Kegels"
                            value={numberFormatter.format(stats.totalKegels)}
                            subtitle={`${numberFormatter.format(stats.premiumKegels)} premium kegels`}
                            icon={<FitnessCenter />}
                            accent="#DB2777"
                            loading={loading}
                        />
                    </Grid>
                </Grid>
            )}

            <Grid container rowSpacing={2.5} columnSpacing={0}>
                <Grid item xs={12} lg={4}>
                    <Card sx={{ borderRadius: 3, height: '100%', border: '1px solid', borderColor: 'divider' }}>
                        <CardContent>
                            <Typography variant="h6" sx={{ fontWeight: 700, mb: 2 }}>
                                Subscription Distribution
                            </Typography>
                            <Box sx={{ height: 280 }}>
                                <ResponsiveContainer width="100%" height="100%">
                                    <PieChart>
                                        <Pie data={subscriptionData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={100}>
                                            <Cell fill="#22C55E" />
                                            <Cell fill="#8B5CF6" />
                                            <Cell fill="#F59E0B" />
                                        </Pie>
                                        <Tooltip />
                                        <Legend />
                                    </PieChart>
                                </ResponsiveContainer>
                            </Box>
                        </CardContent>
                    </Card>
                </Grid>

                <Grid item xs={12} lg={8}>
                    <Card sx={{ borderRadius: 3, height: '100%', border: '1px solid', borderColor: 'divider' }}>
                        <CardContent>
                            <Typography variant="h6" sx={{ fontWeight: 700, mb: 2 }}>
                                Premium vs Free Content
                            </Typography>
                            <Box sx={{ height: 280 }}>
                                <ResponsiveContainer width="100%" height="100%">
                                    <BarChart data={contentData}>
                                        <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
                                        <XAxis dataKey="name" />
                                        <YAxis allowDecimals={false} />
                                        <Tooltip />
                                        <Legend />
                                        <Bar dataKey="premium" fill="#7C3AED" radius={[6, 6, 0, 0]} name="Premium" />
                                        <Bar dataKey="free" fill="#3B82F6" radius={[6, 6, 0, 0]} name="Free" />
                                    </BarChart>
                                </ResponsiveContainer>
                            </Box>
                        </CardContent>
                    </Card>
                </Grid>

                <Grid item xs={12}>
                    <Card sx={{ borderRadius: 3, border: '1px solid', borderColor: 'divider' }}>
                        <CardContent>
                            <Typography variant="h6" sx={{ fontWeight: 700, mb: 2 }}>
                                Progress Coverage & Engagement
                            </Typography>
                            <Grid container spacing={2.5}>
                                <Grid item xs={12} md={7}>
                                    <Box sx={{ height: 260 }}>
                                        <ResponsiveContainer width="100%" height="100%">
                                            <BarChart data={progressData}>
                                                <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" />
                                                <XAxis dataKey="name" />
                                                <YAxis allowDecimals={false} />
                                                <Tooltip />
                                                <Legend />
                                                <Bar dataKey="progressed" fill="#10B981" radius={[6, 6, 0, 0]} name="With Progress" />
                                                <Bar dataKey="noProgress" fill="#EF4444" radius={[6, 6, 0, 0]} name="No Progress" />
                                            </BarChart>
                                        </ResponsiveContainer>
                                    </Box>
                                </Grid>
                                <Grid item xs={12} md={5}>
                                    <Stack spacing={2} sx={{ mt: 0.5 }}>
                                        <Box>
                                            <Stack direction="row" justifyContent="space-between" sx={{ mb: 0.8 }}>
                                                <Typography variant="body2" color="text.secondary">Premium user conversion</Typography>
                                                <Typography variant="body2" sx={{ fontWeight: 700 }}>
                                                    {premiumUserRate.toFixed(1)}%
                                                </Typography>
                                            </Stack>
                                            <LinearProgress variant="determinate" value={premiumUserRate} sx={{ height: 10, borderRadius: 999, bgcolor: '#FEF3C7', '& .MuiLinearProgress-bar': { bgcolor: '#F59E0B' } }} />
                                        </Box>

                                        <Divider />

                                        <Box>
                                            <Stack direction="row" justifyContent="space-between" sx={{ mb: 0.8 }}>
                                                <Typography variant="body2" color="text.secondary">Users with kegel progress</Typography>
                                                <Typography variant="body2" sx={{ fontWeight: 700 }}>
                                                    {kegelProgressRate.toFixed(1)}%
                                                </Typography>
                                            </Stack>
                                            <LinearProgress variant="determinate" value={kegelProgressRate} sx={{ height: 10, borderRadius: 999, bgcolor: '#FCE7F3', '& .MuiLinearProgress-bar': { bgcolor: '#DB2777' } }} />
                                        </Box>

                                        <Box>
                                            <Stack direction="row" justifyContent="space-between" sx={{ mb: 0.8 }}>
                                                <Typography variant="body2" color="text.secondary">Users with game progress</Typography>
                                                <Typography variant="body2" sx={{ fontWeight: 700 }}>
                                                    {gameProgressRate.toFixed(1)}%
                                                </Typography>
                                            </Stack>
                                            <LinearProgress variant="determinate" value={gameProgressRate} sx={{ height: 10, borderRadius: 999, bgcolor: '#DBEAFE', '& .MuiLinearProgress-bar': { bgcolor: '#2563EB' } }} />
                                        </Box>

                                        <Box sx={{ p: 1.5, borderRadius: 2, bgcolor: '#F8FAFC', border: '1px solid #E2E8F0' }}>
                                            <Typography variant="caption" color="text.secondary">Live totals</Typography>
                                            <Typography sx={{ fontWeight: 700, mt: 0.4 }}>
                                                {numberFormatter.format(stats.usersWithGameProgress)} game-progress users • {numberFormatter.format(stats.usersWithKegelProgress)} kegel-progress users
                                            </Typography>
                                        </Box>
                                    </Stack>
                                </Grid>
                            </Grid>
                        </CardContent>
                    </Card>
                </Grid>

                <Grid item xs={12} sm={6} lg={3}>
                    <MetricCard
                        title="Premium Games"
                        value={numberFormatter.format(stats.premiumGames)}
                        subtitle="Monetized game content"
                        icon={<WorkspacePremium />}
                        accent="#7C3AED"
                        loading={loading}
                    />
                </Grid>
                <Grid item xs={12} sm={6} lg={3}>
                    <MetricCard
                        title="Premium Kegels"
                        value={numberFormatter.format(stats.premiumKegels)}
                        subtitle="Monetized kegel content"
                        icon={<WorkspacePremium />}
                        accent="#EC4899"
                        loading={loading}
                    />
                </Grid>
                <Grid item xs={12} sm={6} lg={3}>
                    <MetricCard
                        title="Kegel Progress Users"
                        value={numberFormatter.format(stats.usersWithKegelProgress)}
                        subtitle="Users with tracked completions"
                        icon={<TrendingUp />}
                        accent="#0EA5E9"
                        loading={loading}
                    />
                </Grid>
                <Grid item xs={12} sm={6} lg={3}>
                    <MetricCard
                        title="Game Progress Users"
                        value={numberFormatter.format(stats.usersWithGameProgress)}
                        subtitle="Users with game history"
                        icon={<TrendingUp />}
                        accent="#16A34A"
                        loading={loading}
                    />
                </Grid>
            </Grid>
        </Stack>
    );
};

export default Dashboard;
