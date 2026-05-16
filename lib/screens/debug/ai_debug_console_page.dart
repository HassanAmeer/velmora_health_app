import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velmora/services/debug_log_service.dart';
import 'package:velmora/services/gemini-ai.dart';
import 'package:velmora/services/claude-ai.dart';

class AiDebugConsolePage extends StatefulWidget {
  const AiDebugConsolePage({super.key});

  @override
  State<AiDebugConsolePage> createState() => _AiDebugConsolePageState();
}

class _AiDebugConsolePageState extends State<AiDebugConsolePage> {
  final DebugLogService _logService = DebugLogService();
  Map<String, dynamic>? _aiConfig;
  bool _isLoadingConfig = true;
  String? _configError;
  String _searchQuery = '';
  String _filterType = 'all';
  bool _isTesting = false;
  String? _testResult;
  String? _testError;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _logService.addListener(_onLogChanged);
  }

  @override
  void dispose() {
    _logService.removeListener(_onLogChanged);
    super.dispose();
  }

  void _onLogChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadConfig() async {
    setState(() {
      _isLoadingConfig = true;
      _configError = null;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ai_config')
          .doc('settings')
          .get();
      if (doc.exists) {
        _aiConfig = doc.data()!;
      } else {
        _configError = 'No AI config document found in Firestore';
      }
    } catch (e) {
      _configError = 'Failed to load config: $e';
    }
    if (mounted) setState(() => _isLoadingConfig = false);
  }

  Future<void> _testApi() async {
    if (_aiConfig == null) return;
    setState(() {
      _isTesting = true;
      _testResult = null;
      _testError = null;
    });
    try {
      final provider = (_aiConfig!['provider'] as String? ?? 'gemini')
          .toLowerCase();
      if (provider == 'claude') {
        final apiKey = _aiConfig!['claudeApiKey'] as String?;
        final model =
            _aiConfig!['claudeModel'] as String? ??
            'claude-sonnet-4-5-20250929';
        if (apiKey == null || apiKey.isEmpty) {
          throw Exception('Claude API key not configured');
        }
        final response = await ClaudeProvider.generateSimple(
          apiKey: apiKey,
          model: model,
          prompt: 'Reply with just: "OK"',
          maxTokens: 10,
          temperature: 0.0,
        );
        setState(() {
          _testResult = response;
          _testError = null;
          _isTesting = false;
        });
      } else {
        final apiKey = _aiConfig!['apiKey'] as String?;
        final model = _aiConfig!['model'] as String? ?? 'gemini-2.5-flash';
        if (apiKey == null || apiKey.isEmpty) {
          throw Exception('Gemini API key not configured');
        }
        final response = await GeminiProvider.generateSimple(
          apiKey: apiKey,
          model: model,
          prompt: 'Reply with just: "OK"',
          maxTokens: 10,
          temperature: 0.0,
        );
        setState(() {
          _testResult = response;
          _testError = null;
          _isTesting = false;
        });
      }
    } catch (e) {
      setState(() {
        _testError = e.toString();
        _testResult = null;
        _isTesting = false;
      });
    }
  }

  List<DebugLogEntry> get _filteredLogs {
    final logs = _logService.logs;
    if (_filterType == 'all' && _searchQuery.isEmpty) return logs;
    return logs.where((entry) {
      if (_filterType != 'all' && entry.type.name != _filterType) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!entry.summary.toLowerCase().contains(q) &&
            !entry.provider.toLowerCase().contains(q) &&
            !entry.model.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Debug Console'),
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConfig,
            tooltip: 'Refresh Config',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              _logService.clear();
              setState(() {});
            },
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildConfigCard(),
          _buildTestResult(),
          _buildFilterBar(),
          Expanded(child: _buildLogList()),
        ],
      ),
    );
  }

  Widget _buildConfigCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      height: 200,
      child: Card(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.settings, color: Colors.cyan[300], size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'AI Configuration (Firestore)',
                    style: TextStyle(
                      color: Colors.cyan[300],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  if (_isTesting)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  if (!_isTesting && _aiConfig != null)
                    IconButton(
                      icon: const Icon(Icons.play_arrow, size: 18),
                      tooltip: 'Test API',
                      onPressed: _testApi,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Colors.green[300],
                    ),
                  const SizedBox(width: 8),
                  if (_isLoadingConfig)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const Divider(color: Colors.grey),
              Expanded(
                child: SingleChildScrollView(
                  child: _configError != null
                      ? SelectableText(
                          _configError!,
                          style: TextStyle(
                            color: Colors.red[300],
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        )
                      : _aiConfig == null
                      ? const Text(
                          'No config loaded',
                          style: TextStyle(color: Colors.grey),
                        )
                      : _buildConfigFields(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _fieldLabels = {
    'provider': 'Provider',
    'model': 'Gemini Model',
    'apiKey': 'Gemini API Key',
    'claudeModel': 'Claude Model',
    'claudeApiKey': 'Claude API Key',
    'maxTokens': 'Max Tokens',
    'temperature': 'Temperature',
    'topK': 'TopK',
    'topP': 'TopP',
    'systemInstruction': 'System Instruction',
  };

  Widget _buildConfigFields() {
    final entries = <String>[];
    // enabled — dynamic label based on provider
    if (_aiConfig!.containsKey('enabled') &&
        _aiConfig!.containsKey('provider')) {
      final provider = _aiConfig!['provider']?.toString() ?? 'gemini';
      final prefix = provider == 'claude' ? 'Claude' : 'Gemini';
      entries.add('$prefix Enabled: ${_aiConfig!['enabled']}');
    }
    for (final k in _fieldLabels.keys) {
      if (_aiConfig!.containsKey(k)) {
        final val = (k == 'apiKey' || k == 'claudeApiKey')
            ? _maskKey(_aiConfig![k]?.toString() ?? '')
            : _aiConfig![k]?.toString() ?? 'null';
        entries.add('${_fieldLabels[k]}: $val');
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((line) {
        final colon = line.indexOf(':');
        final label = line.substring(0, colon);
        final val = line.substring(colon + 1);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.amber[200],
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(
                  val,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _maskKey(String key) {
    if (key.length <= 8) return '***';
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }

  Widget _buildTestResult() {
    if (_testResult == null && _testError == null)
      return const SizedBox.shrink();
    final provider = (_aiConfig?['provider'] as String? ?? 'gemini')
        .toLowerCase();
    final prefix = provider == 'claude' ? 'Claude' : 'Gemini';
    final model = provider == 'claude'
        ? (_aiConfig?['claudeModel'] as String? ?? 'claude-sonnet-4-5-20250929')
        : (_aiConfig?['model'] as String? ?? 'gemini-2.5-flash');
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Card(
        color: _testError != null ? Colors.red[900] : Colors.green[900],
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _testError != null ? Icons.error : Icons.check_circle,
                    size: 16,
                    color: _testError != null
                        ? Colors.red[300]
                        : Colors.green[300],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _testError != null ? 'Test Failed' : 'Test Succeeded',
                    style: TextStyle(
                      color: _testError != null
                          ? Colors.red[300]
                          : Colors.green[300],
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() {
                      _testResult = null;
                      _testError = null;
                    }),
                    child: Icon(Icons.close, size: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$prefix · $model',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              SelectableText(
                _testError ?? _testResult ?? '',
                style: TextStyle(
                  color: _testError != null
                      ? Colors.red[200]
                      : Colors.green[200],
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: DropdownButtonFormField<String>(
              value: _filterType,
              isExpanded: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                border: OutlineInputBorder(),
                isDense: true,
                labelStyle: TextStyle(fontSize: 12),
              ),
              style: const TextStyle(fontSize: 12),
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Text(
                    'All',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                DropdownMenuItem(
                  value: 'request',
                  child: Text(
                    'Requests',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                DropdownMenuItem(
                  value: 'response',
                  child: Text(
                    'Responses',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                DropdownMenuItem(
                  value: 'error',
                  child: Text(
                    'Errors',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _filterType = v ?? 'all'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Search logs...',
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${_filteredLogs.length}',
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    final logs = _filteredLogs;
    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _filterType != 'all'
                  ? 'No matching logs'
                  : 'No AI calls yet',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 4),
            Text(
              'Trigger an AI request in the app',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final entry = logs[index];
        return _buildLogCard(entry);
      },
    );
  }

  Widget _buildLogCard(DebugLogEntry entry) {
    final typeColor = switch (entry.type) {
      DebugLogType.request => Colors.blue,
      DebugLogType.response => Colors.green,
      DebugLogType.error => Colors.red,
    };
    final icon = switch (entry.type) {
      DebugLogType.request => Icons.arrow_upward,
      DebugLogType.response => Icons.arrow_downward,
      DebugLogType.error => Icons.error,
    };

    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 4),
      child: ExpansionTile(
        dense: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        leading: Icon(icon, color: typeColor, size: 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: typeColor.withAlpha(30),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                entry.provider,
                style: TextStyle(
                  color: typeColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                entry.model,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              entry.formattedTime,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 9,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        subtitle: Text(
          entry.summary,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          ...entry.details.entries.map((e) {
            final val = e.value is String
                ? e.value as String
                : e.value.toString();
            return Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${e.key}:',
                      style: TextStyle(
                        color: Colors.amber[200],
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      val.length > 500 ? '${val.substring(0, 500)}...' : val,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
