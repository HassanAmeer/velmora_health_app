import React, { useState, useEffect } from 'react';
import {
    Box, Typography, Paper, Grid, Alert,
    Switch, FormControlLabel, Chip, Button, Stack
} from '@mui/material';
import { Refresh } from '@mui/icons-material';
import { collection, getDocs, doc, updateDoc, setDoc } from 'firebase/firestore';
import { db } from '../../services/firebase';
import SkeletonLoader from '../../components/Layout/SkeletonLoader';

interface Game {
    id: string;
    name: string;
    isPremium: boolean;
    isActive: boolean;
}

// Default games that match the app
const defaultGames: Game[] = [
    {
        id: 'truth_or_truth',
        name: 'Truth or Truth',
        isPremium: false,
        isActive: true,
    },
    {
        id: 'love_language_quiz',
        name: 'Love Language Quiz',
        isPremium: true,
        isActive: true,
    },
    {
        id: 'reflection_game',
        name: 'Reflection & Discussion',
        isPremium: false,
        isActive: true,
    },
    {
        id: 'couples_challenge',
        name: 'Couple\'s Challenge',
        isPremium: false,
        isActive: true,
    },
    {
        id: 'would_you_rather',
        name: 'Would You Rather',
        isPremium: false,
        isActive: true,
    },
    {
        id: 'date_night_ideas',
        name: 'Date Night Ideas',
        isPremium: false,
        isActive: true,
    },
    {
        id: 'relationship_quiz',
        name: 'Relationship Quiz',
        isPremium: false,
        isActive: true,
    },
    {
        id: 'compliment_game',
        name: 'Compliment Game',
        isPremium: false,
        isActive: true,
    },
];

