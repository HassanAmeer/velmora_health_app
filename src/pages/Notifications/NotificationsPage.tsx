import React, { useState, useEffect } from 'react';
import {
    Box, Typography, TextField, Button, Paper, Grid,
    CircularProgress, Alert, MenuItem, Radio, RadioGroup,
    FormControlLabel, FormControl, FormLabel, Chip, Autocomplete, Stack
} from '@mui/material';
import { Send, Refresh, NotificationsActive } from '@mui/icons-material';
import { collection, getDocs, addDoc, serverTimestamp, query, orderBy, limit } from 'firebase/firestore';
import { db } from '../../services/firebase';
import SkeletonLoader from '../../components/Layout/SkeletonLoader';

interface User {
    uid: string;
    email: string;
    displayName?: string;
}

interface NotificationHistory {
    id: string;
    title: string;
    body: string;
    type: string;
    targetType: string;
    targetUsers?: string[];
    sentAt: any;
    sentBy: string;
    recipientCount?: number;
}

const notificationTypes = [
    { value: 'system', label: 'System', color: '#FFA726' },
    { value: 'kegel', label: 'Kegel Exercise', color: '#EC407A' },
    { value: 'ai_chat', label: 'AI Chat', color: '#7C3AED' },
    { value: 'game', label: 'Game', color: '#FF9800' },
    { value: 'subscription', label: 'Subscription', color: '#66BB6A' },
    { value: 'profile', label: 'Profile', color: '#42A5F5' },
];

