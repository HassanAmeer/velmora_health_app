import React, { useMemo, useState } from 'react';
import SkeletonLoader from '../components/Layout/SkeletonLoader';
import {
    Box,
    Typography,
    Button,
    Paper,
    List,
    ListItem,
    ListItemIcon,
    ListItemText,
    CircularProgress,
    Alert,
    LinearProgress,
    FormControl,
    FormLabel,
    RadioGroup,
    FormControlLabel,
    Radio,
    Stack,
    Chip,
} from '@mui/material';
import { CheckCircle, Storage, PersonAdd, PlayArrow } from '@mui/icons-material';
import {
    seedService,
    type SeedMode,
    DEFAULT_ADMIN_EMAIL,
    DEFAULT_ADMIN_PASSWORD,
} from '../services/seedService';

const modeLabelMap: Record<SeedMode, string> = {
    full: 'Full Migration',
    'append-users': 'Add/Update Users & Progress',
    'configs-only': 'Configs, FAQs & Legal Docs',
};

const SeedPage: React.FC = () => {
    const [logs, setLogs] = useState<string[]>([]);
    const [loading, setLoading] = useState(false);
    const [complete, setComplete] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [mode, setMode] = useState<SeedMode>('full');

    const totalSteps = useMemo(() => {
        if (mode === 'full') return 14;
        if (mode === 'append-users') return 8;
        return 4;
    }, [mode]);

    const addLog = (msg: string) => {
        setLogs((prev) => [...prev, `${new Date().toLocaleTimeString()}: ${msg}`]);
    };

    const handleSeed = async () => {
        setLoading(true);
        setError(null);
        setComplete(false);
        setLogs([]);

        try {
            addLog(`Starting ${modeLabelMap[mode]}...`);
            const adminResult = await seedService.seedAdmin();
            addLog(adminResult.message);

            await seedService.migrateData(mode, (msg) => addLog(msg));

            setComplete(true);
        } catch (err: any) {
            const message = err?.message || 'An error occurred during migration.';
            setError(message);
            addLog(`ERROR: ${message}`);
        } finally {
            setLoading(false);
        }
    };

    const progressValue = totalSteps
        ? Math.min((logs.length / totalSteps) * 100, 100)
        : 0;

    return (
        <Box sx={{ maxWidth: 980, mx: 'auto', mt: 4 }}>
            <Paper sx={{ p: { xs: 2, sm: 4 }, borderRadius: 3 }}>
                <Stack
                    direction={{ xs: 'column', sm: 'row' }}
                    justifyContent="space-between"
                    alignItems={{ xs: 'flex-start', sm: 'center' }}
                    spacing={2}
                    sx={{ mb: 2 }}
                >
                    <Typography
                        variant="h4"
                        sx={{
                            fontWeight: 'bold',
                            display: 'flex',
                            alignItems: 'center',
                            gap: 1.5,
                        }}
                    >
                        <Storage color="primary" fontSize="large" />
                        Data Migration & Seeding
                    </Typography>

                    <Chip
                        color="primary"
                        label={modeLabelMap[mode]}
                        sx={{ fontWeight: 600 }}
                    />
                </Stack>

                <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
                    Seed realistic Firestore data for users, games, progress, chats, FAQs, legal docs,
                    subscriptions, and AI config.
                </Typography>

                <Alert severity="warning" sx={{ mb: 3 }}>
                    <strong>Admin Credentials:</strong> {DEFAULT_ADMIN_EMAIL} / {DEFAULT_ADMIN_PASSWORD}
                </Alert>

                <Paper variant="outlined" sx={{ p: { xs: 2, sm: 3 }, mb: 3 }}>
                    <FormControl>
                        <FormLabel sx={{ mb: 1 }}>Migration Mode</FormLabel>
                        <RadioGroup
                            value={mode}
                            onChange={(event) => setMode(event.target.value as SeedMode)}
                        >
                            <FormControlLabel
                                value="full"
                                control={<Radio />}
                                label="Full Migration (clear + seed all demo data)"
                            />
                            <FormControlLabel
                                value="append-users"
                                control={<Radio />}
                                label="Add/Update Users & Progress (keep existing configs)"
                            />
                            <FormControlLabel
                                value="configs-only"
                                control={<Radio />}
                                label="Configs, FAQs & Legal Docs only"
                            />
                        </RadioGroup>
                    </FormControl>
                </Paper>

                <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2} sx={{ mb: 3 }}>
                    <Button
                        variant="contained"
                        size="large"
                        onClick={handleSeed}
                        disabled={loading}
                        startIcon={loading ? <SkeletonLoader /> : <PlayArrow />}
                    >
                        {loading ? 'Running Migration...' : 'Run Migration'}
                    </Button>
                    <Button
                        variant="outlined"
                        size="large"
                        disabled={loading}
                        onClick={async () => {
                            setLoading(true);
                            setError(null);
                            setComplete(false);
                            setLogs([]);
                            try {
                                addLog('Creating admin user only...');
                                const adminResult = await seedService.seedAdmin();
                                addLog(adminResult.message);
                                addLog('Admin setup complete! ✅');
                                setComplete(true);
                            } catch (err: any) {
                                const message = err?.message || 'Failed to create admin user.';
                                setError(message);
                                addLog(`ERROR: ${message}`);
                            } finally {
                                setLoading(false);
                            }
                        }}
                        startIcon={loading ? <CircularProgress size={20} color="inherit" /> : <PersonAdd />}
                    >
                        Create Admin Only
                    </Button>
                </Stack>

                {(loading || logs.length > 0) && (
                    <Paper variant="outlined" sx={{ p: 2, mb: 3 }}>
                        <Stack spacing={1.5}>
                            <Typography variant="subtitle2" color="text.secondary">
                                Progress {Math.round(progressValue)}%
                            </Typography>
                            <LinearProgress variant="determinate" value={progressValue} />
                        </Stack>
                    </Paper>
                )}

                {logs.length > 0 && (
                    <Box sx={{ mt: 2 }}>
                        <Typography variant="h6" gutterBottom>
                            Process Logs
                        </Typography>
                        <Paper
                            variant="outlined"
                            sx={{ bgcolor: 'grey.50', maxHeight: 320, overflow: 'auto', p: 1 }}
                        >
                            <List dense>
                                {logs.map((log, index) => {
                                    const isSuccess =
                                        log.includes('complete') ||
                                        log.includes('Complete') ||
                                        log.includes('successfully') ||
                                        log.includes('✅');

                                    return (
                                        <ListItem key={index}>
                                            <ListItemIcon sx={{ minWidth: 34 }}>
                                                {isSuccess ? (
                                                    <CheckCircle color="success" fontSize="small" />
                                                ) : (
                                                    <SkeletonLoader />
                                                )}
                                            </ListItemIcon>
                                            <ListItemText primary={log} />
                                        </ListItem>
                                    );
                                })}
                            </List>
                        </Paper>
                    </Box>
                )}

                {complete && (
                    <Alert severity="success" sx={{ mt: 3 }}>
                        Migration complete. Admin and demo data are ready.
                    </Alert>
                )}

                {error && (
                    <Alert severity="error" sx={{ mt: 3 }}>
                        {error}
                    </Alert>
                )}
            </Paper>
        </Box>
    );
};

export default SeedPage;