const GamesPage: React.FC = () => {
    const [games, setGames] = useState<Game[]>([]);
    const [loading, setLoading] = useState(true);
    const [success, setSuccess] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        loadGames();
    }, []);

    const loadGames = async () => {
        setLoading(true);
        try {
            const gamesSnapshot = await getDocs(collection(db, 'games'));

            if (gamesSnapshot.empty) {
                // Initialize with default games
                await initializeGames();
                setGames(defaultGames);
            } else {
                const gamesList: Game[] = [];
                const existingGameIds: string[] = [];

                gamesSnapshot.forEach((doc) => {
                    const data = doc.data();
                    existingGameIds.push(doc.id);
                    gamesList.push({
                        id: doc.id,
                        name: data.name,
                        isPremium: data.isPremium ?? false,
                        isActive: data.isActive ?? true,
                    });
                });

                // Check for missing games and add them
                const missingGames = defaultGames.filter(
                    game => !existingGameIds.includes(game.id)
                );

                if (missingGames.length > 0) {
                    for (const game of missingGames) {
                        await setDoc(doc(db, 'games', game.id), {
                            name: game.name,
                            isPremium: game.isPremium,
                            isActive: game.isActive,
                        });
                        gamesList.push(game);
                    }
                    setSuccess(`Added ${missingGames.length} new game(s)!`);
                }

                setGames(gamesList);
            }
        } catch (e: any) {
            setError(e.message);
        } finally {
            setLoading(false);
        }
    };

    const initializeGames = async () => {
        try {
            for (const game of defaultGames) {
                await setDoc(doc(db, 'games', game.id), {
                    name: game.name,
                    isPremium: game.isPremium,
                    isActive: game.isActive,
                });
            }
            setSuccess('Games initialized successfully!');
        } catch (e: any) {
            setError(e.message);
        }
    };

    const togglePremium = async (gameId: string, currentValue: boolean) => {
        try {
            await updateDoc(doc(db, 'games', gameId), {
                isPremium: !currentValue,
            });
            setSuccess(`Game ${!currentValue ? 'marked as premium' : 'marked as free'}!`);
            await loadGames();
        } catch (e: any) {
            setError(e.message);
        }
    };

    const toggleActive = async (gameId: string, currentValue: boolean) => {
        try {
            await updateDoc(doc(db, 'games', gameId), {
                isActive: !currentValue,
            });
            setSuccess(`Game ${!currentValue ? 'activated' : 'deactivated'}!`);
            await loadGames();
        } catch (e: any) {
            setError(e.message);
        }
    };

    const getGameIcon = (gameId: string) => {
        const icons: { [key: string]: string } = {
            'truth_or_truth': '💕',
            'love_language_quiz': '👥',
            'reflection_game': '💡',
            'couples_challenge': '🎉',
            'would_you_rather': '❓',
            'date_night_ideas': '🍽️',
            'relationship_quiz': '📝',
            'compliment_game': '🎁',
        };
        return icons[gameId] || '🎮';
    };

    const getGameColor = (gameId: string) => {
        const colors: { [key: string]: string } = {
            'truth_or_truth': '#FF4D8D',
            'love_language_quiz': '#B388FF',
            'reflection_game': '#4CAF50',
            'couples_challenge': '#FF9800',
            'would_you_rather': '#673AB7',
            'date_night_ideas': '#E91E63',
            'relationship_quiz': '#00BCD4',
            'compliment_game': '#9C27B0',
        };
        return colors[gameId] || '#8B42FF';
    };

    if (loading) {
        return <SkeletonLoader type="card" count={6} />;
    }

    return (
        <Box>
            <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" alignItems={{ xs: 'stretch', sm: 'center' }} spacing={2} sx={{ mb: 4 }}>
                <Typography variant="h5" sx={{ fontWeight: 'bold' }}>Games Management</Typography>
                <Button
                    variant="outlined"
                    startIcon={<Refresh />}
                    onClick={loadGames}
                    sx={{ alignSelf: { xs: 'flex-start', sm: 'center' } }}
                >
                    Refresh
                </Button>
            </Stack>

            {success && <Alert severity="success" onClose={() => setSuccess(null)} sx={{ mb: 3 }}>{success}</Alert>}
            {error && <Alert severity="error" onClose={() => setError(null)} sx={{ mb: 3 }}>{error}</Alert>}

            <Grid container spacing={3}>
                {games.map((game) => (
                    <Grid item xs={12} md={6} lg={4} key={game.id}>
                        <Paper
                            sx={{
                                borderRadius: 3,
                                overflow: 'hidden',
                                boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
                            }}
                        >
                            {/* Game Header */}
                            <Box
                                sx={{
                                    height: 150,
                                    background: getGameColor(game.id),
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    fontSize: '64px',
                                }}
                            >
                                {getGameIcon(game.id)}
                            </Box>

                            {/* Game Details */}
                            <Box sx={{ p: 3 }}>
                                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 3 }}>
                                    <Typography variant="h6" sx={{ fontWeight: 'bold', flex: 1 }}>
                                        {game.name}
                                    </Typography>
                                    <Box sx={{ display: 'flex', gap: 1 }}>
                                        {game.isPremium && (
                                            <Chip
                                                label="Premium"
                                                size="small"
                                                sx={{
                                                    bgcolor: '#FFD700',
                                                    color: '#000',
                                                    fontWeight: 'bold',
                                                    fontSize: '11px',
                                                }}
                                            />
                                        )}
                                        {!game.isActive && (
                                            <Chip
                                                label="Inactive"
                                                size="small"
                                                color="error"
                                                sx={{ fontSize: '11px' }}
                                            />
                                        )}
                                    </Box>
                                </Box>

                                <Box
                                    sx={{
                                        pt: 2,
                                        borderTop: '1px solid',
                                        borderColor: 'grey.200',
                                        display: 'flex',
                                        flexDirection: 'column',
                                        gap: 1,
                                    }}
                                >
                                    <FormControlLabel
                                        control={
                                            <Switch
                                                checked={game.isPremium}
                                                onChange={() => togglePremium(game.id, game.isPremium)}
                                                color="warning"
                                            />
                                        }
                                        label={
                                            <Typography variant="body2">
                                                Premium Game
                                            </Typography>
                                        }
                                    />
                                    <FormControlLabel
                                        control={
                                            <Switch
                                                checked={game.isActive}
                                                onChange={() => toggleActive(game.id, game.isActive)}
                                                color="primary"
                                            />
                                        }
                                        label={
                                            <Typography variant="body2">
                                                Active
                                            </Typography>
                                        }
                                    />
                                </Box>
                            </Box>
                        </Paper>
                    </Grid>
                ))}
            </Grid>

            {games.length === 0 && (
                <Box sx={{ textAlign: 'center', py: 8 }}>
                    <Typography variant="h6" color="text.secondary">
                        No games found
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                        Click refresh to initialize games
                    </Typography>
                </Box>
            )}
        </Box>
    );
};

export default GamesPage;
