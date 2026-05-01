import React, { useState, useEffect } from 'react';
import {
    Box,
    Typography,
    Paper,
    Grid,
    Avatar,
    Divider,
    Button,
    Card,
    CardContent,
    Chip,
    IconButton,
    Breadcrumbs,
    Link,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    TextField,
    Alert,
    MenuItem,
    Select,
    FormControl,
    InputLabel,
    Stack
} from '@mui/material';
import {
    ArrowBack,
    Mail,
    CalendarToday,
    Language,
    VerifiedUser,
    History,
    Edit,
    Block,
    Delete,
    CheckCircle,
    Close,
    Save,
    Stars,
    Apple,
    Google,
    Email
} from '@mui/icons-material';
import { useParams, useNavigate, Link as RouterLink } from 'react-router-dom';
import { userService, UserProfile } from '../../services/userService';
import SkeletonLoader from '../../components/Layout/SkeletonLoader';

const UserDetailsPage: React.FC = () => {
    const { uid } = useParams<{ uid: string }>();
    const [user, setUser] = useState<UserProfile | null>(null);
    const [loading, setLoading] = useState(true);
    const [editDialogOpen, setEditDialogOpen] = useState(false);
    const [banDialogOpen, setBanDialogOpen] = useState(false);
    const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
    const [subscriptionEditMode, setSubscriptionEditMode] = useState(false);
    const [tempSubscription, setTempSubscription] = useState({
        plan: 'free',
        expiryDate: ''
    });
    const [editForm, setEditForm] = useState({
        displayName: '',
        password: '',
        subscriptionStatus: 'free' as 'free' | 'premium' | 'trial',
        subscriptionType: '',
        subscriptionExpiryDate: ''
    });
    const [success, setSuccess] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const navigate = useNavigate();

    useEffect(() => {
        const fetchUser = async () => {
            if (!uid) return;
            try {
                const data = await userService.getUserById(uid);
                if (!data) {
                    setLoading(false);
                    return;
                }
                setUser(data);

                setEditForm({
                    displayName: data.displayName || '',
                    password: data.password || '',
                    subscriptionStatus: (data.subscriptionStatus === 'trial' ? 'trial' : data.subscriptionStatus) as 'free' | 'premium' | 'trial',
                    subscriptionType: data.subscriptionType || '',
                    subscriptionExpiryDate: data.subscriptionExpiryDate?.seconds
                        ? new Date(data.subscriptionExpiryDate.seconds * 1000).toISOString().split('T')[0]
                        : data.trialEndTime?.seconds
                            ? new Date(data.trialEndTime.seconds * 1000).toISOString().split('T')[0]
                            : ''
                });
            } catch (error) {
                console.error('Error fetching user details:', error);
            } finally {
                setLoading(false);
            }
        };
        fetchUser();
    }, [uid]);

    const handleEditOpen = () => {
        setEditDialogOpen(true);
    };

    const handleEditClose = () => {
        setEditDialogOpen(false);
        setError(null);
    };

    const handleEditSave = async () => {
        if (!uid) return;
        try {
            const updateData: any = {
                displayName: editForm.displayName,
                password: editForm.password,
                subscriptionStatus: editForm.subscriptionStatus,
            };

            // Update subscription fields based on status
            if (editForm.subscriptionStatus === 'premium') {
                updateData.isPremium = true;
                updateData.subscriptionType = editForm.subscriptionType;
                if (editForm.subscriptionExpiryDate) {
                    updateData.subscriptionExpiryDate = new Date(editForm.subscriptionExpiryDate);
                }
            } else if (editForm.subscriptionStatus === 'trial') {
                updateData.isPremium = false;
                updateData.subscriptionType = editForm.subscriptionType || 'velmora_trial_48h';
                if (editForm.subscriptionExpiryDate) {
                    updateData.trialEndTime = new Date(editForm.subscriptionExpiryDate);
                }
            } else {
                updateData.isPremium = false;
                updateData.subscriptionType = '';
                updateData.subscriptionExpiryDate = null;
                updateData.trialStartTime = null;
                updateData.trialEndTime = null;
            }

            await userService.updateUser(uid, updateData);
            setSuccess('User updated successfully!');
            setEditDialogOpen(false);
            // Refresh user data
            const data = await userService.getUserById(uid);
            setUser(data);
        } catch (err: any) {
            setError(err.message || 'Failed to update user');
        }
    };

    const handleBanToggle = async () => {
        if (!uid || !user) return;
        try {
            const newBanStatus = !user.isBanned;
            await userService.updateUser(uid, { isBanned: newBanStatus });
            setSuccess(newBanStatus ? 'User banned successfully!' : 'User unbanned successfully!');
            setBanDialogOpen(false);
            // Refresh user data
            const data = await userService.getUserById(uid);
            setUser(data);
        } catch (err: any) {
            setError(err.message || 'Failed to update ban status');
        }
    };

    const handleDeleteConfirm = async () => {
        if (!uid) return;
        try {
            await userService.deleteUser(uid);
            setSuccess('User deleted successfully!');
            setTimeout(() => navigate('/users'), 1500);
        } catch (err: any) {
            setError(err.message || 'Failed to delete user');
        }
    };

    const handleSubscriptionEdit = () => {
        setSubscriptionEditMode(true);
        setTempSubscription({
            plan: user?.subscriptionStatus === 'free' ? 'free' : user?.subscriptionType || 'free',
            expiryDate: user?.subscriptionExpiryDate?.seconds
                ? new Date(user.subscriptionExpiryDate.seconds * 1000).toISOString().split('T')[0]
                : user?.trialEndTime?.seconds
                    ? new Date(user.trialEndTime.seconds * 1000).toISOString().split('T')[0]
                    : ''
        });
    };

    const handleSubscriptionCancel = () => {
        setSubscriptionEditMode(false);
        setTempSubscription({ plan: 'free', expiryDate: '' });
    };

    const handleSubscriptionSave = async () => {
        if (!uid) return;
        try {
            const value = tempSubscription.plan;
            let expiryDate = null;
            let subscriptionStatus = 'free';
            let subscriptionType = '';
            let isPremium = false;

            if (value === 'velmora_trial_48h') {
                // 48-hour trial
                subscriptionStatus = 'trial';
                subscriptionType = value;
                isPremium = false;

                // Use manual date or auto-calculate 48 hours
                if (tempSubscription.expiryDate) {
                    expiryDate = new Date(tempSubscription.expiryDate);
                } else {
                    const now = new Date();
                    expiryDate = new Date(now.getTime() + 48 * 60 * 60 * 1000);
                }
            } else if (value !== 'free') {
                // Premium plans
                subscriptionStatus = 'premium';
                subscriptionType = value;
                isPremium = true;

                // Use manual date or auto-calculate
                if (tempSubscription.expiryDate) {
                    expiryDate = new Date(tempSubscription.expiryDate);
                } else {
                    const now = new Date();
                    if (value === 'velmora_premium_monthly') {
                        expiryDate = new Date(now.setMonth(now.getMonth() + 1));
                    } else if (value === 'velmora_premium_quarterly') {
                        expiryDate = new Date(now.setMonth(now.getMonth() + 3));
                    } else if (value === 'velmora_premium_yearly') {
                        expiryDate = new Date(now.setFullYear(now.getFullYear() + 1));
                    }
                }
            }

            const updateData: any = {
                subscriptionStatus,
                subscriptionType,
                isPremium,
            };

            if (value === 'velmora_trial_48h') {
                updateData.trialStartTime = new Date();
                updateData.trialEndTime = expiryDate;
                updateData.hasUsed48HourTrial = false; // Admin can reset trial
            } else if (value !== 'free') {
                updateData.subscriptionExpiryDate = expiryDate;
            } else {
                updateData.subscriptionExpiryDate = null;
                updateData.trialStartTime = null;
                updateData.trialEndTime = null;
            }

            await userService.updateUser(uid, updateData);
            setSuccess('Subscription updated successfully!');
            setSubscriptionEditMode(false);
            const data = await userService.getUserById(uid);
            setUser(data);
        } catch (err: any) {
            setError(err.message || 'Failed to update subscription');
        }
    };

    if (loading) {
        return <SkeletonLoader type="details" />;
    }

    if (!user) {
        return (
            <Box sx={{ p: { xs: 2, sm: 4 }, textAlign: 'center' }}>
                <Typography variant="h6" color="error">User not found</Typography>
                <Button onClick={() => navigate('/users')} startIcon={<ArrowBack />} sx={{ mt: 2 }}>
                    Back to Users
                </Button>
            </Box>
        );
    }

    return (
        <Box>
            {success && <Alert severity="success" onClose={() => setSuccess(null)} sx={{ mb: 3 }}>{success}</Alert>}
            {error && <Alert severity="error" onClose={() => setError(null)} sx={{ mb: 3 }}>{error}</Alert>}

            <Box sx={{ mb: 3 }}>
                <Breadcrumbs sx={{ mb: 2 }}>
                    <Link component={RouterLink} underline="hover" color="inherit" to="/">Dashboard</Link>
                    <Link component={RouterLink} underline="hover" color="inherit" to="/users">Users</Link>
                    <Typography color="text.primary">Details</Typography>
                </Breadcrumbs>

                <Stack direction={{ xs: 'column', sm: 'row' }} alignItems={{ xs: 'flex-start', sm: 'center' }} spacing={1.5}>
                    <IconButton onClick={() => navigate('/users')} size="small">
                        <ArrowBack />
                    </IconButton>
                    <Typography variant="h5" sx={{ fontWeight: 'bold' }}>User Details</Typography>
                    {user?.isBanned && (
                        <Chip label="BANNED" color="error" size="small" />
                    )}
                </Stack>
            </Box>

            <Grid container spacing={3}>
                {/* Profile Overview */}
                <Grid item xs={12} md={4}>
                    <Card sx={{ borderRadius: 3, textAlign: 'center', py: 2, height: '100%' }}>
                        <CardContent>
                            <Avatar
                                src={user?.photoURL}
                                sx={{ width: 100, height: 100, mx: 'auto', mb: 2, bgcolor: '#7C3AED', fontSize: '2rem' }}
                            >
                                {user?.displayName?.charAt(0) || user?.email.charAt(0)}
                            </Avatar>
                            <Typography variant="h6" sx={{ fontWeight: 'bold' }}>{user?.displayName || 'Unnamed User'}</Typography>
                            <Typography color="text.secondary">{user?.email}</Typography>
                            <Typography variant="caption" color="text.secondary" sx={{ fontFamily: 'monospace', display: 'block', mb: 1 }}>
                                ID: {user?.uid}
                            </Typography>
                            <Box sx={{ mt: 2 }}>
                                <Chip
                                    label={user?.subscriptionStatus.toUpperCase()}
                                    color={user?.subscriptionStatus === 'premium' ? 'primary' : 'default'}
                                    sx={{ width: 100 }}
                                />
                            </Box>
                        </CardContent>
                        <Divider sx={{ my: 1 }} />
                        <Box sx={{ p: 2, display: 'flex', flexDirection: 'column', gap: 1 }}>
                            <Button fullWidth variant="outlined" startIcon={<Edit />} onClick={handleEditOpen}>
                                Edit Profile
                            </Button>
                            <Button
                                fullWidth
                                variant="outlined"
                                color={user?.isBanned ? 'success' : 'warning'}
                                startIcon={user?.isBanned ? <CheckCircle /> : <Block />}
                                onClick={() => setBanDialogOpen(true)}
                            >
                                {user?.isBanned ? 'Unban User' : 'Ban User'}
                            </Button>
                            <Button
                                fullWidth
                                variant="outlined"
                                color="error"
                                startIcon={<Delete />}
                                onClick={() => setDeleteDialogOpen(true)}
                            >
                                Delete Account
                            </Button>
                        </Box>
                    </Card>
                </Grid>

                {/* User Stats & Info */}
                <Grid item xs={12} md={8}>
                    <Grid container spacing={3} alignItems="stretch">
                        <Grid item xs={12}>
                            <Paper sx={{ p: 3, borderRadius: 3 }}>
                                <Typography variant="h6" gutterBottom sx={{ fontWeight: '600' }}>Account Information</Typography>
                                <Grid container spacing={2}>
                                    <Grid item xs={12} sm={6}>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                                            <Mail color="action" />
                                            <Box>
                                                <Typography variant="caption" color="text.secondary">Email Address</Typography>
                                                <Typography variant="body2">{user.email}</Typography>
                                            </Box>
                                        </Box>
                                    </Grid>
                                    <Grid item xs={12} sm={6}>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                                            <VerifiedUser color="action" />
                                            <Box>
                                                <Typography variant="caption" color="text.secondary">User ID</Typography>
                                                <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>{user.uid}</Typography>
                                            </Box>
                                        </Box>
                                    </Grid>
                                    <Grid item xs={12} sm={6}>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                                            <CalendarToday color="action" />
                                            <Box>
                                                <Typography variant="caption" color="text.secondary">Member Since</Typography>
                                                <Typography variant="body2">
                                                    {user.createdAt?.seconds ? new Date(user.createdAt.seconds * 1000).toLocaleDateString() : 'N/A'}
                                                </Typography>
                                            </Box>
                                        </Box>
                                    </Grid>
                                    <Grid item xs={12} sm={6}>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                                            <Language color="action" />
                                            <Box>
                                                <Typography variant="caption" color="text.secondary">Preferred Language</Typography>
                                                <Typography variant="body2">{user.preferredLanguage.toUpperCase()}</Typography>
                                            </Box>
                                        </Box>
                                    </Grid>
                                    <Grid item xs={12} sm={6}>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                                            {user.authProvider === 'google' ? <Google color="action" /> :
                                                user.authProvider === 'apple' ? <Apple color="action" /> :
                                                    <Email color="action" />}
                                            <Box>
                                                <Typography variant="caption" color="text.secondary">Auth Provider</Typography>
                                                <Typography variant="body2">{user.authProvider?.toUpperCase() || 'EMAIL'}</Typography>
                                            </Box>
                                        </Box>
                                    </Grid>
                                    <Grid item xs={12} sm={6}>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                                            <History color="action" />
                                            <Box>
                                                <Typography variant="caption" color="text.secondary">Last Login</Typography>
                                                <Typography variant="body2">
                                                    {user.lastLoginAt?.seconds ? new Date(user.lastLoginAt.seconds * 1000).toLocaleString() : 'N/A'}
                                                </Typography>
                                            </Box>
                                        </Box>
                                    </Grid>
                                </Grid>
                            </Paper>
                        </Grid>

                        <Grid item xs={12}>
                            <Paper sx={{ p: 3, borderRadius: 3, position: 'relative' }}>
                                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                        <Stars color="primary" />
                                        <Typography variant="h6" sx={{ fontWeight: '600' }}>Subscription Management</Typography>
                                    </Box>
                                    {!subscriptionEditMode && (
                                        <IconButton size="small" onClick={handleSubscriptionEdit} color="primary">
                                            <Edit fontSize="small" />
                                        </IconButton>
                                    )}
                                </Box>
                                <Grid container spacing={2}>
                                    <Grid item xs={12} sm={6}>
                                        <FormControl fullWidth disabled={!subscriptionEditMode}>
                                            <InputLabel>Subscription Plan</InputLabel>
                                            <Select
                                                value={subscriptionEditMode ? tempSubscription.plan : (user.subscriptionStatus === 'free' ? 'free' : user.subscriptionType || 'free')}
                                                label="Subscription Plan"
                                                onChange={(e) => {
                                                    const value = e.target.value;
                                                    let autoExpiryDate = '';

                                                    if (value === 'velmora_trial_48h') {
                                                        // 48 hours from now
                                                        const now = new Date();
                                                        autoExpiryDate = new Date(now.getTime() + 48 * 60 * 60 * 1000).toISOString().split('T')[0];
                                                    } else if (value !== 'free') {
                                                        const now = new Date();
                                                        if (value === 'velmora_premium_monthly') {
                                                            autoExpiryDate = new Date(now.setMonth(now.getMonth() + 1)).toISOString().split('T')[0];
                                                        } else if (value === 'velmora_premium_quarterly') {
                                                            autoExpiryDate = new Date(now.setMonth(now.getMonth() + 3)).toISOString().split('T')[0];
                                                        } else if (value === 'velmora_premium_yearly') {
                                                            autoExpiryDate = new Date(now.setFullYear(now.getFullYear() + 1)).toISOString().split('T')[0];
                                                        }
                                                    }

                                                    setTempSubscription({
                                                        plan: value,
                                                        expiryDate: autoExpiryDate
                                                    });
                                                }}
                                            >
                                                <MenuItem value="free">Free Plan</MenuItem>
                                                <MenuItem value="velmora_trial_48h">48-Hour Trial</MenuItem>
                                                <MenuItem value="velmora_premium_monthly">Monthly Plan</MenuItem>
                                                <MenuItem value="velmora_premium_quarterly">Quarterly Plan</MenuItem>
                                                <MenuItem value="velmora_premium_yearly">Yearly Plan</MenuItem>
                                            </Select>
                                        </FormControl>
                                    </Grid>
                                    {(subscriptionEditMode ? tempSubscription.plan !== 'free' : user.subscriptionStatus === 'premium' || user.subscriptionStatus === 'trial') && (
                                        <Grid item xs={12} sm={6}>
                                            <TextField
                                                fullWidth
                                                label="Expiry Date"
                                                type="date"
                                                value={subscriptionEditMode ? tempSubscription.expiryDate : (user.subscriptionExpiryDate?.seconds
                                                    ? new Date(user.subscriptionExpiryDate.seconds * 1000).toISOString().split('T')[0]
                                                    : user.trialEndTime?.seconds
                                                        ? new Date(user.trialEndTime.seconds * 1000).toISOString().split('T')[0]
                                                        : '')}
                                                onChange={(e) => setTempSubscription({ ...tempSubscription, expiryDate: e.target.value })}
                                                InputLabelProps={{ shrink: true }}
                                                disabled={!subscriptionEditMode}
                                                helperText={subscriptionEditMode ? "Auto-filled based on plan, you can modify" : "Plan expiry date"}
                                            />
                                        </Grid>
                                    )}
                                </Grid>
                                {subscriptionEditMode && (
                                    <Box sx={{ display: 'flex', gap: 1, mt: 2, justifyContent: 'flex-end' }}>
                                        <Button
                                            variant="outlined"
                                            startIcon={<Close />}
                                            onClick={handleSubscriptionCancel}
                                            size="small"
                                        >
                                            Cancel
                                        </Button>
                                        <Button
                                            variant="contained"
                                            startIcon={<Save />}
                                            onClick={handleSubscriptionSave}
                                            size="small"
                                        >
                                            Save
                                        </Button>
                                    </Box>
                                )}
                            </Paper>
                        </Grid>

                        <Grid item xs={12}>
                            <Paper sx={{ p: 3, borderRadius: 3 }}>
                                <Typography variant="h6" gutterBottom sx={{ fontWeight: '600' }}>Subscription Details</Typography>
                                <Grid container spacing={2}>
                                    <Grid item xs={12} sm={6}>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                                            <CheckCircle color="action" />
                                            <Box>
                                                <Typography variant="caption" color="text.secondary">Plan Type</Typography>
                                                <Typography variant="body2">
                                                    {user.subscriptionStatus === 'premium' ? 'Premium' : user.subscriptionStatus === 'trial' ? 'Trial' : 'Free'}
                                                </Typography>
                                            </Box>
                                        </Box>
                                    </Grid>
                                    {user.subscriptionType && (
                                        <Grid item xs={12} sm={6}>
                                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                                                <CalendarToday color="action" />
                                                <Box>
                                                    <Typography variant="caption" color="text.secondary">Subscription Period</Typography>
                                                    <Typography variant="body2">
                                                        {user.subscriptionType.includes('monthly') ? 'Monthly' :
                                                            user.subscriptionType.includes('quarterly') ? 'Quarterly' :
                                                                user.subscriptionType.includes('yearly') ? 'Yearly' :
                                                                    user.subscriptionType.includes('trial') ? '48-Hour Trial' : 'N/A'}
                                                    </Typography>
                                                </Box>
                                            </Box>
                                        </Grid>
                                    )}
                                    {(user.subscriptionExpiryDate?.seconds || user.trialEndTime?.seconds) && (
                                        <Grid item xs={12} sm={6}>
                                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 2 }}>
                                                <History color="action" />
                                                <Box>
                                                    <Typography variant="caption" color="text.secondary">Expiry Date</Typography>
                                                    <Typography variant="body2">
                                                        {user.subscriptionExpiryDate?.seconds
                                                            ? new Date(user.subscriptionExpiryDate.seconds * 1000).toLocaleDateString()
                                                            : new Date(user.trialEndTime.seconds * 1000).toLocaleDateString()}
                                                    </Typography>
                                                </Box>
                                            </Box>
                                        </Grid>
                                    )}
                                    {user.cancellationRequested && (
                                        <Grid item xs={12}>
                                            <Alert severity="warning" sx={{ mt: 1 }}>
                                                <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                                                    <Box>
                                                        <Typography variant="body2" fontWeight="600">Cancellation Requested</Typography>
                                                        <Typography variant="caption">
                                                            {user.cancellationRequestedAt?.seconds
                                                                ? `Requested on ${new Date(user.cancellationRequestedAt.seconds * 1000).toLocaleString()}`
                                                                : 'Pending review'}
                                                        </Typography>
                                                    </Box>
                                                    <Button
                                                        size="small"
                                                        variant="outlined"
                                                        onClick={async () => {
                                                            try {
                                                                await userService.updateUser(user.uid, {
                                                                    cancellationRequested: false,
                                                                    cancellationRequestedAt: null
                                                                });
                                                                setSuccess('Cancellation request cleared');
                                                                const data = await userService.getUserById(user.uid);
                                                                setUser(data);
                                                            } catch (err: any) {
                                                                setError(err.message || 'Failed to clear request');
                                                            }
                                                        }}
                                                    >
                                                        Clear Request
                                                    </Button>
                                                </Box>
                                            </Alert>
                                        </Grid>
                                    )}
                                </Grid>
                            </Paper>
                        </Grid>

                        <Grid item xs={12}>
                            <Paper sx={{ p: 3, borderRadius: 3 }}>
                                <Typography variant="h6" gutterBottom sx={{ fontWeight: '600' }}>Features Access</Typography>
                                <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                                    {user.subscriptionStatus === 'premium' || user.subscriptionStatus === 'trial' ? (
                                        <>
                                            <Chip
                                                icon={<VerifiedUser />}
                                                label="Kegel Exercises"
                                                color="success"
                                                variant="outlined"
                                            />
                                            <Chip
                                                icon={<VerifiedUser />}
                                                label="Games"
                                                color="success"
                                                variant="outlined"
                                            />
                                            <Chip
                                                icon={<VerifiedUser />}
                                                label="Chat"
                                                color="success"
                                                variant="outlined"
                                            />
                                            {user.subscriptionStatus === 'trial' && (
                                                <Chip
                                                    label="48h Access"
                                                    color="warning"
                                                    variant="outlined"
                                                />
                                            )}
                                        </>
                                    ) : (
                                        <>
                                            <Chip
                                                icon={<VerifiedUser />}
                                                label="Some Games"
                                                color="default"
                                                variant="outlined"
                                            />
                                            <Chip
                                                icon={<VerifiedUser />}
                                                label="Some Kegel Exercises"
                                                color="default"
                                                variant="outlined"
                                            />
                                        </>
                                    )}
                                </Box>
                            </Paper>
                        </Grid>
                    </Grid>
                </Grid>
            </Grid>

            {/* Edit Dialog */}
            <Dialog open={editDialogOpen} onClose={handleEditClose} maxWidth="sm" fullWidth>
                <DialogTitle>Edit User Profile</DialogTitle>
                <DialogContent>
                    <TextField
                        fullWidth
                        label="Display Name"
                        value={editForm.displayName}
                        onChange={(e) => setEditForm({ ...editForm, displayName: e.target.value })}
                        sx={{ mt: 2, mb: 2 }}
                    />
                    <TextField
                        fullWidth
                        label="Password"
                        value={editForm.password}
                        onChange={(e) => setEditForm({ ...editForm, password: e.target.value })}
                        sx={{ mb: 2 }}
                        helperText="Update the user's password in the database."
                    />
                    <FormControl fullWidth sx={{ mb: 2 }}>
                        <InputLabel>Subscription Plan</InputLabel>
                        <Select
                            value={editForm.subscriptionStatus === 'free' ? 'free' : editForm.subscriptionType || 'free'}
                            label="Subscription Plan"
                            onChange={(e) => {
                                const value = e.target.value;
                                if (value === 'free') {
                                    setEditForm({
                                        ...editForm,
                                        subscriptionStatus: 'free',
                                        subscriptionType: '',
                                        subscriptionExpiryDate: ''
                                    });
                                } else if (value === 'velmora_trial_48h') {
                                    setEditForm({
                                        ...editForm,
                                        subscriptionStatus: 'trial',
                                        subscriptionType: value
                                    });
                                } else {
                                    setEditForm({
                                        ...editForm,
                                        subscriptionStatus: 'premium',
                                        subscriptionType: value
                                    });
                                }
                            }}
                        >
                            <MenuItem value="free">Free Plan</MenuItem>
                            <MenuItem value="velmora_trial_48h">48-Hour Trial</MenuItem>
                            <MenuItem value="velmora_premium_monthly">Monthly Plan</MenuItem>
                            <MenuItem value="velmora_premium_quarterly">Quarterly Plan</MenuItem>
                            <MenuItem value="velmora_premium_yearly">Yearly Plan</MenuItem>
                        </Select>
                    </FormControl>
                    {(editForm.subscriptionStatus === 'premium' || editForm.subscriptionStatus === 'trial') && (
                        <TextField
                            fullWidth
                            label="Expiry Date"
                            type="date"
                            value={editForm.subscriptionExpiryDate}
                            onChange={(e) => setEditForm({ ...editForm, subscriptionExpiryDate: e.target.value })}
                            InputLabelProps={{ shrink: true }}
                            sx={{ mb: 2 }}
                            helperText={`Set the ${editForm.subscriptionStatus} expiry date`}
                        />
                    )}
                </DialogContent>
                <DialogActions>
                    <Button onClick={handleEditClose}>Cancel</Button>
                    <Button onClick={handleEditSave} variant="contained">Save Changes</Button>
                </DialogActions>
            </Dialog>

            {/* Ban/Unban Dialog */}
            <Dialog open={banDialogOpen} onClose={() => setBanDialogOpen(false)} maxWidth="sm" fullWidth>
                <DialogTitle>{user?.isBanned ? 'Unban User' : 'Ban User'}</DialogTitle>
                <DialogContent>
                    <Typography>
                        {user?.isBanned
                            ? 'Are you sure you want to unban this user? They will be able to access their account again.'
                            : 'Are you sure you want to ban this user? They will not be able to log in to their account.'}
                    </Typography>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setBanDialogOpen(false)}>Cancel</Button>
                    <Button onClick={handleBanToggle} variant="contained" color={user?.isBanned ? 'success' : 'warning'}>
                        {user?.isBanned ? 'Unban' : 'Ban'}
                    </Button>
                </DialogActions>
            </Dialog>

            {/* Delete Dialog */}
            <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)} maxWidth="sm" fullWidth>
                <DialogTitle>Delete User Account</DialogTitle>
                <DialogContent>
                    <Alert severity="error" sx={{ mb: 2 }}>
                        This action cannot be undone!
                    </Alert>
                    <Typography>
                        Are you sure you want to delete this user account? All user data will be permanently removed.
                    </Typography>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
                    <Button onClick={handleDeleteConfirm} variant="contained" color="error">
                        Delete Account
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default UserDetailsPage;
