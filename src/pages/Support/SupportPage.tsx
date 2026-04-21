import React, { useState, useEffect } from 'react';
import {
    Box, Typography, Paper, Tabs, Tab, Table, TableBody, TableCell,
    TableContainer, TableHead, TableRow, Chip, IconButton, Dialog,
    DialogTitle, DialogContent, DialogActions, Button, TextField,
    Alert, MenuItem, Grid, Stack
} from '@mui/material';
import SkeletonLoader from '../../components/Layout/SkeletonLoader';
import {
    Visibility, Delete, Refresh, Add, Edit as EditIcon
} from '@mui/icons-material';
import { collection, getDocs, doc, updateDoc, deleteDoc, addDoc } from 'firebase/firestore';
import { db } from '../../services/firebase';

interface SupportMessage {
    id: string;
    userId?: string;
    name: string;
    email: string;
    message: string;
    timestamp: any;
    status: 'pending' | 'resolved' | 'in-progress';
}

interface BugReport {
    id: string;
    userId?: string;
    title: string;
    description: string;
    timestamp: any;
    status: 'pending' | 'resolved' | 'in-progress';
}

interface FAQ {
    id: string;
    question: string;
    answer: string;
    order: number;
}

const SupportPage: React.FC = () => {
    const [tabValue, setTabValue] = useState(0);
    const [supportMessages, setSupportMessages] = useState<SupportMessage[]>([]);
    const [bugReports, setBugReports] = useState<BugReport[]>([]);
    const [faqs, setFaqs] = useState<FAQ[]>([]);
    const [loading, setLoading] = useState(true);
    const [selectedItem, setSelectedItem] = useState<any>(null);
    const [viewDialogOpen, setViewDialogOpen] = useState(false);
    const [faqDialogOpen, setFaqDialogOpen] = useState(false);
    const [editingFaq, setEditingFaq] = useState<FAQ | null>(null);
    const [success, setSuccess] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        loadData();
    }, []);

    const loadData = async () => {
        setLoading(true);
        try {
            await Promise.all([
                loadSupportMessages(),
                loadBugReports(),
                loadFAQs(),
            ]);
        } catch (e: any) {
            setError(e.message);
        } finally {
            setLoading(false);
        }
    };

    const loadSupportMessages = async () => {
        try {
            const snapshot = await getDocs(
                collection(db, 'admin', 'support_messages', 'submissions')
            );
            const messages: SupportMessage[] = [];
            snapshot.forEach((doc) => {
                messages.push({ id: doc.id, ...doc.data() } as SupportMessage);
            });
            messages.sort((a, b) => {
                const aTime = a.timestamp?.toMillis() || 0;
                const bTime = b.timestamp?.toMillis() || 0;
                return bTime - aTime;
            });
            setSupportMessages(messages);
        } catch (e: any) {
            console.error('Error loading support messages:', e);
        }
    };

    const loadBugReports = async () => {
        try {
            const snapshot = await getDocs(
                collection(db, 'admin', 'bug_reports', 'submissions')
            );
            const bugs: BugReport[] = [];
            snapshot.forEach((doc) => {
                bugs.push({ id: doc.id, ...doc.data() } as BugReport);
            });
            bugs.sort((a, b) => {
                const aTime = a.timestamp?.toMillis() || 0;
                const bTime = b.timestamp?.toMillis() || 0;
                return bTime - aTime;
            });
            setBugReports(bugs);
        } catch (e: any) {
            console.error('Error loading bug reports:', e);
        }
    };

    const loadFAQs = async () => {
        try {
            const snapshot = await getDocs(
                collection(db, 'admin', 'faqs', 'items')
            );
            const faqList: FAQ[] = [];
            snapshot.forEach((doc) => {
                faqList.push({ id: doc.id, ...doc.data() } as FAQ);
            });
            faqList.sort((a, b) => a.order - b.order);
            setFaqs(faqList);
        } catch (e: any) {
            console.error('Error loading FAQs:', e);
        }
    };

    const updateStatus = async (type: 'support' | 'bug', id: string, status: string) => {
        try {
            const collectionPath = type === 'support'
                ? 'admin/support_messages/submissions'
                : 'admin/bug_reports/submissions';
            await updateDoc(doc(db, collectionPath, id), { status });
            setSuccess('Status updated successfully!');
            await loadData();
        } catch (e: any) {
            setError(e.message);
        }
    };

    const deleteItem = async (type: 'support' | 'bug', id: string) => {
        if (!window.confirm('Are you sure you want to delete this item?')) return;
        try {
            const collectionPath = type === 'support'
                ? 'admin/support_messages/submissions'
                : 'admin/bug_reports/submissions';
            await deleteDoc(doc(db, collectionPath, id));
            setSuccess('Item deleted successfully!');
            await loadData();
        } catch (e: any) {
            setError(e.message);
        }
    };

    const saveFAQ = async (faq: Partial<FAQ>) => {
        try {
            if (editingFaq) {
                // Update existing FAQ
                await updateDoc(doc(db, 'admin', 'faqs', 'items', editingFaq.id), {
                    question: faq.question,
                    answer: faq.answer,
                    order: faq.order,
                });
                setSuccess('FAQ updated successfully!');
            } else {
                // Create new FAQ
                await addDoc(collection(db, 'admin', 'faqs', 'items'), {
                    question: faq.question,
                    answer: faq.answer,
                    order: faq.order || faqs.length + 1,
                });
                setSuccess('FAQ created successfully!');
            }
            setFaqDialogOpen(false);
            setEditingFaq(null);
            await loadFAQs();
        } catch (e: any) {
            setError(e.message);
        }
    };

    const deleteFAQ = async (id: string) => {
        if (!window.confirm('Are you sure you want to delete this FAQ?')) return;
        try {
            await deleteDoc(doc(db, 'admin', 'faqs', 'items', id));
            setSuccess('FAQ deleted successfully!');
            await loadFAQs();
        } catch (e: any) {
            setError(e.message);
        }
    };

    const formatDate = (timestamp: any) => {
        if (!timestamp) return 'N/A';
        try {
            return timestamp.toDate().toLocaleString();
        } catch {
            return 'N/A';
        }
    };

    const getStatusColor = (status: string) => {
        switch (status) {
            case 'pending': return 'warning';
            case 'in-progress': return 'info';
            case 'resolved': return 'success';
            default: return 'default';
        }
    };

    return (
        <Box>
            <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" alignItems={{ xs: 'stretch', sm: 'center' }} spacing={2} sx={{ mb: 4 }}>
                <Typography variant="h5" sx={{ fontWeight: 'bold' }}>Support & Help</Typography>
                <Button variant="outlined" startIcon={<Refresh />} onClick={loadData} sx={{ alignSelf: { xs: 'flex-start', sm: 'center' } }}>
                    Refresh
                </Button>
            </Stack>

            {success && <Alert severity="success" onClose={() => setSuccess(null)} sx={{ mb: 3 }}>{success}</Alert>}
            {error && <Alert severity="error" onClose={() => setError(null)} sx={{ mb: 3 }}>{error}</Alert>}

            <Paper sx={{ borderRadius: 3, overflow: 'hidden' }}>
                <Tabs value={tabValue} onChange={(_, v) => setTabValue(v)} variant="scrollable" scrollButtons="auto" sx={{ borderBottom: 1, borderColor: 'divider' }}>
                    <Tab label={`Support Messages (${supportMessages.length})`} />
                    <Tab label={`Bug Reports (${bugReports.length})`} />
                    <Tab label={`FAQs (${faqs.length})`} />
                </Tabs>

                <Box sx={{ p: 3 }}>
                    {loading ? (
                        <SkeletonLoader type="table" />
                    ) : (
                        <>
                            {/* Support Messages Tab */}
                            {tabValue === 0 && (
                                <TableContainer sx={{ overflowX: 'auto' }}>
                                    <Table sx={{ minWidth: 760 }}>
                                        <TableHead>
                                            <TableRow>
                                                <TableCell>Name</TableCell>
                                                <TableCell>Email</TableCell>
                                                <TableCell>Message</TableCell>
                                                <TableCell sx={{ display: { xs: 'none', md: 'table-cell' } }}>Date</TableCell>
                                                <TableCell>Status</TableCell>
                                                <TableCell>Actions</TableCell>
                                            </TableRow>
                                        </TableHead>
                                        <TableBody>
                                            {supportMessages.length === 0 ? (
                                                <TableRow>
                                                    <TableCell colSpan={6} align="center">No support messages</TableCell>
                                                </TableRow>
                                            ) : (
                                                supportMessages.map((msg) => (
                                                    <TableRow key={msg.id}>
                                                        <TableCell>{msg.name}</TableCell>
                                                        <TableCell>{msg.email}</TableCell>
                                                        <TableCell sx={{ maxWidth: 300 }}>
                                                            {msg.message.substring(0, 50)}...
                                                        </TableCell>
                                                        <TableCell sx={{ display: { xs: 'none', md: 'table-cell' } }}>{formatDate(msg.timestamp)}</TableCell>
                                                        <TableCell>
                                                            <TextField
                                                                select
                                                                size="small"
                                                                value={msg.status}
                                                                onChange={(e) => updateStatus('support', msg.id, e.target.value)}
                                                                sx={{ minWidth: 120 }}
                                                            >
                                                                <MenuItem value="pending">Pending</MenuItem>
                                                                <MenuItem value="in-progress">In Progress</MenuItem>
                                                                <MenuItem value="resolved">Resolved</MenuItem>
                                                            </TextField>
                                                        </TableCell>
                                                        <TableCell>
                                                            <IconButton
                                                                size="small"
                                                                onClick={() => {
                                                                    setSelectedItem(msg);
                                                                    setViewDialogOpen(true);
                                                                }}
                                                            >
                                                                <Visibility fontSize="small" />
                                                            </IconButton>
                                                            <IconButton
                                                                size="small"
                                                                color="error"
                                                                onClick={() => deleteItem('support', msg.id)}
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
                            )}

                            {/* Bug Reports Tab */}
                            {tabValue === 1 && (
                                <TableContainer sx={{ overflowX: 'auto' }}>
                                    <Table sx={{ minWidth: 700 }}>
                                        <TableHead>
                                            <TableRow>
                                                <TableCell>Title</TableCell>
                                                <TableCell>Description</TableCell>
                                                <TableCell sx={{ display: { xs: 'none', md: 'table-cell' } }}>Date</TableCell>
                                                <TableCell>Status</TableCell>
                                                <TableCell>Actions</TableCell>
                                            </TableRow>
                                        </TableHead>
                                        <TableBody>
                                            {bugReports.length === 0 ? (
                                                <TableRow>
                                                    <TableCell colSpan={5} align="center">No bug reports</TableCell>
                                                </TableRow>
                                            ) : (
                                                bugReports.map((bug) => (
                                                    <TableRow key={bug.id}>
                                                        <TableCell>{bug.title}</TableCell>
                                                        <TableCell sx={{ maxWidth: 300 }}>
                                                            {bug.description.substring(0, 50)}...
                                                        </TableCell>
                                                        <TableCell sx={{ display: { xs: 'none', md: 'table-cell' } }}>{formatDate(bug.timestamp)}</TableCell>
                                                        <TableCell>
                                                            <TextField
                                                                select
                                                                size="small"
                                                                value={bug.status}
                                                                onChange={(e) => updateStatus('bug', bug.id, e.target.value)}
                                                                sx={{ minWidth: 120 }}
                                                            >
                                                                <MenuItem value="pending">Pending</MenuItem>
                                                                <MenuItem value="in-progress">In Progress</MenuItem>
                                                                <MenuItem value="resolved">Resolved</MenuItem>
                                                            </TextField>
                                                        </TableCell>
                                                        <TableCell>
                                                            <IconButton
                                                                size="small"
                                                                onClick={() => {
                                                                    setSelectedItem(bug);
                                                                    setViewDialogOpen(true);
                                                                }}
                                                            >
                                                                <Visibility fontSize="small" />
                                                            </IconButton>
                                                            <IconButton
                                                                size="small"
                                                                color="error"
                                                                onClick={() => deleteItem('bug', bug.id)}
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
                            )}

                            {/* FAQs Tab */}
                            {tabValue === 2 && (
                                <>
                                    <Box sx={{ display: 'flex', justifyContent: 'flex-end', mb: 2 }}>
                                        <Button
                                            variant="contained"
                                            startIcon={<Add />}
                                            onClick={() => {
                                                setEditingFaq(null);
                                                setFaqDialogOpen(true);
                                            }}
                                        >
                                            Add FAQ
                                        </Button>
                                    </Box>
                                    {faqs.length === 0 ? (
                                        <Box sx={{ textAlign: 'center', py: 4 }}>
                                            <Typography color="text.secondary">No FAQs yet</Typography>
                                        </Box>
                                    ) : (
                                        faqs.map((faq) => (
                                            <Paper key={faq.id} sx={{ p: 2, mb: 2, bgcolor: 'grey.50' }}>
                                                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                                                    <Box sx={{ flex: 1 }}>
                                                        <Typography variant="subtitle1" fontWeight="bold" gutterBottom>
                                                            {faq.order}. {faq.question}
                                                        </Typography>
                                                        <Typography variant="body2" color="text.secondary">
                                                            {faq.answer}
                                                        </Typography>
                                                    </Box>
                                                    <Box>
                                                        <IconButton
                                                            size="small"
                                                            onClick={() => {
                                                                setEditingFaq(faq);
                                                                setFaqDialogOpen(true);
                                                            }}
                                                        >
                                                            <EditIcon fontSize="small" />
                                                        </IconButton>
                                                        <IconButton
                                                            size="small"
                                                            color="error"
                                                            onClick={() => deleteFAQ(faq.id)}
                                                        >
                                                            <Delete fontSize="small" />
                                                        </IconButton>
                                                    </Box>
                                                </Box>
                                            </Paper>
                                        ))
                                    )}
                                </>
                            )}
                        </>
                    )}
                </Box>
            </Paper>

            {/* View Details Dialog */}
            <Dialog open={viewDialogOpen} onClose={() => setViewDialogOpen(false)} maxWidth="sm" fullWidth>
                <DialogTitle>Details</DialogTitle>
                <DialogContent>
                    {selectedItem && (
                        <Box>
                            {selectedItem.name && (
                                <Box sx={{ mb: 2 }}>
                                    <Typography variant="subtitle2" color="text.secondary">Name</Typography>
                                    <Typography>{selectedItem.name}</Typography>
                                </Box>
                            )}
                            {selectedItem.email && (
                                <Box sx={{ mb: 2 }}>
                                    <Typography variant="subtitle2" color="text.secondary">Email</Typography>
                                    <Typography>{selectedItem.email}</Typography>
                                </Box>
                            )}
                            {selectedItem.title && (
                                <Box sx={{ mb: 2 }}>
                                    <Typography variant="subtitle2" color="text.secondary">Title</Typography>
                                    <Typography>{selectedItem.title}</Typography>
                                </Box>
                            )}
                            {selectedItem.message && (
                                <Box sx={{ mb: 2 }}>
                                    <Typography variant="subtitle2" color="text.secondary">Message</Typography>
                                    <Typography>{selectedItem.message}</Typography>
                                </Box>
                            )}
                            {selectedItem.description && (
                                <Box sx={{ mb: 2 }}>
                                    <Typography variant="subtitle2" color="text.secondary">Description</Typography>
                                    <Typography>{selectedItem.description}</Typography>
                                </Box>
                            )}
                            <Box sx={{ mb: 2 }}>
                                <Typography variant="subtitle2" color="text.secondary">Date</Typography>
                                <Typography>{formatDate(selectedItem.timestamp)}</Typography>
                            </Box>
                            <Box>
                                <Typography variant="subtitle2" color="text.secondary">Status</Typography>
                                <Chip label={selectedItem.status} color={getStatusColor(selectedItem.status)} size="small" />
                            </Box>
                        </Box>
                    )}
                </DialogContent>
                <DialogActions>
                    <Button onClick={() => setViewDialogOpen(false)}>Close</Button>
                </DialogActions>
            </Dialog>

            {/* FAQ Dialog */}
            <FAQDialog
                open={faqDialogOpen}
                faq={editingFaq}
                onClose={() => {
                    setFaqDialogOpen(false);
                    setEditingFaq(null);
                }}
                onSave={saveFAQ}
            />
        </Box>
    );
};

// FAQ Dialog Component
interface FAQDialogProps {
    open: boolean;
    faq: FAQ | null;
    onClose: () => void;
    onSave: (faq: Partial<FAQ>) => void;
}

const FAQDialog: React.FC<FAQDialogProps> = ({ open, faq, onClose, onSave }) => {
    const [question, setQuestion] = useState('');
    const [answer, setAnswer] = useState('');
    const [order, setOrder] = useState(1);

    useEffect(() => {
        if (faq) {
            setQuestion(faq.question);
            setAnswer(faq.answer);
            setOrder(faq.order);
        } else {
            setQuestion('');
            setAnswer('');
            setOrder(1);
        }
    }, [faq, open]);

    const handleSave = () => {
        if (!question.trim() || !answer.trim()) return;
        onSave({ question: question.trim(), answer: answer.trim(), order });
    };

    return (
        <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
            <DialogTitle>{faq ? 'Edit FAQ' : 'Add FAQ'}</DialogTitle>
            <DialogContent sx={{ px: { xs: 2, sm: 3 } }}>
                <Grid container spacing={2} sx={{ mt: 1 }}>
                    <Grid item xs={12}>
                        <TextField
                            fullWidth
                            label="Question"
                            value={question}
                            onChange={(e) => setQuestion(e.target.value)}
                            multiline
                            rows={2}
                        />
                    </Grid>
                    <Grid item xs={12}>
                        <TextField
                            fullWidth
                            label="Answer"
                            value={answer}
                            onChange={(e) => setAnswer(e.target.value)}
                            multiline
                            rows={4}
                        />
                    </Grid>
                    <Grid item xs={12}>
                        <TextField
                            fullWidth
                            type="number"
                            label="Order"
                            value={order}
                            onChange={(e) => setOrder(Number(e.target.value))}
                        />
                    </Grid>
                </Grid>
            </DialogContent>
            <DialogActions>
                <Button onClick={onClose}>Cancel</Button>
                <Button variant="contained" onClick={handleSave}>
                    {faq ? 'Update' : 'Create'}
                </Button>
            </DialogActions>
        </Dialog>
    );
};

export default SupportPage;
