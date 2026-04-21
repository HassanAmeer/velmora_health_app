import React from 'react';
import {
    Drawer,
    List,
    ListItem,
    ListItemIcon,
    ListItemText,
    ListItemButton,
    Toolbar,
    Typography,
    Box
} from '@mui/material';
import {
    Dashboard as DashboardIcon,
    People as PeopleIcon,
    Subscriptions as SubscriptionsIcon,
    SmartToy as SmartToyIcon,
    SportsEsports as GamesIcon,
    FitnessCenter as KegelIcon,
    Notifications as NotifyIcon,
    SupportAgent as SupportIcon,
    Settings as SettingsIcon,
    Logout as LogoutIcon
} from '@mui/icons-material';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { Divider } from '@mui/material';

const drawerWidth = 260;

const menuItems = [
    { text: 'Dashboard', icon: <DashboardIcon />, path: '/' },
    { text: 'Users', icon: <PeopleIcon />, path: '/users' },
    { text: 'Subscriptions', icon: <SubscriptionsIcon />, path: '/subscriptions' },
    { text: 'AI Configuration', icon: <SmartToyIcon />, path: '/ai-config' },
    { text: 'Games', icon: <GamesIcon />, path: '/games' },
    { text: 'Kegel Exercises', icon: <KegelIcon />, path: '/kegel' },
    { text: 'Notifications', icon: <NotifyIcon />, path: '/notifications' },
    { text: 'Support', icon: <SupportIcon />, path: '/support' },
    { text: 'Settings', icon: <SettingsIcon />, path: '/settings' },
];

interface SidebarProps {
    mobileOpen: boolean;
    onClose: () => void;
}

const Sidebar: React.FC<SidebarProps> = ({ mobileOpen, onClose }) => {
    const navigate = useNavigate();
    const location = useLocation();
    const { logout } = useAuth();

    const drawerContent = (
        <Box sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
            <Toolbar>
                <Typography variant="h6" noWrap component="div" sx={{ fontWeight: 'bold', color: '#A78BFA' }}>
                    Velmora Admin
                </Typography>
            </Toolbar>
            <Box sx={{ flexGrow: 1, overflow: 'auto' }}>
                <List>
                    {menuItems.map((item) => (
                        <ListItem key={item.text} disablePadding>
                            <ListItemButton
                                onClick={() => {
                                    navigate(item.path);
                                    onClose();
                                }}
                                selected={location.pathname === item.path}
                                sx={{
                                    '&.Mui-selected': {
                                        backgroundColor: 'rgba(124, 58, 237, 0.2)',
                                        borderRight: '4px solid #7C3AED',
                                    },
                                    '&:hover': {
                                        backgroundColor: 'rgba(124, 58, 237, 0.1)',
                                    },
                                    color: location.pathname === item.path ? '#A78BFA' : 'rgba(255,255,255,0.7)',
                                    '& .MuiListItemIcon-root': {
                                        color: location.pathname === item.path ? '#7C3AED' : 'rgba(255,255,255,0.7)',
                                    }
                                }}
                            >
                                <ListItemIcon>
                                    {item.icon}
                                </ListItemIcon>
                                <ListItemText primary={item.text} />
                            </ListItemButton>
                        </ListItem>
                    ))}
                </List>
            </Box>
            <Box sx={{ p: 1 }}>
                <Divider sx={{ bgcolor: 'rgba(255,255,255,0.1)', mb: 1 }} />
                <List>
                    <ListItem disablePadding>
                        <ListItemButton
                            onClick={async () => {
                                await logout();
                                onClose();
                            }}
                            sx={{
                                color: '#EF4444',
                                borderRadius: 2,
                                '& .MuiListItemIcon-root': {
                                    color: '#EF4444',
                                },
                                '&:hover': {
                                    backgroundColor: 'rgba(239, 68, 68, 0.1)',
                                }
                            }}
                        >
                            <ListItemIcon>
                                <LogoutIcon />
                            </ListItemIcon>
                            <ListItemText primary="Logout" />
                        </ListItemButton>
                    </ListItem>
                </List>
            </Box>
        </Box>
    );

    return (
        <>
            <Box sx={{ display: { xs: 'block', sm: 'none' } }}>
                <Drawer
                    variant="temporary"
                    open={mobileOpen}
                    onClose={onClose}
                    ModalProps={{ keepMounted: true }}
                    sx={{
                        '& .MuiDrawer-paper': {
                            width: drawerWidth,
                            boxSizing: 'border-box',
                            backgroundColor: '#1E1B4B',
                            color: 'white'
                        },
                    }}
                >
                    {drawerContent}
                </Drawer>
            </Box>

            <Box sx={{ display: { xs: 'none', sm: 'block' } }}>
                <Drawer
                    variant="permanent"
                    sx={{
                        width: drawerWidth,
                        flexShrink: 0,
                        [`& .MuiDrawer-paper`]: {
                            width: drawerWidth,
                            boxSizing: 'border-box',
                            backgroundColor: '#1E1B4B',
                            color: 'white'
                        },
                    }}
                    open
                >
                    {drawerContent}
                </Drawer>
            </Box>
        </>
    );
};

export default Sidebar;
