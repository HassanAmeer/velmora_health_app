import 'package:flutter/material.dart';
import 'package:velmora/services/error_cache_service.dart';

/// Diagnostic screen to view cached errors
/// Add this temporarily for debugging:
/// Navigator.push(context, MaterialPageRoute(builder: (_) => const ErrorDiagnosticScreen()));
class ErrorDiagnosticScreen extends StatefulWidget {
  const ErrorDiagnosticScreen({super.key});

  @override
  State<ErrorDiagnosticScreen> createState() => _ErrorDiagnosticScreenState();
}

class _ErrorDiagnosticScreenState extends State<ErrorDiagnosticScreen> {
  Map<String, String?> _lastError = {};
  List<String> _errorHistory = [];
  int _crashCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    setState(() => _isLoading = true);

    _lastError = await ErrorCacheService().getLastError();
    _errorHistory = await ErrorCacheService().getErrorHistory();
    _crashCount = await ErrorCacheService().getCrashCount();

    setState(() => _isLoading = false);
  }

  Future<void> _clearErrors() async {
    await ErrorCacheService().clearErrors();
    _loadDiagnostics();
  }

  Future<void> _printDiagnostics() async {
    await ErrorCacheService().printDiagnostics();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diagnostics printed to console'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Diagnostics'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDiagnostics,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearErrors,
            tooltip: 'Clear Errors',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Crash Count Card
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[700]),
                    const SizedBox(height: 8),
                    Text(
                      '$_crashCount',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                    const Text('Total Errors Caught'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Last Error Card
            if (_lastError['error'] != null) ...[
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bug_report, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Last Error',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildErrorField('Error', _lastError['error'] ?? ''),
                      _buildErrorField(
                        'Location',
                        _lastError['location'] ?? 'Unknown',
                      ),
                      _buildErrorField(
                        'Time',
                        _lastError['time'] ?? 'Unknown',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Stack Trace:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: SelectableText(
                          _lastError['stack'] ?? 'No stack trace',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Error History Card
            if (_errorHistory.isNotEmpty) ...[
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.history, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Error History (${_errorHistory.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _errorHistory.length,
                        separatorBuilder: (_, __) => const Divider(height: 8),
                        itemBuilder: (context, index) {
                          return SelectableText(
                            _errorHistory[index],
                            style: const TextStyle(fontFamily: 'monospace'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // No errors message
            if (_lastError.isEmpty && _errorHistory.isEmpty) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle,
                          size: 64, color: Colors.green[700]),
                      const SizedBox(height: 16),
                      Text(
                        'No Errors Cached',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Great! No errors have been caught.',
                        style: TextStyle(color: Colors.green[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _printDiagnostics,
                    icon: const Icon(Icons.print),
                    label: const Text('Print to Console'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearErrors,
                    icon: const Icon(Icons.delete),
                    label: const Text('Clear All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Use',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Errors are automatically cached when they occur\n'
                      '2. This screen shows the last error and history\n'
                      '3. Use "Print to Console" for full stack traces\n'
                      '4. Use "Clear All" to reset after fixing issues',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[900],
              fontSize: 12,
            ),
          ),
          SelectableText(
            value,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}
