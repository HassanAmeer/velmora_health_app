import React, { useState, useEffect } from 'react';
import {
    Box, Typography, Paper, Grid, Alert,
    Switch, FormControlLabel, Chip, Button, Stack
} from '@mui/material';
import { Refresh } from '@mui/icons-material';
import { collection, getDocs, doc, updateDoc, setDoc } from 'firebase/firestore';
import { db } from '../../services/firebase';
import SkeletonLoader from '../../components/Layout/SkeletonLoader';

interface KegelExercise {
    id: string;
    name: string;
    duration: number;
    sets: number;
    isPremium: boolean;
    isActive: boolean;
}

// Default kegel exercises that match the app
const defaultExercises: KegelExercise[] = [
    {
        id: 'beginner',
        name: 'Beginner Routine',
        duration: 5,
        sets: 3,
        isPremium: false,
        isActive: true,
    },
    {
        id: 'intermediate',
        name: 'Intermediate Routine',
        duration: 10,
        sets: 5,
        isPremium: false,
        isActive: true,
    },
    {
        id: 'advanced',
        name: 'Advanced Routine',
        duration: 15,
        sets: 7,
        isPremium: false,
        isActive: true,
    },
];

const KegelPage: React.FC = () => {
    const [exercises, setExercises] = useState<KegelExercise[]>([]);
    const [loading, setLoading] = useState(true);
    const [success, setSuccess] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        loadExercises();
    }, []);

    const loadExercises = async () => {
        setLoading(true);
        try {
            const exercisesSnapshot = await getDocs(collection(db, 'kegel_exercises'));

            if (exercisesSnapshot.empty) {
                // Initialize with default exercises
                await initializeExercises();
                setExercises(defaultExercises);
            } else {
                const exercisesList: KegelExercise[] = [];
                const existingExerciseIds: string[] = [];

                exercisesSnapshot.forEach((doc) => {
                    const data = doc.data();
                    existingExerciseIds.push(doc.id);
                    exercisesList.push({
                        id: doc.id,
                        name: data.name,
                        duration: data.duration,
                        sets: data.sets,
                        isPremium: data.isPremium ?? false,
                        isActive: data.isActive ?? true,
                    });
                });

                // Check for missing exercises and add them
                const missingExercises = defaultExercises.filter(
                    exercise => !existingExerciseIds.includes(exercise.id)
                );

                if (missingExercises.length > 0) {
                    for (const exercise of missingExercises) {
                        await setDoc(doc(db, 'kegel_exercises', exercise.id), {
                            name: exercise.name,
                            duration: exercise.duration,
                            sets: exercise.sets,
                            isPremium: exercise.isPremium,
                            isActive: exercise.isActive,
                        });
                        exercisesList.push(exercise);
                    }
                    setSuccess(`Added ${missingExercises.length} new exercise(s)!`);
                }

                setExercises(exercisesList);
            }
        } catch (e: any) {
            setError(e.message);
        } finally {
            setLoading(false);
        }
    };

    const initializeExercises = async () => {
        try {
            for (const exercise of defaultExercises) {
                await setDoc(doc(db, 'kegel_exercises', exercise.id), {
                    name: exercise.name,
                    duration: exercise.duration,
                    sets: exercise.sets,
                    isPremium: exercise.isPremium,
                    isActive: exercise.isActive,
                });
            }
            setSuccess('Kegel exercises initialized successfully!');
        } catch (e: any) {
            setError(e.message);
        }
    };

    const togglePremium = async (exerciseId: string, currentValue: boolean) => {
        try {
            await updateDoc(doc(db, 'kegel_exercises', exerciseId), {
                isPremium: !currentValue,
            });
            setSuccess(`Exercise ${!currentValue ? 'marked as premium' : 'marked as free'}!`);
            await loadExercises();
        } catch (e: any) {
            setError(e.message);
        }
    };

    const toggleActive = async (exerciseId: string, currentValue: boolean) => {
        try {
            await updateDoc(doc(db, 'kegel_exercises', exerciseId), {
                isActive: !currentValue,
            });
            setSuccess(`Exercise ${!currentValue ? 'activated' : 'deactivated'}!`);
            await loadExercises();
        } catch (e: any) {
            setError(e.message);
        }
    };

    const getExerciseIcon = (exerciseId: string) => {
        const icons: { [key: string]: string } = {
            'beginner': '🌱',
            'intermediate': '💪',
            'advanced': '🔥',
        };
        return icons[exerciseId] || '⚡';
    };

    const getExerciseColor = (exerciseId: string) => {
        const colors: { [key: string]: string } = {
            'beginner': '#4CAF50',
            'intermediate': '#9B67FF',
            'advanced': '#FF4D8D',
        };
        return colors[exerciseId] || '#6B26FF';
    };

    if (loading) {
        return <SkeletonLoader type="card" count={6} />;
    }

    return (
        <Box>
            <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" alignItems={{ xs: 'stretch', sm: 'center' }} spacing={2} sx={{ mb: 4 }}>
                <Typography variant="h5" sx={{ fontWeight: 'bold' }}>Kegel Exercises Management</Typography>
                <Button
                    variant="outlined"
                    startIcon={<Refresh />}
                    onClick={loadExercises}
                    sx={{ alignSelf: { xs: 'flex-start', sm: 'center' } }}
                >
                    Refresh
                </Button>
            </Stack>

            {success && <Alert severity="success" onClose={() => setSuccess(null)} sx={{ mb: 3 }}>{success}</Alert>}
            {error && <Alert severity="error" onClose={() => setError(null)} sx={{ mb: 3 }}>{error}</Alert>}

            <Grid container spacing={3}>
                {exercises.map((exercise) => (
                    <Grid item xs={12} md={6} lg={4} key={exercise.id}>
                        <Paper
                            sx={{
                                borderRadius: 3,
                                overflow: 'hidden',
                                boxShadow: '0 4px 12px rgba(0,0,0,0.08)',
                            }}
                        >
                            {/* Exercise Header */}
                            <Box
                                sx={{
                                    height: 150,
                                    background: getExerciseColor(exercise.id),
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    fontSize: '64px',
                                }}
                            >
                                {getExerciseIcon(exercise.id)}
                            </Box>

                            {/* Exercise Details */}
                            <Box sx={{ p: 3 }}>
                                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 3 }}>
                                    <Typography variant="h6" sx={{ fontWeight: 'bold', flex: 1 }}>
                                        {exercise.name}
                                    </Typography>
                                    <Box sx={{ display: 'flex', gap: 1 }}>
                                        {exercise.isPremium && (
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
                                        {!exercise.isActive && (
                                            <Chip
                                                label="Inactive"
                                                size="small"
                                                color="error"
                                                sx={{ fontSize: '11px' }}
                                            />
                                        )}
                                    </Box>
                                </Box>

                                <Box sx={{ mb: 2 }}>
                                    <Typography variant="body2" color="text.secondary">
                                        Duration: {exercise.duration} minutes
                                    </Typography>
                                    <Typography variant="body2" color="text.secondary">
                                        Sets: {exercise.sets}
                                    </Typography>
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
                                                checked={exercise.isPremium}
                                                onChange={() => togglePremium(exercise.id, exercise.isPremium)}
                                                color="warning"
                                            />
                                        }
                                        label={
                                            <Typography variant="body2">
                                                Premium Exercise
                                            </Typography>
                                        }
                                    />
                                    <FormControlLabel
                                        control={
                                            <Switch
                                                checked={exercise.isActive}
                                                onChange={() => toggleActive(exercise.id, exercise.isActive)}
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

            {exercises.length === 0 && (
                <Box sx={{ textAlign: 'center', py: 8 }}>
                    <Typography variant="h6" color="text.secondary">
                        No exercises found
                    </Typography>
                    <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                        Click refresh to initialize exercises
                    </Typography>
                </Box>
            )}
        </Box>
    );
};

export default KegelPage;
