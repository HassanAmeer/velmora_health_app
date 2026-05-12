import React, { useState, useEffect } from 'react';
import {
    Box, Typography, TextField, Button, Paper, Grid,
    CircularProgress, Alert, MenuItem, Divider, InputAdornment, IconButton, Switch, FormControlLabel, Stack, Dialog, DialogTitle, DialogContent, DialogActions, Chip
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
    provider: 'gemini' | 'claude';
    // Gemini specific
    apiKey: string;
    model: string;
    safetySettings: SafetySettings;
    topK: number;
    topP: number;
    // Claude specific
    claudeApiKey: string;
    claudeModel: string;
    // Common
    maxTokens: number;
    systemInstruction: string;
    temperature: number;
}

const defaultConfig: AIConfig = {
    enabled: true,
    provider: 'gemini',
    apiKey: 'PLACEHOLDER_KEY',
    maxTokens: 500,
    model: 'gemini-2.5-flash',
    safetySettings: {
        dangerousContent: 'BLOCK_MEDIUM_AND_ABOVE',
        harassment: 'BLOCK_MEDIUM_AND_ABOVE',
        hateSpeech: 'BLOCK_MEDIUM_AND_ABOVE',
        sexuallyExplicit: 'BLOCK_MEDIUM_AND_ABOVE',
    },
    claudeApiKey: '',
    claudeModel: 'claude-3-5-sonnet-20240620',
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
    const [showClaudeApiKey, setShowClaudeApiKey] = useState(false);
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
                const data = docSnap.data();
                setConfig({
                    ...defaultConfig,
                    ...data,
                    safetySettings: {
                        ...defaultConfig.safetySettings,
                        ...(data.safetySettings || {}),
                    }
                } as AIConfig);
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
            if (config.provider === 'gemini') {
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
                    setError(`Gemini API Test Failed: ${errorMessage}`);
                }
            } else {
                // Claude Test (Anthropic API often requires a proxy due to CORS in browser, 
                // but we'll try direct or show a note)
                setError("Claude API testing from browser may be blocked by CORS. Please save and test from the app.");
                
                // Optional: Attempting Claude test (might fail CORS)
                /*
                const response = await fetch('https://api.anthropic.com/v1/messages', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'x-api-key': config.claudeApiKey,
                        'anthropic-version': '2023-06-01'
                    },
                    body: JSON.stringify({
                        model: config.claudeModel,
                        max_tokens: 10,
                        messages: [{ role: 'user', content: 'Say "Hey" to test.' }]
                    })
                });
                */
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
                    • <strong>Gemini API Key:</strong> <a href="https://aistudio.google.com/apikey" target="_blank" rel="noopener noreferrer" style={{ color: '#1976d2', textDecoration: 'underline' }}>https://aistudio.google.com/apikey</a><br/>
                    • <strong>Claude API Key:</strong> <a href="https://console.anthropic.com/" target="_blank" rel="noopener noreferrer" style={{ color: '#1976d2', textDecoration: 'underline' }}>https://console.anthropic.com/</a><br/>
                    • <strong>Gemini Models:</strong> gemini-2.5-flash (Best price/performance)<br/>
                    • <strong>Claude Models:</strong> claude-3-5-sonnet-20240620 (Most capable)<br/>
                    • <strong>Note:</strong> Active provider will be used in the mobile app.
                </Typography>
            </Alert>

            <Paper sx={{ p: { xs: 2, sm: 4 }, borderRadius: 3 }}>
                <Grid container spacing={3}>
                    {/* AI Enable/Disable */}
                    <Grid item xs={12} md={6}>
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
                    </Grid>

                    {/* Provider Selection */}
                    <Grid item xs={12} md={6}>
                        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
                            <Typography variant="h6">Active AI Provider</Typography>
                            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                                <Typography variant="body2" color={config.provider === 'gemini' ? 'primary' : 'textSecondary'}>Gemini</Typography>
                                <Switch
                                    checked={config.provider === 'claude'}
                                    onChange={(e) => setConfig({ ...config, provider: e.target.checked ? 'claude' : 'gemini' })}
                                    color="secondary"
                                />
                                <Typography variant="body2" color={config.provider === 'claude' ? 'secondary' : 'textSecondary'}>Claude</Typography>
                            </Box>
                        </Box>
                    </Grid>

                    <Grid item xs={12}>
                        <Divider sx={{ mb: 2 }} />
                    </Grid>

                    {/* Gemini Settings */}
                    {config.provider === 'gemini' && (
                        <>
                            <Grid item xs={12}>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                    <Typography variant="h6">Gemini Configuration</Typography>
                                    <Chip label="Active" color="primary" size="small" />
                                </Box>
                            </Grid>

                            <Grid item xs={12} md={6}>
                                <TextField
                                    fullWidth
                                    label="Gemini API Key"
                                    value={config.apiKey}
                                    onChange={(e) => setConfig({ ...config, apiKey: e.target.value })}
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
                                    label="Gemini Model"
                                    value={config.model}
                                    onChange={(e) => setConfig({ ...config, model: e.target.value })}
                                >
                                    <MenuItem value="gemini-2.5-flash">gemini-2.5-flash (Recommended)</MenuItem>
                                    <MenuItem value="gemini-2.5-pro">gemini-2.5-pro (Advanced)</MenuItem>
                                    <MenuItem value="gemini-1.5-flash">gemini-1.5-flash (Stable)</MenuItem>
                                </TextField>
                            </Grid>
                        </>
                    )}

                    {/* Claude Settings */}
                    {config.provider === 'claude' && (
                        <>
                            <Grid item xs={12} sx={{ mt: config.provider === 'claude' ? 0 : 2 }}>
                                <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                                    <Typography variant="h6">Claude Configuration</Typography>
                                    <Chip label="Active" color="secondary" size="small" />
                                </Box>
                            </Grid>

                            <Grid item xs={12} md={6}>
                                <TextField
                                    fullWidth
                                    label="Claude API Key"
                                    value={config.claudeApiKey}
                                    onChange={(e) => setConfig({ ...config, claudeApiKey: e.target.value })}
                                    type={showClaudeApiKey ? 'text' : 'password'}
                                    InputProps={{
                                        endAdornment: (
                                            <InputAdornment position="end">
                                                <IconButton
                                                    onClick={() => setShowClaudeApiKey(!showClaudeApiKey)}
                                                    edge="end"
                                                >
                                                    {showClaudeApiKey ? <VisibilityOff /> : <Visibility />}
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
                                    label="Claude Model"
                                    value={config.claudeModel}
                                    onChange={(e) => setConfig({ ...config, claudeModel: e.target.value })}
                                >
                                    <MenuItem value="claude-3-5-sonnet-20240620">claude-3-5-sonnet-20240620 (Recommended)</MenuItem>
                                    <MenuItem value="claude-3-opus-20240229">claude-3-opus (Most Advanced)</MenuItem>
                                    <MenuItem value="claude-3-haiku-20240307">claude-3-haiku (Fastest)</MenuItem>
                                </TextField>
                            </Grid>
                        </>
                    )}

                    {/* Test API Button */}
                    <Grid item xs={12}>
                        <Button
                            variant="outlined"
                            color="primary"
                            startIcon={testing ? <CircularProgress size={20} /> : <CheckCircle />}
                            onClick={handleTestAPI}
                            disabled={testing || (config.provider === 'gemini' && !config.apiKey) || (config.provider === 'claude' && !config.claudeApiKey)}
                            sx={{ mt: 1 }}
                        >
                            {testing ? 'Testing API...' : `Test ${config.provider === 'gemini' ? 'Gemini' : 'Claude'} API`}
                        </Button>
                    </Grid>

                    {/* Common Parameters */}
                    <Grid item xs={12} sx={{ mt: 3 }}>
                        <Typography variant="h6" gutterBottom>Generation Parameters (Common)</Typography>
                        <Divider sx={{ mb: 2 }} />
                    </Grid>

                    <Grid item xs={12} md={4}>
                        <TextField
                            fullWidth
                            type="number"
                            label="Max Tokens"
                            value={config.maxTokens}
                            onChange={(e) => setConfig({ ...config, maxTokens: Number(e.target.value) })}
                            inputProps={{ min: 1, max: 8192 }}
                        />
                    </Grid>

                    <Grid item xs={12} md={4}>
                        <TextField
                            fullWidth
                            type="number"
                            label="Temperature"
                            value={config.temperature}
                            onChange={(e) => setConfig({ ...config, temperature: Number(e.target.value) })}
                            helperText="0.0 - 2.0 (Gemini) / 0.0 - 1.0 (Claude)"
                            inputProps={{ min: 0, max: 2, step: 0.1 }}
                        />
                    </Grid>

                    {/* Gemini Specific Params Section */}
                    {config.provider === 'gemini' && (
                        <>
                            <Grid item xs={12} md={2}>
                                <TextField
                                    fullWidth
                                    type="number"
                                    label="Top K"
                                    value={config.topK}
                                    onChange={(e) => setConfig({ ...config, topK: Number(e.target.value) })}
                                    inputProps={{ min: 1, max: 100 }}
                                />
                            </Grid>

                            <Grid item xs={12} md={2}>
                                <TextField
                                    fullWidth
                                    type="number"
                                    label="Top P"
                                    value={config.topP}
                                    onChange={(e) => setConfig({ ...config, topP: Number(e.target.value) })}
                                    inputProps={{ min: 0, max: 1, step: 0.05 }}
                                />
                            </Grid>

                            <Grid item xs={12} sx={{ mt: 3 }}>
                                <Typography variant="h6" gutterBottom>Gemini Safety Settings</Typography>
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
                        </>
                    )}

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
                            helperText="The AI's role and behavior instructions (Applied to both providers)"
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
                        {config.provider === 'gemini' ? 'Gemini' : 'Claude'} API Key and Model are working correctly!
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
