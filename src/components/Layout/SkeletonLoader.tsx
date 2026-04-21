import React from 'react';
import { Box, Skeleton, Grid, Paper, Stack } from '@mui/material';

interface SkeletonLoaderProps {
    type?: 'list' | 'card' | 'table' | 'details' | 'dashboard';
    count?: number;
}

const SkeletonLoader: React.FC<SkeletonLoaderProps> = ({ type = 'table', count = 3 }) => {
    const renderTableSkeleton = () => (
        <Paper sx={{ p: { xs: 2, sm: 3 }, borderRadius: 3 }}>
            <Box sx={{ borderBottom: 1, borderColor: 'divider', pb: 2, mb: 2 }}>
                <Skeleton variant="rectangular" width="40%" height={32} animation="wave" />
            </Box>
            {[...Array(5)].map((_, i) => (
                <Box key={i} sx={{ display: 'flex', gap: 2, mb: 2 }}>
                    <Skeleton variant="text" width="25%" height={24} animation="wave" />
                    <Skeleton variant="text" width="45%" height={24} animation="wave" />
                    <Skeleton variant="text" width="20%" height={24} animation="wave" />
                </Box>
            ))}
        </Paper>
    );

    const renderCardSkeleton = () => (
        <Grid container spacing={3}>
            {[...Array(count)].map((_, i) => (
                <Grid item xs={12} sm={6} md={4} key={i}>
                    <Paper sx={{ p: 3, borderRadius: 3 }}>
                        <Skeleton variant="rectangular" width="100%" height={120} animation="wave" sx={{ mb: 2, borderRadius: 2 }} />
                        <Skeleton variant="text" width="80%" height={32} animation="wave" />
                        <Skeleton variant="text" width="60%" height={24} animation="wave" />
                        <Box sx={{ mt: 2, display: 'flex', gap: 1 }}>
                            <Skeleton variant="rectangular" width="40%" height={36} animation="wave" sx={{ borderRadius: 1 }} />
                            <Skeleton variant="rectangular" width="40%" height={36} animation="wave" sx={{ borderRadius: 1 }} />
                        </Box>
                    </Paper>
                </Grid>
            ))}
        </Grid>
    );

    const renderDetailsSkeleton = () => (
        <Paper sx={{ p: { xs: 2, sm: 4 }, borderRadius: 3 }}>
            <Box sx={{ mb: 4 }}>
                <Skeleton variant="text" width="40%" height={40} animation="wave" sx={{ mb: 1 }} />
                <Skeleton variant="text" width="60%" height={24} animation="wave" />
            </Box>
            <Grid container spacing={3}>
                {[...Array(6)].map((_, i) => (
                    <Grid item xs={12} md={6} key={i}>
                        <Skeleton variant="text" width="30%" animation="wave" />
                        <Skeleton variant="rectangular" width="100%" height={56} animation="wave" sx={{ borderRadius: 1, mt: 1 }} />
                    </Grid>
                ))}
            </Grid>
        </Paper>
    );

    const renderListSkeleton = () => (
        <Stack spacing={2}>
            {[...Array(count)].map((_, i) => (
                <Paper key={i} sx={{ p: 2, borderRadius: 2 }}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <Skeleton variant="circular" width={40} height={40} animation="wave" />
                        <Box sx={{ flex: 1 }}>
                            <Skeleton variant="text" width="40%" animation="wave" />
                            <Skeleton variant="text" width="70%" animation="wave" />
                        </Box>
                    </Box>
                </Paper>
            ))}
        </Stack>
    );

    const renderDashboardSkeleton = () => (
        <Grid container spacing={2.5}>
            {[...Array(4)].map((_, i) => (
                <Grid item xs={12} sm={6} lg={3} key={i}>
                    <Paper sx={{ p: 3, borderRadius: 3 }}>
                        <Skeleton variant="text" width="50%" animation="wave" />
                        <Skeleton variant="rectangular" width="80%" height={48} animation="wave" sx={{ my: 1 }} />
                        <Skeleton variant="text" width="60%" animation="wave" />
                    </Paper>
                </Grid>
            ))}
        </Grid>
    );

    return (
        <Box sx={{ width: '100%', py: 2 }}>
            {type === 'table' && renderTableSkeleton()}
            {type === 'card' && renderCardSkeleton()}
            {type === 'details' && renderDetailsSkeleton()}
            {type === 'list' && renderListSkeleton()}
            {type === 'dashboard' && renderDashboardSkeleton()}
        </Box>
    );
};

export default SkeletonLoader;