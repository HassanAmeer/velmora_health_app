import React, { useState } from 'react';
import {
    Box,
    Card,
    CardContent,
    TextField,
    Button,
    Typography,
    Alert,
    CircularProgress,
    InputAdornment,
    IconButton,
    Snackbar
} from '@mui/material';
import { LockOutlined, Visibility, VisibilityOff } from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import { useNavigate } from 'react-router-dom';

const LoginPage: React.FC = () => {
    const [email, setEmail] = useState(localStorage.getItem('adminCredentialsEmail') || 'admin@gmail.com');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [loading, setLoading] = useState(false);
    const [toastOpen, setToastOpen] = useState(false);
    const [toastMessage, setToastMessage] = useState('');
    const { login } = useAuth();
    const navigate = useNavigate();

    const showErrorToast = (message: string) => {
        setToastMessage(message);
        setToastOpen(true);
    };

    const handleToastClose = (_event?: React.SyntheticEvent | Event, reason?: string) => {
        if (reason === 'clickaway') return;
        setToastOpen(false);
    };

    const handleLogin = async (e: React.FormEvent) => {
        e.preventDefault();
        e.stopPropagation();
        setLoading(true);

        try {
            await login(email, password);
            navigate('/');
        } catch (err: any) {
            setPassword('');
            showErrorToast('Invalid login credentials. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <Box
            sx={{
                minHeight: '100vh',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                background: 'linear-gradient(135deg, #1E1B4B 0%, #312E81 100%)'
            }}
        >
            {/* Invalid Login Toast */}
            <Snackbar
                open={toastOpen}
                autoHideDuration={5000}
                onClose={handleToastClose}
                anchorOrigin={{ vertical: 'top', horizontal: 'center' }}
            >
                <Alert
                    onClose={handleToastClose}
                    severity="error"
                    variant="filled"
                    sx={{
                        width: '100%',
                        fontWeight: 600,
                        fontSize: '0.9rem',
                        borderRadius: 2,
                        boxShadow: 6
                    }}
                >
                    {toastMessage}
                </Alert>
            </Snackbar>

            <Card sx={{ maxWidth: 400, width: '90%', borderRadius: 3, boxShadow: 10 }}>
                <CardContent sx={{ p: 4, textAlign: 'center' }}>
                    <Box sx={{ mb: 3 }}>
                        <Box
                            sx={{
                                width: 60,
                                height: 60,
                                bgcolor: 'primary.main',
                                borderRadius: '50%',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                                margin: '0 auto',
                                mb: 2
                            }}
                        >
                            <LockOutlined sx={{ color: 'white' }} />
                        </Box>
                        <Typography variant="h5" component="h1" sx={{ fontWeight: 'bold' }}>
                            Velmora Admin
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                            Sign in to manage the Velmora ecosystem
                        </Typography>
                        {/* <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1 }}>
                            Default: admin@gmail.com / 12345678
                        </Typography> */}
                    </Box>

                    <form onSubmit={handleLogin} autoComplete="off">
                        <TextField
                            fullWidth
                            label="Email Address"
                            variant="outlined"
                            margin="normal"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                            type="email"
                            autoComplete="off"
                            inputProps={{ autoComplete: 'off' }}
                        />
                        <TextField
                            fullWidth
                            label="Password"
                            variant="outlined"
                            margin="normal"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                            type={showPassword ? 'text' : 'password'}
                            autoComplete="new-password"
                            inputProps={{ autoComplete: 'new-password' }}
                            InputProps={{
                                endAdornment: (
                                    <InputAdornment position="end">
                                        <IconButton onClick={() => setShowPassword(!showPassword)} edge="end">
                                            {showPassword ? <VisibilityOff /> : <Visibility />}
                                        </IconButton>
                                    </InputAdornment>
                                ),
                            }}
                        />

                        <Button
                            fullWidth
                            type="submit"
                            variant="contained"
                            size="large"
                            disabled={loading}
                            sx={{
                                mt: 4,
                                py: 1.5,
                                fontWeight: 'bold',
                                borderRadius: 2
                            }}
                        >
                            {loading ? <CircularProgress /> : 'Login'}
                        </Button>
                    </form>

                    <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 3 }}>
                        &copy; {new Date().getFullYear()} Velmora AI. All rights reserved.
                    </Typography>
                </CardContent>
            </Card>
        </Box>
    );
};

export default LoginPage;
