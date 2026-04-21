import React, { useEffect, useMemo, useState } from 'react';
import {
    Alert,
    Box,
    Breadcrumbs,
    Chip,
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
    AssignmentTurnedIn,
    History,
    SportsEsports,
    Stars
} from '@mui/icons-material';
import { Link as RouterLink, useNavigate, useParams } from 'react-router-dom';
import {
    UserGameSession,
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

const formatGameName = (session: UserGameSession) => {
    const key = session.gameType || session.gameId || 'unknown_game';
    return key
        .split('_')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1))
        .join(' ');
};

const UserGameProgressPage: React.FC = () => {
    const { uid } = useParams<{ uid: string }>();
    const navigate = useNavigate();

    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [user, setUser] = useState<UserProfile | null>(null);
    const [sessions, setSessions] = useState<UserGameSession[]>([]);
    const [totalScore, setTotalScore] = useState(0);

    useEffect(() => {
        const load = async () => {
            if (!uid) return;

            try {
                setLoading(true);
                setError(null);

                const [userData, progressData] = await Promise.all([
                    userService.getUserById(uid),
                    userService.getUserGameProgress(uid)
                ]);

                setUser(userData);
                setSessions(progressData.gameSessions);
                setTotalScore(progressData.aggregate?.totalScore ?? 0);
            } catch (err: any) {
                setError(err?.message || 'Failed to load game progress');
            } finally {
                setLoading(false);
            }
        };

        load();
    }, [uid]);

    const completedCount = useMemo(
        () => sessions.filter(session => session.status === 'completed').length,
        [sessions]
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
                    <Typography color="text.primary">Game Progress</Typography>
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
                                Game Progress
                            </Typography>
                            <Typography color="text.secondary" sx={{ mt: 0.5 }}>
                                {user?.displayName || 'Unknown User'} ({user?.email || 'No email'})
                            </Typography>
                        </Box>
                    </Box>
                </Paper>
            </Box>

            <Box sx={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: 2, mb: 3 }}>
                <KPICard title="Total Sessions" value={sessions.length} icon={<History />} color="#7C3AED" />
                <KPICard title="Completed Sessions" value={completedCount} icon={<AssignmentTurnedIn />} color="#10B981" />
                <KPICard title="Total Score" value={totalScore} icon={<Stars />} color="#F59E0B" />
            </Box>

            <TableContainer component={Paper} sx={{ borderRadius: 3, boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}>
                <Table>
                    <TableHead sx={{ bgcolor: '#F8FAFC' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: '600' }}>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                    <SportsEsports fontSize="small" /> Game
                                </Box>
                            </TableCell>
                            <TableCell sx={{ fontWeight: '600' }}>Status</TableCell>
                            <TableCell sx={{ fontWeight: '600' }}>Score</TableCell>
                            <TableCell sx={{ fontWeight: '600' }}>Started At</TableCell>
                            <TableCell sx={{ fontWeight: '600' }}>Completed At</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {sessions.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={5} align="center" sx={{ py: 4 }}>
                                    <Typography color="text.secondary">No game sessions found for this user</Typography>
                                </TableCell>
                            </TableRow>
                        ) : (
                            sessions.map(session => (
                                <TableRow key={session.id} hover>
                                    <TableCell>{formatGameName(session)}</TableCell>
                                    <TableCell>
                                        <Chip
                                            label={session.status || 'unknown'}
                                            size="small"
                                            color={session.status === 'completed' ? 'success' : session.status === 'started' ? 'warning' : 'default'}
                                            variant={session.status === 'completed' ? 'filled' : 'outlined'}
                                        />
                                    </TableCell>
                                    <TableCell>{session.score ?? 0}</TableCell>
                                    <TableCell>{formatDate(session.startedAt)}</TableCell>
                                    <TableCell>{formatDate(session.completedAt)}</TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>
        </Box>
    );
};

export default UserGameProgressPage;
