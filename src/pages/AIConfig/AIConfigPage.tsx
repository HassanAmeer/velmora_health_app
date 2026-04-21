import React, { useState, useEffect } from 'react';
import {
    Box, Typography, TextField, Button, Paper, Grid,
    CircularProgress, Alert, MenuItem, Divider, InputAdornment, IconButton, Switch, FormControlLabel, Stack, Dialog, DialogTitle, DialogContent, DialogActions
} from '@mui/material';
import { Save, Refresh, Visibility, VisibilityOff, CheckCircle } from '@mui/icons-material';
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../../services/firebase';
import SkeletonLoader from '../../components/Layout/SkeletonLoader';

interface SafetySettings {
    dangerousContent: string;
    harassment: string;
    hateSpeech: string;
    sexuallyExplicit: string;
}

interface AIConfig {
    enabled: boolean;
    apiKey: string;
    maxTokens: number;
    model: string;
    safetySettings: SafetySettings;
    systemInstruction: string;
    temperature: number;
    topK: number;
    topP: number;
}

const defaultConfig: AIConfig = {
    enabled: true,
    apiKey: 'PLACEHOLDER_KEY',
    maxTokens: 500,
    model: 'gemini-2.5-flash',
    safetySettings: {
        dangerousContent: 'BLOCK_MEDIUM_AND_ABOVE',
        harassment: 'BLOCK_MEDIUM_AND_ABOVE',
        hateSpeech: 'BLOCK_MEDIUM_AND_ABOVE',
        sexuallyExplicit: 'BLOCK_MEDIUM_AND_ABOVE',
    },
    systemInstruction: 'You are Velmora AI, a helpful relationship coach.',
    temperature: 0.7,
    topK: 40,
    topP: 0.95,
};

const safetyLevels = [
    'BLOCK_NONE',
    'BLOCK_ONLY_HIGH',
    'BLOCK_MEDIUM_AND_ABOVE',
    'BLOCK_LOW_AND_ABOVE',
];