const NotificationsPage: React.FC = () => {
    const [title, setTitle] = useState('');
    const [body, setBody] = useState('');
    const [type, setType] = useState('system');
    const [targetType, setTargetType] = useState<'all' | 'specific'>('all');
    const [selectedUsers, setSelectedUsers] = useState<User[]>([]);
    const [users, setUsers] = useState<User[]>([]);
    const [loading, setLoading] = useState(false);
    const [loadingUsers, setLoadingUsers] = useState(false);
    const [success, setSuccess] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [history, setHistory] = useState<NotificationHistory[]>([]);

    useEffect(() => {
        loadUsers();
        loadHistory();
    }, []);

    const loadUsers = async () => {
        setLoadingUsers(true);
        try {
            const usersSnapshot = await getDocs(collection(db, 'users'));
            const usersList: User[] = [];
            usersSnapshot.forEach((doc) => {
                const data = doc.data();
                usersList.push({
                    uid: doc.id,
                    email: data.email || 'No email',
                    displayName: data.displayName || data.name || 'Unknown User',
                });
            });
            setUsers(usersList);
        } catch (e: any) {
            setError(e.message);
        } finally {
            setLoadingUsers(false);
        }
    };

    const loadHistory = async () => {
        try {
            const q = query(
                collection(db, 'notification_history'),
                orderBy('sentAt', 'desc'),
                limit(10)
            );
            const snapshot = await getDocs(q);
            const historyList: NotificationHistory[] = [];
            snapshot.forEach((doc) => {
                historyList.push({ id: doc.id, ...doc.data() } as NotificationHistory);
            });
            setHistory(historyList);
        } catch (e: any) {
            console.error('Error loading history:', e);
        }
    };

    const handleSend = async () => {
        if (!title.trim() || !body.trim()) {
            setError('Title and body are required');
            return;
        }

        if (targetType === 'specific' && selectedUsers.length === 0) {
            setError('Please select at least one user');
            return;
        }

        setLoading(true);
        setSuccess(null);
        setError(null);

        try {
            const notificationData = {
                title: title.trim(),
                body: body.trim(),
                type,
                isRead: false,
                timestamp: serverTimestamp(),
            };

            let targetUserIds: string[] = [];

            if (targetType === 'all') {
                // Send to all users
                targetUserIds = users.map(u => u.uid);
            } else {
                // Send to specific users
                targetUserIds = selectedUsers.map(u => u.uid);
            }

            // Add notification to each user's subcollection
            const promises = targetUserIds.map(async (uid) => {
                await addDoc(
                    collection(db, 'users', uid, 'notifications'),
                    notificationData
                );
            });

            await Promise.all(promises);

            // Save to notification history
            const historyData: any = {
                title: title.trim(),
                body: body.trim(),
                type,
                targetType,
                sentAt: serverTimestamp(),
                sentBy: 'admin', // You can replace with actual admin email
                recipientCount: targetUserIds.length,
            };

            // Only add targetUsers if specific users were selected
            if (targetType === 'specific') {
                historyData.targetUsers = targetUserIds;
            }

            await addDoc(collection(db, 'notification_history'), historyData);

            setSuccess(
                `Notification sent successfully to ${targetUserIds.length} user${targetUserIds.length > 1 ? 's' : ''}!`
            );

            // Reset form
            setTitle('');
            setBody('');
            setType('system');
            setTargetType('all');
            setSelectedUsers([]);

            // Reload history
            await loadHistory();
        } catch (e: any) {
            setError(e.message);
        } finally {
            setLoading(false);
        }
    };

    const formatDate = (timestamp: any) => {
        if (!timestamp) return 'N/A';
        try {
            const date = timestamp.toDate();
            return date.toLocaleString();
        } catch {
            return 'N/A';
        }
    };

    if (loading) {
        return <SkeletonLoader type="table" />;
    }

    return (
        <Box>
            <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" alignItems={{ xs: 'stretch', sm: 'center' }} spacing={2} sx={{ mb: 4 }}>
                <Typography variant="h5" sx={{ fontWeight: 'bold' }}>Send Notifications</Typography>
                <Button
                    variant="outlined"
                    startIcon={<Refresh />}
                    onClick={() => {
                        loadUsers();
                        loadHistory();
                    }}
                    sx={{ alignSelf: { xs: 'flex-start', sm: 'center' } }}
                >
                    Refresh
                </Button>
            </Stack>

            {success && <Alert severity="success" onClose={() => setSuccess(null)} sx={{ mb: 3 }}>{success}</Alert>}
            {error && <Alert severity="error" onClose={() => setError(null)} sx={{ mb: 3 }}>{error}</Alert>}

            <Grid container spacing={3}>
                {/* Send Notification Form */}
                <Grid item xs={12} md={7}>
                    <Paper sx={{ p: { xs: 2, sm: 4 }, borderRadius: 3 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
                            <NotificationsActive sx={{ fontSize: 32, color: '#7C3AED' }} />
                            <Typography variant="h6" sx={{ fontWeight: 'bold' }}>Create Notification</Typography>
                        </Box>

                        <Grid container spacing={3}>
                            <Grid item xs={12}>
                                <TextField
                                    fullWidth
                                    label="Notification Title"
                                    value={title}
                                    onChange={(e) => setTitle(e.target.value)}
                                    placeholder="e.g., New Feature Available!"
                                />
                            </Grid>

                            <Grid item xs={12}>
                                <TextField
                                    fullWidth
                                    multiline
                                    rows={4}
                                    label="Notification Body"
                                    value={body}
                                    onChange={(e) => setBody(e.target.value)}
                                    placeholder="Enter the notification message..."
                                />
                            </Grid>

                            <Grid item xs={12}>
                                <TextField
                                    fullWidth
                                    select
                                    label="Notification Type"
                                    value={type}
                                    onChange={(e) => setType(e.target.value)}
                                >
                                    {notificationTypes.map((option) => (
                                        <MenuItem key={option.value} value={option.value}>
                                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                                <Box
                                                    sx={{
                                                        width: 12,
                                                        height: 12,
                                                        borderRadius: '50%',
                                                        bgcolor: option.color,
                                                    }}
                                                />
                                                {option.label}
                                            </Box>
                                        </MenuItem>
                                    ))}
                                </TextField>
                            </Grid>

                            <Grid item xs={12}>
                                <FormControl component="fieldset">
                                    <FormLabel component="legend">Target Audience</FormLabel>
                                    <RadioGroup
                                        row
                                        sx={{ flexWrap: 'wrap' }}
                                        value={targetType}
                                        onChange={(e) => setTargetType(e.target.value as 'all' | 'specific')}
                                    >
                                        <FormControlLabel value="all" control={<Radio />} label="All Users" />
                                        <FormControlLabel value="specific" control={<Radio />} label="Specific Users" />
                                    </RadioGroup>
                                </FormControl>
                            </Grid>

                            {targetType === 'specific' && (
                                <Grid item xs={12}>
                                    <Autocomplete
                                        multiple
                                        options={users}
                                        getOptionLabel={(option) => `${option.displayName} (${option.email})`}
                                        value={selectedUsers}
                                        onChange={(_, newValue) => setSelectedUsers(newValue)}
                                        loading={loadingUsers}
                                        renderInput={(params) => (
                                            <TextField
                                                {...params}
                                                label="Select Users"
                                                placeholder="Search users..."
                                                InputProps={{
                                                    ...params.InputProps,
                                                    endAdornment: (
                                                        <>
                                                            {loadingUsers ? <CircularProgress size={20} /> : null}
                                                            {params.InputProps.endAdornment}
                                                        </>
                                                    ),
                                                }}
                                            />
                                        )}
                                        renderTags={(value, getTagProps) =>
                                            value.map((option, index) => (
                                                <Chip
                                                    label={option.displayName}
                                                    {...getTagProps({ index })}
                                                    size="small"
                                                />
                                            ))
                                        }
                                    />
                                </Grid>
                            )}

                            <Grid item xs={12}>
                                <Button
                                    fullWidth
                                    variant="contained"
                                    size="large"
                                    startIcon={loading ? <CircularProgress size={20} color="inherit" /> : <Send />}
                                    onClick={handleSend}
                                    disabled={loading}
                                    sx={{ py: 1.5 }}
                                >
                                    {loading ? 'Sending...' : 'Send Notification'}
                                </Button>
                            </Grid>
                        </Grid>
                    </Paper>
                </Grid>

                {/* Notification History */}
                <Grid item xs={12} md={5}>
                    <Paper sx={{ p: { xs: 2, sm: 3 }, borderRadius: 3 }}>
                        <Typography variant="h6" sx={{ fontWeight: 'bold', mb: 3 }}>Recent Notifications</Typography>
                        {history.length === 0 ? (
                            <Box sx={{ textAlign: 'center', py: 4 }}>
                                <Typography variant="body2" color="text.secondary">
                                    No notifications sent yet
                                </Typography>
                            </Box>
                        ) : (
                            <Box sx={{ maxHeight: 600, overflowY: 'auto' }}>
                                {history.map((item) => (
                                    <Box
                                        key={item.id}
                                        sx={{
                                            p: 2,
                                            mb: 2,
                                            borderRadius: 2,
                                            bgcolor: 'grey.50',
                                            border: '1px solid',
                                            borderColor: 'grey.200',
                                        }}
                                    >
                                        <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                                            <Typography variant="subtitle2" fontWeight="bold">
                                                {item.title}
                                            </Typography>
                                            <Chip
                                                label={item.type}
                                                size="small"
                                                sx={{
                                                    bgcolor: notificationTypes.find(t => t.value === item.type)?.color || '#999',
                                                    color: 'white',
                                                    fontSize: '10px',
                                                }}
                                            />
                                        </Box>
                                        <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                                            {item.body}
                                        </Typography>
                                        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                            <Typography variant="caption" color="text.secondary">
                                                {formatDate(item.sentAt)}
                                            </Typography>
                                            <Chip
                                                label={item.targetType === 'all' ? 'All Users' : `${item.recipientCount || 0} users`}
                                                size="small"
                                                variant="outlined"
                                            />
                                        </Box>
                                    </Box>
                                ))}
                            </Box>
                        )}
                    </Paper>
                </Grid>
            </Grid>
        </Box>
    );
};

export default NotificationsPage;
