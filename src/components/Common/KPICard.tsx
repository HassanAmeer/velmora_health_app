import React from 'react';
import { Card, CardContent, Typography, Box, Skeleton } from '@mui/material';
import { TrendingUp, TrendingDown } from '@mui/icons-material';

interface KPICardProps {
    title: string;
    value: string | number;
    icon: React.ReactNode;
    trend?: {
        value: number;
        isUp: boolean;
    };
    loading?: boolean;
    color?: string;
}

const KPICard: React.FC<KPICardProps> = ({ title, value, icon, trend, loading, color = '#7C3AED' }) => {
    if (loading) {
        return (
            <Card sx={{ height: '100%' }}>
                <CardContent>
                    <Skeleton variant="text" width="60%" />
                    <Skeleton variant="rectangular" height={40} sx={{ my: 1 }} />
                    <Skeleton variant="text" width="40%" />
                </CardContent>
            </Card>
        );
    }

    return (
        <Card sx={{ height: '100%', boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)' }}>
            <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <Box>
                        <Typography variant="overline" color="text.secondary" sx={{ fontWeight: 'bold' }}>
                            {title}
                        </Typography>
                        <Typography variant="h4" sx={{ fontWeight: 'bold', my: 1 }}>
                            {value}
                        </Typography>
                    </Box>
                    <Box
                        sx={{
                            p: 1.5,
                            borderRadius: 2,
                            bgcolor: `${color}15`,
                            color: color,
                            display: 'flex'
                        }}
                    >
                        {icon}
                    </Box>
                </Box>

                {trend && (
                    <Box sx={{ display: 'flex', alignItems: 'center', mt: 1 }}>
                        {trend.isUp ? (
                            <TrendingUp sx={{ color: '#10B981', fontSize: 16, mr: 0.5 }} />
                        ) : (
                            <TrendingDown sx={{ color: '#EF4444', fontSize: 16, mr: 0.5 }} />
                        )}
                        <Typography
                            variant="caption"
                            sx={{
                                color: trend.isUp ? '#10B981' : '#EF4444',
                                fontWeight: '600'
                            }}
                        >
                            {trend.value}%
                        </Typography>
                        <Typography variant="caption" color="text.secondary" sx={{ ml: 1 }}>
                            vs last month
                        </Typography>
                    </Box>
                )}
            </CardContent>
        </Card>
    );
};

export default KPICard;