const AIConfigPage: React.FC = () => {
    const [config, setConfig] = useState<AIConfig>(defaultConfig);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [success, setSuccess] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [showApiKey, setShowApiKey] = useState(false);
    const [testing, setTesting] = useState(false);
    const [testDialogOpen, setTestDialogOpen] = useState(false);
    const [testResponse, setTestResponse] = useState<string>('');

    useEffect(() => {
        loadConfig();
    }, []);

    const loadConfig = async () => {
        setLoading(true);
        try {
            const docRef = doc(db, 'ai_config', 'settings');
            const docSnap = await getDoc(docRef);

            if (docSnap.exists()) {
                setConfig(docSnap.data() as AIConfig);
            } else {
                setConfig(defaultConfig);
            }
        } catch (e: any) {
            setError(e.message);
        } finally {
            setLoading(false);
        }
    };

    const handleSave = async () => {
        setSaving(true);
        setSuccess(null);
        setError(null);

        try {
            const docRef = doc(db, 'ai_config', 'settings');
            await setDoc(docRef, {
                ...config,
                updatedAt: serverTimestamp(),
            });
            setSuccess('AI configuration saved successfully!');
        } catch (e: any) {
            setError(e.message);
        } finally {
            setSaving(false);
        }
    };

    const handleTestAPI = async () => {
        setTesting(true);
        setError(null);
        setTestResponse('');

        try {
            // Remove 'models/' prefix if present
            let modelName = config.model;
            if (modelName.startsWith('models/')) {
                modelName = modelName.replace('models/', '');
            }

            const apiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${config.apiKey}`;

            const response = await fetch(apiUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    contents: [
                        {
                            parts: [
                                {
                                    text: 'Say "Hey" to test the connection.',
                                },
                            ],
                        },
                    ],
                }),
            });

            if (response.ok) {
                const data = await response.json();
                const aiResponse = data.candidates?.[0]?.content?.parts?.[0]?.text || 'No response';
                setTestResponse(aiResponse);
                setTestDialogOpen(true);
            } else {
                const errorData = await response.json();
                const errorMessage = errorData.error?.message || 'Unknown error';
                setError(`API Test Failed: ${errorMessage}`);
            }
        } catch (e: any) {
            setError(`API Test Failed: ${e.message}`);
        } finally {
            setTesting(false);
        }
    };

    if (loading) {
        return <SkeletonLoader type="details" />;
    }

    return (
        <Box>
            <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" alignItems={{ xs: 'stretch', sm: 'center' }} spacing={2} sx={{ mb: 4 }}>
                <Typography variant="h5" sx={{ fontWeight: 'bold' }}>AI Configuration</Typography>
                <Button
                    variant="outlined"
                    startIcon={<Refresh />}
                    onClick={loadConfig}
                    sx={{ alignSelf: { xs: 'flex-start', sm: 'center' } }}
                >
                    Refresh
                </Button>
            </Stack>

            {success && <Alert severity="success" onClose={() => setSuccess(null)} sx={{ mb: 3 }}>{success}</Alert>}
            {error && <Alert severity="error" onClose={() => setError(null)} sx={{ mb: 3 }}>{error}</Alert>}

            {/* Quota Warning */}
            <Alert severity="info" sx={{ mb: 3 }}>
                <Typography variant="body2" sx={{ fontWeight: 'bold', mb: 1 }}>
                    Important: API Setup & Model Information
                </Typography>
                <Typography variant="body2" component="div">
                    • <strong>Get API Key:</strong> <a href="https://aistudio.google.com/apikey" target="_blank" rel="noopener noreferrer" style={{ color: '#1976d2', textDecoration: 'underline' }}>https://aistudio.google.com/apikey</a><br/>
                    • <strong>View Available Models:</strong> <a href="https://ai.google.dev/gemini-api/docs/models" target="_blank" rel="noopener noreferrer" style={{ color: '#1976d2', textDecoration: 'underline' }}>Gemini Models Documentation</a><br/>
                    • <strong>Enable Billing (if quota exceeded):</strong> <a href="https://console.cloud.google.com/billing" target="_blank" rel="noopener noreferrer" style={{ color: '#1976d2', textDecoration: 'underline' }}>Google Cloud Console</a><br/>
                    • <strong>Rate Limits Info:</strong> <a href="https://ai.google.dev/gemini-api/docs/rate-limits" target="_blank" rel="noopener noreferrer" style={{ color: '#1976d2', textDecoration: 'underline' }}>Rate Limits Documentation</a><br/>
                    • <strong>Recommended:</strong> gemini-2.5-flash (best price/performance for production)<br/>
                    • <strong>Note:</strong> If quota exceeded, create a NEW API key or enable billing
                </Typography>
            </Alert>

            <Paper sx={{ p: { xs: 2, sm: 4 }, borderRadius: 3 }}>
                <Grid container spacing={3}>
                    {/* AI Enable/Disable */}
                    <Grid item xs={12}>
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
                            <Typography variant="h6">AI Service Status</Typography>
                            <FormControlLabel
                                control={
                                    <Switch
                                        checked={config.enabled}
                                        onChange={(e) => setConfig({ ...config, enabled: e.target.checked })}
                                        color="primary"
                                    />
                                }
                                label={config.enabled ? 'Enabled' : 'Disabled'}
                            />
                        </Box>
                        <Divider sx={{ mb: 2 }} />
                    </Grid>

                    {/* API Key */}
                    <Grid item xs={12}>
                        <Typography variant="h6" gutterBottom>API Configuration</Typography>
                        <Divider sx={{ mb: 2 }} />
                    </Grid>

                    <Grid item xs={12} md={6}>
                        <TextField
                            fullWidth
                            label="API Key"
                            value={config.apiKey}
                            onChange={(e) => setConfig({ ...config, apiKey: e.target.value })}
                            helperText="Your Gemini API key (Get it from https://aistudio.google.com/apikey)"
                            type={showApiKey ? 'text' : 'password'}
                            InputProps={{
                                endAdornment: (
                                    <InputAdornment position="end">
                                        <IconButton
                                            onClick={() => setShowApiKey(!showApiKey)}
                                            edge="end"
                                        >
                                            {showApiKey ? <VisibilityOff /> : <Visibility />}
                                        </IconButton>
                                    </InputAdornment>
                                ),
                            }}
                        />
                    </Grid>

                    <Grid item xs={12} md={6}>
                        <TextField
                            fullWidth
                            select
                            label="Model Selection"
                            value={config.model}
                            onChange={(e) => setConfig({ ...config, model: e.target.value })}
                            helperText="Select Gemini model (Stable models recommended for production)"
                        >
                            <MenuItem value="gemini-2.5-flash">gemini-2.5-flash (Recommended - Best price/performance)</MenuItem>
                            <MenuItem value="gemini-2.5-flash-lite">gemini-2.5-flash-lite (Fastest & Budget-friendly)</MenuItem>
                            <MenuItem value="gemini-2.5-pro">gemini-2.5-pro (Most Advanced - Complex tasks)</MenuItem>
                            <MenuItem value="gemini-3-flash">gemini-3-flash (Preview - Frontier performance)</MenuItem>
                            <MenuItem value="gemini-1.5-flash">gemini-1.5-flash (Legacy - Stable)</MenuItem>
                            <MenuItem value="gemini-1.5-pro">gemini-1.5-pro (Legacy - Stable)</MenuItem>
                        </TextField>
                    </Grid>

                    {/* Test API Button */}
                    <Grid item xs={12}>
                        <Button
                            variant="outlined"
                            color="primary"
                            startIcon={testing ? <CircularProgress size={20} /> : <CheckCircle />}
                            onClick={handleTestAPI}
                            disabled={testing || !config.apiKey}
                            sx={{ mt: 1 }}
                        >
                            {testing ? 'Testing API...' : 'Test API Key'}
                        </Button>
                    </Grid>

                    {/* Generation Parameters */}
                    <Grid item xs={12} sx={{ mt: 3 }}>
                        <Typography variant="h6" gutterBottom>Generation Parameters</Typography>
                        <Divider sx={{ mb: 2 }} />
                    </Grid>

                    <Grid item xs={12} md={3}>
                        <TextField
                            fullWidth
                            type="number"
                            label="Max Tokens"
                            value={config.maxTokens}
                            onChange={(e) => setConfig({ ...config, maxTokens: Number(e.target.value) })}
                            helperText="Maximum output tokens"
                            inputProps={{ min: 1, max: 8192 }}
                        />
                    </Grid>

                    <Grid item xs={12} md={3}>
                        <TextField
                            fullWidth
                            type="number"
                            label="Temperature"
                            value={config.temperature}
                            onChange={(e) => setConfig({ ...config, temperature: Number(e.target.value) })}
                            helperText="0.0 - 2.0"
                            inputProps={{ min: 0, max: 2, step: 0.1 }}
                        />
                    </Grid>

                    <Grid item xs={12} md={3}>
                        <TextField
                            fullWidth
                            type="number"
                            label="Top K"
                            value={config.topK}
                            onChange={(e) => setConfig({ ...config, topK: Number(e.target.value) })}
                            helperText="1 - 100"
                            inputProps={{ min: 1, max: 100 }}
                        />
                    </Grid>

                    <Grid item xs={12} md={3}>
                        <TextField
                            fullWidth
                            type="number"
                            label="Top P"
                            value={config.topP}
                            onChange={(e) => setConfig({ ...config, topP: Number(e.target.value) })}
                            helperText="0.0 - 1.0"
                            inputProps={{ min: 0, max: 1, step: 0.05 }}
                        />
                    </Grid>

                    {/* Safety Settings */}
                    <Grid item xs={12} sx={{ mt: 3 }}>
                        <Typography variant="h6" gutterBottom>Safety Settings</Typography>
                        <Divider sx={{ mb: 2 }} />
                    </Grid>

                    <Grid item xs={12} md={6}>
                        <TextField
                            fullWidth
                            select
                            label="Dangerous Content"
                            value={config.safetySettings.dangerousContent}
                            onChange={(e) => setConfig({
                                ...config,
                                safetySettings: { ...config.safetySettings, dangerousContent: e.target.value }
                            })}
                        >
                            {safetyLevels.map((level) => (
                                <MenuItem key={level} value={level}>{level}</MenuItem>
                            ))}
                        </TextField>
                    </Grid>

                    <Grid item xs={12} md={6}>
                        <TextField
                            fullWidth
                            select
                            label="Harassment"
                            value={config.safetySettings.harassment}
                            onChange={(e) => setConfig({
                                ...config,
                                safetySettings: { ...config.safetySettings, harassment: e.target.value }
                            })}
                        >
                            {safetyLevels.map((level) => (
                                <MenuItem key={level} value={level}>{level}</MenuItem>
                            ))}
                        </TextField>
                    </Grid>

                    <Grid item xs={12} md={6}>
                        <TextField
                            fullWidth
                            select
                            label="Hate Speech"
                            value={config.safetySettings.hateSpeech}
                            onChange={(e) => setConfig({
                                ...config,
                                safetySettings: { ...config.safetySettings, hateSpeech: e.target.value }
                            })}
                        >
                            {safetyLevels.map((level) => (
                                <MenuItem key={level} value={level}>{level}</MenuItem>
                            ))}
                        </TextField>
                    </Grid>

                    <Grid item xs={12} md={6}>
                        <TextField
                            fullWidth
                            select
                            label="Sexually Explicit"
                            value={config.safetySettings.sexuallyExplicit}
                            onChange={(e) => setConfig({
                                ...config,
                                safetySettings: { ...config.safetySettings, sexuallyExplicit: e.target.value }
                            })}
                        >
                            {safetyLevels.map((level) => (
                                <MenuItem key={level} value={level}>{level}</MenuItem>
                            ))}
                        </TextField>
                    </Grid>

                    {/* System Instruction */}
                    <Grid item xs={12} sx={{ mt: 3 }}>
                        <Typography variant="h6" gutterBottom>System Instruction</Typography>
                        <Divider sx={{ mb: 2 }} />
                    </Grid>

                    <Grid item xs={12}>
                        <TextField
                            fullWidth
                            multiline
                            rows={6}
                            label="System Instruction"
                            value={config.systemInstruction}
                            onChange={(e) => setConfig({ ...config, systemInstruction: e.target.value })}
                            helperText="The AI's role and behavior instructions"
                        />
                    </Grid>

                    {/* Save Button */}
                    <Grid item xs={12} sx={{ mt: 2 }}>
                        <Button
                            variant="contained"
                            size="large"
                            startIcon={saving ? <CircularProgress size={20} color="inherit" /> : <Save />}
                            onClick={handleSave}
                            disabled={saving}
                            sx={{ minWidth: 200 }}
                        >
                            {saving ? 'Saving...' : 'Save Configuration'}
                        </Button>
                    </Grid>
                </Grid>
            </Paper>

            {/* Test Response Dialog */}
            <Dialog open={testDialogOpen} onClose={() => setTestDialogOpen(false)} maxWidth="sm" fullWidth>
                <DialogTitle>API Test Successful</DialogTitle>
                <DialogContent>
                    <Alert severity="success" sx={{ mb: 2 }}>
                        API Key and Model are working correctly!
                    </Alert>
                    <Typography variant="body2" color="text.secondary" gutterBottom>
                        Response from AI:
                    </Typography>
                    <Paper sx={{ p: 2, bgcolor: 'grey.100' }}>
                        <Typography variant="body1">{testResponse}</Typography>
                    </Paper>
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setTestDialogOpen(false)} variant="contained">
                        Close
                    </Button>
                </DialogActions>
            </Dialog>
        </Box>
    );
};

export default AIConfigPage;
