import React, { useEffect, useState } from 'react';
import {
    AppBar,
    Toolbar,
    Typography,
    IconButton,
    Avatar,
    Box,
    Menu,
    MenuItem,
    Tooltip,
    Chip
} from '@mui/material';
import {
    Menu as MenuIcon,
    AccessTime
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';
import { authService } from '../../services/authService';

interface HeaderProps {
    onDrawerToggle: () => void;
}

const Header: React.FC<HeaderProps> = ({ onDrawerToggle }) => {
    const { user, role, logout } = useAuth();
    const [anchorEl, setAnchorEl] = React.useState<null | HTMLElement>(null);
    const [remainingTime, setRemainingTime] = useState<number>(0);

    useEffect(() => {
        // Update remaining time every minute
        const updateTime = () => {
            setRemainingTime(authService.getRemainingSessionTime());
        };

        updateTime(); // Initial update
        const interval = setInterval(updateTime, 60000); // Update every minute

        return () => clearInterval(interval);
    }, []);

    const handleMenu = (event: React.MouseEvent<HTMLElement>) => {
        setAnchorEl(event.currentTarget);
    };

    const handleClose = () => {
        setAnchorEl(null);
    };

    const handleLogout = async () => {
        await logout();
        handleClose();
    };

    const formatTime = (minutes: number): string => {
        const hours = Math.floor(minutes / 60);
        const mins = minutes % 60;
        return `${hours}h ${mins}m`;
    };

    return (
        <AppBar
            position="fixed"
            sx={{
                zIndex: (theme) => theme.zIndex.drawer + 1,
                backgroundColor: 'white',
                color: '#1E293B',
                boxShadow: 'none',
                borderBottom: '1px solid #E2E8F0'
            }}
        >
            <Toolbar>
                <IconButton
                    color="inherit"
                    edge="start"
                    onClick={onDrawerToggle}
                    sx={{ mr: 1, display: { xs: 'inline-flex', sm: 'none' } }}
                >
                    <MenuIcon />
                </IconButton>

                <Typography variant="h6" noWrap component="div" sx={{ flexGrow: 1, fontWeight: 'bold' }}>
                    Admin Panel
                </Typography>

                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    {/* Session Timer */}
                    {remainingTime > 0 && (
                        <Tooltip title="Session expires in">
                            <Chip
                                icon={<AccessTime />}
                                label={formatTime(remainingTime)}
                                size="small"
                                color={remainingTime < 60 ? 'error' : 'default'}
                                variant="outlined"
                                sx={{ display: { xs: 'none', md: 'flex' } }}
                            />
                        </Tooltip>
                    )}

                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Box sx={{ textAlign: 'right', display: { xs: 'none', sm: 'block' } }}>
                            <Typography variant="body2" sx={{ fontWeight: '600' }}>
                                {user?.displayName || 'Admin User'}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                                {role || 'Moderator'}
                            </Typography>
                        </Box>
                        <Tooltip title="Account settings">
                            <IconButton onClick={handleMenu} sx={{ p: 0 }}>
                                <Avatar sx={{ bgcolor: '#7C3AED' }}>
                                    {user?.email?.charAt(0).toUpperCase()}
                                </Avatar>
                            </IconButton>
                        </Tooltip>
                        <Menu
                            anchorEl={anchorEl}
                            open={Boolean(anchorEl)}
                            onClose={handleClose}
                            transformOrigin={{ horizontal: 'right', vertical: 'top' }}
                            anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
                        >
                            <MenuItem disabled>
                                <Typography variant="caption" color="text.secondary">
                                    Session: {formatTime(remainingTime)} remaining
                                </Typography>
                            </MenuItem>
                            <MenuItem onClick={handleClose}>Profile</MenuItem>
                            <MenuItem onClick={handleLogout}>Logout</MenuItem>
                        </Menu>
                    </Box>
                </Box>
            </Toolbar>
        </AppBar>
    );
};

export default Header;
