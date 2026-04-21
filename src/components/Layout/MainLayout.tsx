import React, { useState, Suspense } from 'react';
import { Box, Toolbar } from '@mui/material';
import SkeletonLoader from './SkeletonLoader';
import Sidebar from './Sidebar';
import Header from './Header';
import { useAuth } from '../../contexts/AuthContext';
import { Navigate, Outlet } from 'react-router-dom';

const MainLayout: React.FC = () => {
    const { user, loading } = useAuth();
    const [mobileOpen, setMobileOpen] = useState(false);

    const handleDrawerToggle = () => {
        setMobileOpen(prev => !prev);
    };

    const handleDrawerClose = () => {
        setMobileOpen(false);
    };

    const handleContentClick = () => {
        if (mobileOpen) {
            setMobileOpen(false);
        }
    };


    if (loading) return null; // Or a full-screen spinner

    if (!user) {
        return <Navigate to="/login" replace />;
    }

    return (
        <Box sx={{ display: 'flex', minHeight: '100vh', bgcolor: '#F8FAFC' }}>
            <Header onDrawerToggle={handleDrawerToggle} />
            <Sidebar mobileOpen={mobileOpen} onClose={handleDrawerClose} />
            <Box
                component="main"
                onClick={handleContentClick}
                sx={{
                    flexGrow: 1,
                    p: { xs: 2.5, sm: 3 },
                    minHeight: '100vh',
                    minWidth: 0, // Critical for flex children to not overflow
                    overflowX: 'hidden',
                }}
            >
                <Toolbar />
                <Suspense fallback={<SkeletonLoader />}><Outlet /></Suspense>
            </Box>
        </Box>
    );
};

export default MainLayout;
