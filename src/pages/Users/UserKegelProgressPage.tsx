import React, { useEffect, useMemo, useState } from 'react';
import {
    Alert,
    Box,
    Breadcrumbs,
    IconButton,
    Link,
    Paper,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Typography
} from '@mui/material';
import SkeletonLoader from '../../components/Layout/SkeletonLoader';
import {
    ArrowBack,
    CheckCircle,
    FitnessCenter,
    LocalFireDepartment,
    Timer,
    Today
} from '@mui/icons-material';
import { Link as RouterLink, useNavigate, useParams } from 'react-router-dom';
import {
    UserKegelDailyCompletion,
    UserKegelSession,
    UserKegelSummary,
    UserProfile,
    userService
} from '../../services/userService';
import KPICard from '../../components/Common/KPICard';

const formatDate = (value?: any) => {
    if (!value) return '—';

    try {
        if (value.seconds) {
            return new Date(value.seconds * 1000).toLocaleString();
        }

        const parsed = new Date(value);
        if (Number.isNaN(parsed.getTime())) return '—';
        return parsed.toLocaleString();
    } catch {
        return '—';
    }
};

const UserKegelProgressPage: React.FC = () => {
    const { uid } = useParams<{ uid: string }>();
    const navigate = useNavigate();

    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [user, setUser] = useState<UserProfile | null>(null);
    const [summary, setSummary] = useState<UserKegelSummary | null>(null);
    const [sessions, setSessions] = useState<UserKegelSession[]>([]);
    const [dailyCompletions, setDailyCompletions] = useState<UserKegelDailyCompletion[]>([]);

    useEffect(() => {
        const load = async () => {
            if (!uid) return;

            try {
                setLoading(true);
                setError(null);

                const [userData, progressData] = await Promise.all([
                    userService.getUserById(uid),
                    userService.getUserKegelProgress(uid)
                ]);

                setUser(userData);
                setSummary(progressData.summary);
                setSessions(progressData.sessions);
                setDailyCompletions(progressData.dailyCompletions);
            } catch (err: any) {
                setError(err?.message || 'Failed to load kegel progress');
            } finally {
                setLoading(false);
            }
        };

        load();
    }, [uid]);

    const totalDailyCompletions = useMemo(
        () => dailyCompletions.reduce((sum, item) => sum + (item.completions ?? 0), 0),
        [dailyCompletions]
    );

    if (loading) {
        return <SkeletonLoader type="list" count={5} />;
    }

    return (
        <Box>
            {error && <Alert severity="error" sx={{ mb: 3 }}>{error}</Alert>}

            <Box sx={{ mb: 3 }}>
                <Breadcrumbs sx={{ mb: 2 }}>
                    <Link component={RouterLink} underline="hover" color="inherit" to="/">Dashboard</Link>
                    <Link component={RouterLink} underline="hover" color="inherit" to="/users">Users</Link>
                    <Typography color="text.primary">Kegel Progress</Typography>
                </Breadcrumbs>

                <Paper
                    sx={{
                        p: 2,
                        borderRadius: 3,
                        bgcolor: '#F8FAFC',
                        border: '1px solid #E2E8F0'
                    }}
                >
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <IconButton onClick={() => navigate('/users')} size="small" sx={{ bgcolor: 'white' }}>
                            <ArrowBack />
                        </IconButton>
                        <Box>
                            <Typography variant="h5" sx={{ fontWeight: 'bold' }}>
                                Kegel Progress
                            </Typography>
                            <Typography color="text.secondary" sx={{ mt: 0.5 }}>
                                {user?.displayName || 'Unknown User'} ({user?.email || 'No email'})
                            </Typography>
                        </Box>
                    </Box>
                </Paper>
            </Box>

            <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 2, mb: 3 }}>
                <KPICard title="Week Streak" value={summary?.weekStreak ?? 0} icon={<LocalFireDepartment />} color="#F97316" />
                <KPICard title="Total Completed" value={summary?.totalCompleted ?? 0} icon={<CheckCircle />} color="#10B981" />
                <KPICard title="Total Minutes" value={summary?.totalMinutes ?? 0} icon={<Timer />} color="#7C3AED" />
                <KPICard title="Daily Completions" value={totalDailyCompletions} icon={<Today />} color="#0EA5E9" />
            </Box>

            <TableContainer component={Paper} sx={{ borderRadius: 3, mb: 3, boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}>
                <Table>
                    <TableHead sx={{ bgcolor: '#F8FAFC' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: '600' }}>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <FitnessCenter fontSize="small" /> Routine
                                </Box>
                            </TableCell>
                            <TableCell sx={{ fontWeight: '600' }}>Duration (mins)</TableCell>
                            <TableCell sx={{ fontWeight: '600' }}>Sets</TableCell>
                            <TableCell sx={{ fontWeight: '600' }}>Completed At</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {sessions.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={4} align="center" sx={{ py: 4 }}>
                                    <Typography color="text.secondary">No kegel sessions found for this user</Typography>
                                </TableCell>
                            </TableRow>
                        ) : (
                            sessions.map(session => (
                                <TableRow key={session.id} hover>
                                    <TableCell>{session.routineType || '—'}</TableCell>
                                    <TableCell>{session.durationMinutes ?? 0}</TableCell>
                                    <TableCell>{session.setsCompleted ?? 0}</TableCell>
                                    <TableCell>{formatDate(session.completedAt)}</TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>

            <TableContainer component={Paper} sx={{ borderRadius: 3, boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}>
                <Table>
                    <TableHead sx={{ bgcolor: '#F8FAFC' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: '600' }}>Date</TableCell>
                            <TableCell sx={{ fontWeight: '600' }}>Completions</TableCell>
                            <TableCell sx={{ fontWeight: '600' }}>Last Updated</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {dailyCompletions.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={3} align="center" sx={{ py: 4 }}>
                                    <Typography color="text.secondary">No daily completion data found</Typography>
                                </TableCell>
                            </TableRow>
                        ) : (
                            dailyCompletions.map(item => (
                                <TableRow key={item.id} hover>
                                    <TableCell>{item.date || item.id}</TableCell>
                                    <TableCell>{item.completions ?? 0}</TableCell>
                                    <TableCell>{formatDate(item.lastUpdated)}</TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>
        </Box>
    );
};

export default UserKegelProgressPage;
