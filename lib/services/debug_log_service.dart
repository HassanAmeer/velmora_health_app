import 'package:flutter/foundation.dart';

enum DebugLogType { request, response, error }

class DebugLogEntry {
  final DateTime timestamp;
  final DebugLogType type;
  final String provider;
  final String model;
  final String summary;
  final Map<String, dynamic> details;

  DebugLogEntry({
    required this.timestamp,
    required this.type,
    required this.provider,
    required this.model,
    required this.summary,
    required this.details,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }
}

class DebugLogService {
  DebugLogService._();
  static final DebugLogService _instance = DebugLogService._();
  factory DebugLogService() => _instance;

  final List<DebugLogEntry> _logs = [];
  final List<void Function()> _listeners = [];

  void addLog(DebugLogEntry entry) {
    _logs.insert(0, entry);
    debugPrint('[DebugLog] ${entry.type.name.toUpperCase()} | ${entry.provider} | ${entry.model} | ${entry.summary}');
    for (final listener in _listeners) {
      listener();
    }
  }

  List<DebugLogEntry> get logs => List.unmodifiable(_logs);

  void clear() {
    _logs.clear();
    for (final listener in _listeners) {
      listener();
    }
  }

  void addListener(void Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }
}
