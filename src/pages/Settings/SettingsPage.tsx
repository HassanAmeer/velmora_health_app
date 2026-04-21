import React, { useState, useEffect } from 'react';
import SkeletonLoader from '../../components/Layout/SkeletonLoader';
import {
    Box, Typography, Paper, Tabs, Tab, TextField, Button,
    CircularProgress, Alert, Grid, Divider, IconButton, Stack
} from '@mui/material';
import { Save, Refresh, Add, Delete } from '@mui/icons-material';
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../../services/firebase';

interface LegalSection {
    title: string;
    content: string;
}

interface LegalDocument {
    sections: LegalSection[];
    lastUpdated: string;
}

interface AppSettings {
    supportEmail: string;
    adminEmail: string;
    adminPassword: string;
    termsOfService: LegalDocument;
    privacyPolicy: LegalDocument;
}

const defaultSettings: AppSettings = {
    supportEmail: 'support@velmora.com',
    adminEmail: 'admin@gmail.com',
    adminPassword: '12345678',
    termsOfService: {
        sections: [
            {
                title: 'Agreement to Terms',
                content: 'By accessing or using Velmora AI, you agree to be bound by these Terms of Service.',
            },
        ],
        lastUpdated: new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }),
    },
    privacyPolicy: {
        sections: [
            {
                title: 'Introduction',
                content: 'Velmora AI is committed to protecting your privacy.',
            },
        ],
        lastUpdated: new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }),
    },
};

