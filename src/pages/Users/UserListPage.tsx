import React, { useState, useEffect } from 'react';
import Toast from '../../components/Common/Toast';
import SkeletonLoader from '../../components/Layout/SkeletonLoader';
import {
    Box,
    Typography,
    Paper,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TableRow,
    Avatar,
    Chip,
    IconButton,
    TextField,
    InputAdornment,
    Switch,
    Dialog,
    DialogTitle,
    DialogContent,
    DialogActions,
    Button,
    Alert,
    Stack
} from '@mui/material';
import {
    Search,
    Visibility,
    FilterList,
    Delete,
    Close,
    SportsEsports,
    FitnessCenter,
    Apple,
    Google,
    Email
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { userService, UserProfile } from '../../services/userService';

const UserListPage: React.FC = () => {
    const [users, setUsers] = useState<UserProfile[]>([]);
    const [deleting, setDeleting] = useState(false);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
    const [selectedUser, setSelectedUser] = useState<UserProfile | null>(null);
    const [success, setSuccess] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const navigate = useNavigate();

    useEffect(() => {
        const fetchUsers = async () => {
            try {
                const data = await userService.getUsers(50);
                setUsers(data);
            } catch (error) {
                console.error('Error fetching users:', error);
            } finally {
                setLoading(false);
            }
        };
        fetchUsers();
    }, []);

    const filteredUsers = users.filter(user =>
        user.displayName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        user.email?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    const getStatusChip = (status: string) => {
        switch (status) {
            case 'premium': return <Chip label="Premium" color="primary" size="small" />;
            case 'trial': return <Chip label="Trial" color="warning" size="small" />;
            default: return <Chip label="Free" color="default" size="small" />;
        }
    };

    const handleBanToggle = async (user: UserProfile) => {
        try {
            const newBanStatus = !user.isBanned;
            await userService.updateUser(user.uid, { isBanned: newBanStatus });
            setSuccess(newBanStatus ? 'User banned successfully!' : 'User unbanned successfully!');
            // Refresh users
            const data = await userService.getUsers(50);
            setUsers(data);
        } catch (err: any) {
            setError(err.message || 'Failed to update ban status');
        }
    };

    const handleDeleteClick = (user: UserProfile, triggerElement?: HTMLButtonElement | null) => {
        triggerElement?.blur();
        setSelectedUser(user);
        setDeleteDialogOpen(true);
    };

    const handleDeleteConfirm = async () => {
        if (!selectedUser || deleting) return;

        try {
            setDeleting(true);
            await userService.deleteUser(selectedUser.uid);
            setSuccess('User deleted successfully!');
            setDeleteDialogOpen(false);
            setSelectedUser(null);

            // Refresh users
            const data = await userService.getUsers(50);
            setUsers(data);
        } catch (err: any) {
            setError(err.message || 'Failed to delete user');
        } finally {
            setDeleting(false);
        }
    };

    return (
        <Box>
            {success && <Toast type="success" message={success} />}
            {error && <Toast type="danger" message={error} />}

            <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" alignItems={{ xs: 'stretch', sm: 'center' }} spacing={2} sx={{ mb: 4 }}>
                <Typography variant="h5" sx={{ fontWeight: 'bold' }}>User Management</Typography>
                <Stack direction="row" spacing={1.5} sx={{ width: { xs: '100%', sm: 'auto' } }}>
                    <TextField
                        variant="outlined"
                        size="small"
                        placeholder="Search users..."
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        InputProps={{
                            startAdornment: (
                                <InputAdornment position="start">
                                    <Search fontSize="small" />
                                </InputAdornment>
                            ),
                        }}
                        sx={{ bgcolor: 'white', borderRadius: 1, width: { xs: '100%', sm: 300 } }}
                    />
                    <IconButton sx={{ bgcolor: 'white', border: '1px solid #E2E8F0', alignSelf: { xs: 'flex-start', sm: 'center' } }}>
                        <FilterList />
                    </IconButton>
                </Stack>
            </Stack>

            <TableContainer component={Paper} sx={{ borderRadius: 3, boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)', overflowX: 'auto' }}>
                <Table sx={{ minWidth: 700 }}>
                    <TableHead sx={{ bgcolor: '#F8FAFC' }}>
                        <TableRow>
                            <TableCell sx={{ fontWeight: '600' }}>User</TableCell>
                            <TableCell sx={{ fontWeight: '600' }}>Status</TableCell>
                            <TableCell sx={{ fontWeight: '600', display: { xs: 'none', md: 'table-cell' } }}>Plan Expiry</TableCell>
                            <TableCell sx={{ fontWeight: '600', display: { xs: 'none', lg: 'table-cell' } }}>Language</TableCell>
                            <TableCell sx={{ fontWeight: '600', display: { xs: 'none', lg: 'table-cell' } }}>Created</TableCell>
                            <TableCell sx={{ fontWeight: '600' }}>Ban/Unban</TableCell>
                            <TableCell align="right" sx={{ fontWeight: '600' }}>Actions</TableCell>
                        </TableRow>
                    </TableHead>
                    <TableBody>
                        {loading ? (
                            <TableRow>
                                <TableCell colSpan={7} align="center" sx={{ py: 3 }}>
                                    <SkeletonLoader type="table" />
                                </TableCell>
                            </TableRow>
                        ) : filteredUsers.length === 0 ? (
                            <TableRow>
                                <TableCell colSpan={7} align="center" sx={{ py: 3 }}>
                                    <Typography color="text.secondary">No users found</Typography>
                                </TableCell>
                            </TableRow>
                        ) : (
                            filteredUsers.map((user) => (
                                <TableRow key={user.uid} hover sx={{ '&:last-child td, &:last-child th': { border: 0 } }}>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                            <Avatar src={user.photoURL} sx={{ bgcolor: '#7C3AED' }}>
                                                {user.displayName?.charAt(0) || user.email.charAt(0)}
                                            </Avatar>
                                            <Box>
                                                <Typography variant="body2" sx={{ fontWeight: '600' }}>{user.displayName || 'N/A'}</Typography>
                                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                                                    {user.authProvider === 'google' ? <Google sx={{ fontSize: 14 }} color="action" /> :
                                                        user.authProvider === 'apple' ? <Apple sx={{ fontSize: 14 }} color="action" /> :
                                                            <Email sx={{ fontSize: 14 }} color="action" />}
                                                    <Typography variant="caption" color="text.secondary">{user.email}</Typography>
                                                </Box>
                                            </Box>
                                        </Box>
                                    </TableCell>
                                    <TableCell>
                                        {user.isBanned ? (
                                            <Chip label="BANNED" color="error" size="small" />
                                        ) : (
                                            getStatusChip(user.subscriptionStatus)
                                        )}
                                    </TableCell>
                                    <TableCell sx={{ display: { xs: 'none', md: 'table-cell' } }}>
                                        <Box>
                                            {user.subscriptionExpiryDate?.seconds ? (
                                                <>
                                                    <Typography variant="body2" sx={{ fontWeight: '600' }}>
                                                        {new Date(user.subscriptionExpiryDate.seconds * 1000).toLocaleDateString()}
                                                    </Typography>
                                                    <Typography variant="caption" color="text.secondary">
                                                        {(() => {
                                                            const days = Math.ceil((user.subscriptionExpiryDate.seconds * 1000 - Date.now()) / (1000 * 60 * 60 * 24));
                                                            return days > 0 ? `${days} days left` : 'Expired';
                                                        })()} • {user.subscriptionType?.includes('monthly') ? 'Monthly' :
                                                            user.subscriptionType?.includes('quarterly') ? 'Quarterly' :
                                                                user.subscriptionType?.includes('yearly') ? 'Yearly' : 'Premium'}
                                                    </Typography>
                                                </>
                                            ) : user.trialEndTime?.seconds ? (
                                                <>
                                                    <Typography variant="body2" sx={{ fontWeight: '600' }}>
                                                        {new Date(user.trialEndTime.seconds * 1000).toLocaleDateString()}
                                                    </Typography>
                                                    <Typography variant="caption" color="text.secondary">
                                                        {(() => {
                                                            const days = Math.ceil((user.trialEndTime.seconds * 1000 - Date.now()) / (1000 * 60 * 60 * 24));
                                                            return days > 0 ? `${days} days left` : 'Expired';
                                                        })()} • Trial (48h)
                                                    </Typography>
                                                </>
                                            ) : user.subscriptionStatus === 'premium' || user.subscriptionStatus === 'trial' ? (
                                                <>
                                                    <Typography variant="body2" sx={{ fontWeight: '600', color: 'primary.main' }}>
                                                        Active
                                                    </Typography>
                                                    <Typography variant="caption" color="text.secondary">
                                                        No expiry date set
                                                    </Typography>
                                                </>
                                            ) : (
                                                <Typography variant="body2" color="text.secondary">
                                                    No expiry (Free)
                                                </Typography>
                                            )}
                                        </Box>
                                    </TableCell>
                                    <TableCell sx={{ display: { xs: 'none', lg: 'table-cell' } }}>
                                        <Typography variant="body2">{user.preferredLanguage.toUpperCase()}</Typography>
                                    </TableCell>
                                    <TableCell sx={{ display: { xs: 'none', lg: 'table-cell' } }}>
                                        <Typography variant="body2">
                                            {user.createdAt?.seconds ? new Date(user.createdAt.seconds * 1000).toLocaleDateString() : 'N/A'}
                                        </Typography>
                                    </TableCell>
                                    <TableCell>
                                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                            <Switch
                                                checked={!user.isBanned}
                                                onChange={() => handleBanToggle(user)}
                                                color={user.isBanned ? 'error' : 'success'}
                                                size="small"
                                            />
                                            <Typography variant="caption" color="text.secondary">
                                                {user.isBanned ? 'Banned' : 'Active'}
                                            </Typography>
                                            {user.cancellationRequested && (
                                                <Chip
                                                    icon={<Close fontSize="small" />}
                                                    label="Cancel Req"
                                                    color="error"
                                                    size="small"
                                                    variant="outlined"
                                                />
                                            )}
                                        </Box>
                                    </TableCell>
                                    <TableCell align="right">
                                        <IconButton
                                            size="small"
                                            color="info"
                                            onClick={() => navigate(`/users/${user.uid}/game-progress`)}
                                            title="Game Progress"
                                        >
                                            <SportsEsports fontSize="small" />
                                        </IconButton>
                                        <IconButton
                                            size="small"
                                            color="secondary"
                                            onClick={() => navigate(`/users/${user.uid}/kegel-progress`)}
                                            title="Kegel Progress"
                                        >
                                            <FitnessCenter fontSize="small" />
                                        </IconButton>
                                        <IconButton
                                            size="small"
                                            color="primary"
                                            onClick={() => navigate(`/users/${user.uid}`)}
                                            title="View Details"
                                        >
                                            <Visibility fontSize="small" />
                                        </IconButton>
                                        <IconButton
                                            size="small"
                                            color="error"
                                            onClick={(event) => handleDeleteClick(user, event.currentTarget)}
                                            title="Delete User"
                                        >
                                            <Delete fontSize="small" />
                                        </IconButton>
                                    </TableCell>
                                </TableRow>
                            ))
                        )}
                    </TableBody>
                </Table>
            </TableContainer>

            {/* Delete Dialog */}
            <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)} maxWidth="sm" fullWidth keepMounted>
                <DialogTitle>Delete User Account</DialogTitle>
                <DialogContent>
                    <Alert severity="error" sx={{ mb: 2 }}>
                        This action cannot be undone!
                    </Alert>
                    <Typography>
                        Are you sure you want to delete <strong>{selectedUser?.displayName || selectedUser?.email}</strong>? All user data will be permanently removed.
                    </Typography>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setDeleteDialogOpen(false)} disabled={deleting}>Cancel</Button>
                    <Button onClick={handleDeleteConfirm} variant="contained" color="error" disabled={deleting}>
                        {deleting ? 'Deleting...' : 'Delete Account'}
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default UserListPage;