const SettingsPage: React.FC = () => {
    const [tabValue, setTabValue] = useState(0);
    const [settings, setSettings] = useState<AppSettings>(defaultSettings);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [success, setSuccess] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        loadSettings();
    }, []);

    const loadSettings = async () => {
        setLoading(true);
        try {
            // Load support email
            const settingsDoc = await getDoc(doc(db, 'admin_settings', 'general'));
            const supportEmail = settingsDoc.exists() ? settingsDoc.data()?.supportEmail : defaultSettings.supportEmail;

            // Load admin credentials
            const adminCredentialsDoc = await getDoc(doc(db, 'admin', 'credentials'));
            const adminEmail = adminCredentialsDoc.exists()
                ? (adminCredentialsDoc.data()?.adminEmail || defaultSettings.adminEmail)
                : defaultSettings.adminEmail;
            const adminPassword = adminCredentialsDoc.exists()
                ? (adminCredentialsDoc.data()?.adminPassword || defaultSettings.adminPassword)
                : defaultSettings.adminPassword;

            // Load Terms of Service
            const termsDoc = await getDoc(doc(db, 'admin', 'legal_docs', 'items', 'terms_of_service'));
            const termsOfService = termsDoc.exists() ? termsDoc.data() as LegalDocument : defaultSettings.termsOfService;

            // Load Privacy Policy
            const privacyDoc = await getDoc(doc(db, 'admin', 'legal_docs', 'items', 'privacy_policy'));
            const privacyPolicy = privacyDoc.exists() ? privacyDoc.data() as LegalDocument : defaultSettings.privacyPolicy;

            setSettings({
                supportEmail,
                adminEmail,
                adminPassword,
                termsOfService,
                privacyPolicy,
            });

            localStorage.setItem('adminCredentialsEmail', adminEmail);
            localStorage.setItem('adminCredentialsPassword', adminPassword);
        } catch (e: any) {
            setError(e.message);
        } finally {
            setLoading(false);
        }
    };

    const saveSettings = async () => {
        setSaving(true);
        setSuccess(null);
        setError(null);

        try {
            // Save support email
            await setDoc(doc(db, 'admin_settings', 'general'), {
                supportEmail: settings.supportEmail,
                updatedAt: serverTimestamp(),
            });

            // Save admin credentials
            await setDoc(doc(db, 'admin', 'credentials'), {
                adminEmail: settings.adminEmail,
                adminPassword: settings.adminPassword,
                updatedAt: serverTimestamp(),
            }, { merge: true });

            localStorage.setItem('adminCredentialsEmail', settings.adminEmail);
            localStorage.setItem('adminCredentialsPassword', settings.adminPassword);

            // Save Terms of Service
            await setDoc(doc(db, 'admin', 'legal_docs', 'items', 'terms_of_service'), {
                ...settings.termsOfService,
                lastUpdated: new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }),
                updatedAt: serverTimestamp(),
            });

            // Save Privacy Policy
            await setDoc(doc(db, 'admin', 'legal_docs', 'items', 'privacy_policy'), {
                ...settings.privacyPolicy,
                lastUpdated: new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' }),
                updatedAt: serverTimestamp(),
            });

            setSuccess('Settings saved successfully!');
            await loadSettings();
        } catch (e: any) {
            setError(e.message);
        } finally {
            setSaving(false);
        }
    };

    const addSection = (type: 'termsOfService' | 'privacyPolicy') => {
        setSettings({
            ...settings,
            [type]: {
                ...settings[type],
                sections: [
                    ...settings[type].sections,
                    { title: '', content: '' },
                ],
            },
        });
    };

    const updateSection = (
        type: 'termsOfService' | 'privacyPolicy',
        index: number,
        field: 'title' | 'content',
        value: string
    ) => {
        const newSections = [...settings[type].sections];
        newSections[index][field] = value;
        setSettings({
            ...settings,
            [type]: {
                ...settings[type],
                sections: newSections,
            },
        });
    };

    const deleteSection = (type: 'termsOfService' | 'privacyPolicy', index: number) => {
        const newSections = settings[type].sections.filter((_, i) => i !== index);
        setSettings({
            ...settings,
            [type]: {
                ...settings[type],
                sections: newSections,
            },
        });
    };

    if (loading) {
        return <SkeletonLoader type="details" />;
    }

    return (
        <Box>
            <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" alignItems={{ xs: 'stretch', sm: 'center' }} spacing={2} sx={{ mb: 4 }}>
                <Typography variant="h5" sx={{ fontWeight: 'bold' }}>App Settings</Typography>
                <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1.5} sx={{ width: { xs: '100%', sm: 'auto' } }}>
                    <Button variant="outlined" startIcon={<Refresh />} onClick={loadSettings}>
                        Refresh
                    </Button>
                    <Button
                        variant="contained"
                        startIcon={saving ? <CircularProgress size={20} color="inherit" /> : <Save />}
                        onClick={saveSettings}
                        disabled={saving}
                    >
                        {saving ? 'Saving...' : 'Save All Changes'}
                    </Button>
                </Stack>
            </Stack>

            {success && <Alert severity="success" onClose={() => setSuccess(null)} sx={{ mb: 3 }}>{success}</Alert>}
            {error && <Alert severity="error" onClose={() => setError(null)} sx={{ mb: 3 }}>{error}</Alert>}

            <Paper sx={{ borderRadius: 3 }}>
                <Tabs value={tabValue} onChange={(_, v) => setTabValue(v)} variant="scrollable" scrollButtons="auto" sx={{ borderBottom: 1, borderColor: 'divider' }}>
                    <Tab label="General Settings" />
                    <Tab label="Admin Credentials" />
                    <Tab label="Terms of Service" />
                    <Tab label="Privacy Policy" />
                </Tabs>

                <Box sx={{ p: { xs: 2, sm: 4 } }}>
                    {/* General Settings Tab */}
                    {tabValue === 0 && (
                        <Grid container spacing={3}>
                            <Grid item xs={12}>
                                <Typography variant="h6" gutterBottom>Contact Information</Typography>
                                <Divider sx={{ mb: 3 }} />
                            </Grid>
                            <Grid item xs={12} md={6}>
                                <TextField
                                    fullWidth
                                    label="Support Email"
                                    value={settings.supportEmail}
                                    onChange={(e) => setSettings({ ...settings, supportEmail: e.target.value })}
                                    helperText="Email address for user support inquiries"
                                    type="email"
                                />
                            </Grid>
                            <Grid item xs={12}>
                                <Alert severity="info">
                                    This email will be displayed in the app for users to contact support.
                                </Alert>
                            </Grid>
                        </Grid>
                    )}

                    {/* Admin Credentials Tab */}
                    {tabValue === 1 && (
                        <Grid container spacing={3}>
                            <Grid item xs={12}>
                                <Typography variant="h6" gutterBottom>Admin Login Credentials</Typography>
                                <Divider sx={{ mb: 3 }} />
                            </Grid>
                            <Grid item xs={12} md={6}>
                                <TextField
                                    fullWidth
                                    label="Admin Email"
                                    type="email"
                                    value={settings.adminEmail}
                                    onChange={(e) => setSettings({ ...settings, adminEmail: e.target.value })}
                                />
                            </Grid>
                            <Grid item xs={12} md={6}>
                                <TextField
                                    fullWidth
                                    label="Admin Password"
                                    type="text"
                                    value={settings.adminPassword}
                                    onChange={(e) => setSettings({ ...settings, adminPassword: e.target.value })}
                                    helperText="Used for reference and login page hint only"
                                />
                            </Grid>
                            <Grid item xs={12}>
                                <Alert severity="info">
                                    This updates admin credential metadata stored in <strong>admin/credentials</strong>. Ensure Firebase Auth password is kept in sync manually if changed.
                                </Alert>
                            </Grid>
                        </Grid>
                    )}

                    {/* Terms of Service Tab */}
                    {tabValue === 2 && (
                        <Box>
                            <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" alignItems={{ xs: 'stretch', sm: 'center' }} spacing={1.5} sx={{ mb: 3 }}>
                                <Typography variant="h6">Terms of Service Sections</Typography>
                                <Button
                                    variant="outlined"
                                    startIcon={<Add />}
                                    onClick={() => addSection('termsOfService')}
                                    sx={{ alignSelf: { xs: 'flex-start', sm: 'center' } }}
                                >
                                    Add Section
                                </Button>
                            </Stack>
                            <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                                Last Updated: {settings.termsOfService.lastUpdated}
                            </Typography>
                            {settings.termsOfService.sections.map((section, index) => (
                                <Paper key={index} sx={{ p: 3, mb: 3, bgcolor: 'grey.50' }}>
                                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                                        <Typography variant="subtitle2" color="text.secondary">
                                            Section {index + 1}
                                        </Typography>
                                        <IconButton
                                            size="small"
                                            color="error"
                                            onClick={() => deleteSection('termsOfService', index)}
                                        >
                                            <Delete fontSize="small" />
                                        </IconButton>
                                    </Box>
                                    <TextField
                                        fullWidth
                                        label="Section Title"
                                        value={section.title}
                                        onChange={(e) => updateSection('termsOfService', index, 'title', e.target.value)}
                                        sx={{ mb: 2 }}
                                    />
                                    <TextField
                                        fullWidth
                                        multiline
                                        rows={6}
                                        label="Section Content"
                                        value={section.content}
                                        onChange={(e) => updateSection('termsOfService', index, 'content', e.target.value)}
                                    />
                                </Paper>
                            ))}
                        </Box>
                    )}

                    {/* Privacy Policy Tab */}
                    {tabValue === 3 && (
                        <Box>
                            <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" alignItems={{ xs: 'stretch', sm: 'center' }} spacing={1.5} sx={{ mb: 3 }}>
                                <Typography variant="h6">Privacy Policy Sections</Typography>
                                <Button
                                    variant="outlined"
                                    startIcon={<Add />}
                                    onClick={() => addSection('privacyPolicy')}
                                    sx={{ alignSelf: { xs: 'flex-start', sm: 'center' } }}
                                >
                                    Add Section
                                </Button>
                            </Stack>
                            <Typography variant="body2" color="text.secondary" sx={{ mb: 3 }}>
                                Last Updated: {settings.privacyPolicy.lastUpdated}
                            </Typography>
                            {settings.privacyPolicy.sections.map((section, index) => (
                                <Paper key={index} sx={{ p: 3, mb: 3, bgcolor: 'grey.50' }}>
                                    <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                                        <Typography variant="subtitle2" color="text.secondary">
                                            Section {index + 1}
                                        </Typography>
                                        <IconButton
                                            size="small"
                                            color="error"
                                            onClick={() => deleteSection('privacyPolicy', index)}
                                        >
                                            <Delete fontSize="small" />
                                        </IconButton>
                                    </Box>
                                    <TextField
                                        fullWidth
                                        label="Section Title"
                                        value={section.title}
                                        onChange={(e) => updateSection('privacyPolicy', index, 'title', e.target.value)}
                                        sx={{ mb: 2 }}
                                    />
                                    <TextField
                                        fullWidth
                                        multiline
                                        rows={6}
                                        label="Section Content"
                                        value={section.content}
                                        onChange={(e) => updateSection('privacyPolicy', index, 'content', e.target.value)}
                                    />
                                </Paper>
                            ))}
                        </Box>
                    )}
                </Box>
            </Paper>
        </Box>
    );
};

export default SettingsPage;
