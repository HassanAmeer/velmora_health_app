import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;

/// MigrationService reads the bundled [lib/migration/migration.json] file
/// and uploads / merges every collection into Firebase Firestore.
///
/// Collections handled:
///   users/{uid}                   — main user document (merge)
///   users/{uid}/chatMessages      — AI copilot chat history (set per doc)
///   games/{docId}                 — global games catalog (set per doc)
///   game_questions/{docId}        — all game questions   (set per doc)
///   user_game_progress/{uid}      — per-user progress    (merge)
///   user_games/{docId}            — game sessions        (set per doc)
class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _assetPath = 'lib/migration/migration.json';

  String? get _uid => _auth.currentUser?.uid;
  String? get _email => _auth.currentUser?.email;

  // ───────────────────────────────────────────────────────────────────────────
  // Public entry point — called by the UI button
  // ───────────────────────────────────────────────────────────────────────────

  /// Reads [lib/migration/migration.json], resolves __CURRENT_USER_UID__
  /// placeholders, then uploads every collection to Firestore.
  ///
  /// Returns a summary string for the UI to display.
  /// Throws a descriptive [String] on error.
  Future<MigrationResult> uploadMigrationData() async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) {
      throw 'User is not authenticated. Please sign in and try again.';
    }

    // 1 ─ Load the asset JSON
    final raw = await rootBundle.loadString(_assetPath);

    // 2 ─ Replace UID / email placeholders
    final resolved = raw
        .replaceAll('__CURRENT_USER_UID__', uid)
        .replaceAll('__CURRENT_USER_EMAIL__', _email ?? '');

    final json = jsonDecode(resolved) as Map<String, dynamic>;
    final collections = (json['collections'] as Map<String, dynamic>?) ?? {};

    int totalDocs = 0;
    final List<String> uploaded = [];
    final List<String> errors = [];

    // 3 ─ users
    final usersSection = collections['users'] as Map<String, dynamic>?;
    if (usersSection != null) {
      final r = await _uploadUserDocuments(uid, usersSection);
      totalDocs += r.count;
      if (r.count > 0) uploaded.add('users (${r.count} doc)');
      if (r.error != null) errors.add('users: ${r.error}');
    }

    // 4 ─ chatMessages (subcollection of users/{uid})
    final chatSection = collections['chatMessages'] as Map<String, dynamic>?;
    if (chatSection != null) {
      final r = await _uploadSubcollection(
        'users/$uid/chatMessages',
        chatSection,
      );
      totalDocs += r.count;
      if (r.count > 0) uploaded.add('chatMessages (${r.count} docs)');
      if (r.error != null) errors.add('chatMessages: ${r.error}');
    }

    // 5 ─ games (global collection)
    final gamesSection = collections['games'] as Map<String, dynamic>?;
    if (gamesSection != null) {
      final r = await _uploadTopLevelCollection('games', gamesSection);
      totalDocs += r.count;
      if (r.count > 0) uploaded.add('games (${r.count} docs)');
      if (r.error != null) errors.add('games: ${r.error}');
    }

    // 6 ─ game_questions (global collection)
    final questionsSection =
        collections['game_questions'] as Map<String, dynamic>?;
    if (questionsSection != null) {
      final r = await _uploadTopLevelCollection(
        'game_questions',
        questionsSection,
      );
      totalDocs += r.count;
      if (r.count > 0) uploaded.add('game_questions (${r.count} docs)');
      if (r.error != null) errors.add('game_questions: ${r.error}');
    }

    // 7 ─ user_game_progress/{uid}
    final progressSection =
        collections['user_game_progress'] as Map<String, dynamic>?;
    if (progressSection != null) {
      final r = await _uploadUserGameProgress(uid, progressSection);
      totalDocs += r.count;
      if (r.count > 0) uploaded.add('user_game_progress (${r.count} doc)');
      if (r.error != null) errors.add('user_game_progress: ${r.error}');
    }

    // 8 ─ user_games (global collection, filtered docs)
    final userGamesSection = collections['user_games'] as Map<String, dynamic>?;
    if (userGamesSection != null) {
      final r = await _uploadTopLevelCollection('user_games', userGamesSection);
      totalDocs += r.count;
      if (r.count > 0) uploaded.add('user_games (${r.count} docs)');
      if (r.error != null) errors.add('user_games: ${r.error}');
    }

    // 9 ─ kegel_daily_completions (subcollection of users/{uid})
    final kegelDailySection =
        collections['kegel_daily_completions'] as Map<String, dynamic>?;
    print('DEBUG: kegelDailySection = $kegelDailySection');
    if (kegelDailySection != null) {
      print(
        'DEBUG: Uploading kegel_daily_completions to users/$uid/kegel_daily_completions',
      );
      final r = await _uploadSubcollection(
        'users/$uid/kegel_daily_completions',
        kegelDailySection,
      );
      print(
        'DEBUG: kegel_daily_completions uploaded: ${r.count} docs, error: ${r.error}',
      );
      totalDocs += r.count;
      if (r.count > 0) {
        uploaded.add('kegel_daily_completions (${r.count} docs)');
      }
      if (r.error != null) errors.add('kegel_daily_completions: ${r.error}');
    } else {
      print('DEBUG: kegelDailySection is NULL');
    }

    // 10 ─ kegel_sessions (subcollection of users/{uid})
    final kegelSessionsSection =
        collections['kegel_sessions'] as Map<String, dynamic>?;
    print('DEBUG: kegelSessionsSection = $kegelSessionsSection');
    if (kegelSessionsSection != null) {
      print('DEBUG: Uploading kegel_sessions to users/$uid/kegel_sessions');
      final r = await _uploadSubcollection(
        'users/$uid/kegel_sessions',
        kegelSessionsSection,
      );
      print(
        'DEBUG: kegel_sessions uploaded: ${r.count} docs, error: ${r.error}',
      );
      totalDocs += r.count;
      if (r.count > 0) uploaded.add('kegel_sessions (${r.count} docs)');
      if (r.error != null) errors.add('kegel_sessions: ${r.error}');
    } else {
      print('DEBUG: kegelSessionsSection is NULL');
    }

    // 11 ─ notifications (subcollection of users/{uid})
    final notificationsSection =
        collections['notifications'] as Map<String, dynamic>?;
    if (notificationsSection != null) {
      final r = await _uploadSubcollection(
        'users/$uid/notifications',
        notificationsSection,
      );
      totalDocs += r.count;
      if (r.count > 0) uploaded.add('notifications (${r.count} docs)');
      if (r.error != null) errors.add('notifications: ${r.error}');
    }

    return MigrationResult(
      totalDocuments: totalDocs,
      uploadedCollections: uploaded,
      errors: errors,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Upload helpers
  // ───────────────────────────────────────────────────────────────────────────

  /// Uploads / merges user documents.
  Future<_UploadCount> _uploadUserDocuments(
    String uid,
    Map<String, dynamic> section,
  ) async {
    try {
      final docs = section['documents'] as List<dynamic>? ?? [];
      int count = 0;
      for (final raw in docs) {
        final docData = Map<String, dynamic>.from(raw as Map);
        final docIdMode = docData.remove('_docIdMode');
        final id = (docIdMode == 'currentUser')
            ? uid
            : (docData.remove('_docId') as String? ?? uid);
        final cleaned = _cleanForUpload(docData);
        await _firestore
            .collection('users')
            .doc(id)
            .set(cleaned, SetOptions(merge: true));
        count++;
      }
      return _UploadCount(count);
    } catch (e) {
      return _UploadCount(0, error: e.toString());
    }
  }

  /// Uploads documents into a sub-collection.
  Future<_UploadCount> _uploadSubcollection(
    String collectionPath,
    Map<String, dynamic> section,
  ) async {
    try {
      final docs = section['documents'] as List<dynamic>? ?? [];
      int count = 0;
      for (final raw in docs) {
        final docData = Map<String, dynamic>.from(raw as Map);
        final docId = docData.remove('_docId') as String?;
        docData.remove('_docIdMode');
        final cleaned = _cleanForUpload(docData);
        if (docId != null) {
          await _firestore.collection(collectionPath).doc(docId).set(cleaned);
        } else {
          await _firestore.collection(collectionPath).add(cleaned);
        }
        count++;
      }
      return _UploadCount(count);
    } catch (e) {
      return _UploadCount(0, error: e.toString());
    }
  }

  /// Uploads documents into a top-level collection.
  Future<_UploadCount> _uploadTopLevelCollection(
    String collectionName,
    Map<String, dynamic> section,
  ) async {
    try {
      final docs = section['documents'] as List<dynamic>? ?? [];
      int count = 0;
      for (final raw in docs) {
        final docData = Map<String, dynamic>.from(raw as Map);
        final docId = docData.remove('_docId') as String?;
        docData.remove('_docIdMode');
        final cleaned = _cleanForUpload(docData);
        if (docId != null) {
          await _firestore.collection(collectionName).doc(docId).set(cleaned);
        } else {
          await _firestore.collection(collectionName).add(cleaned);
        }
        count++;
      }
      return _UploadCount(count);
    } catch (e) {
      return _UploadCount(0, error: e.toString());
    }
  }

  /// Uploads user_game_progress/{uid}.
  Future<_UploadCount> _uploadUserGameProgress(
    String uid,
    Map<String, dynamic> section,
  ) async {
    try {
      final docs = section['documents'] as List<dynamic>? ?? [];
      int count = 0;
      for (final raw in docs) {
        final docData = Map<String, dynamic>.from(raw as Map);
        docData.remove('_docIdMode');
        docData.remove('_docId');
        final cleaned = _cleanForUpload(docData);
        await _firestore.collection('user_game_progress').doc(uid).set(cleaned);
        count++;
      }
      return _UploadCount(count);
    } catch (e) {
      return _UploadCount(0, error: e.toString());
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Serialization helpers
  // ───────────────────────────────────────────────────────────────────────────

  /// Strips internal `_` metadata keys and converts null timestamp
  /// sentinels to actual server timestamp field values.
  Map<String, dynamic> _cleanForUpload(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    data.forEach((key, value) {
      // Skip our own metadata keys
      if (key.startsWith('_')) return;

      if (value == null) {
        // Keep nulls as-is (Firestore accepts null)
        result[key] = null;
      } else if (value is Map<String, dynamic>) {
        if (value['__type'] == 'Timestamp') {
          // Restore serialised Timestamp
          result[key] = Timestamp(
            value['seconds'] as int,
            value['nanoseconds'] as int,
          );
        } else {
          result[key] = _cleanForUpload(value);
        }
      } else if (value is List) {
        result[key] = value
            .map((e) => e is Map<String, dynamic> ? _cleanForUpload(e) : e)
            .toList();
      } else {
        result[key] = value;
      }
    });
    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result model
// ─────────────────────────────────────────────────────────────────────────────

class MigrationResult {
  final int totalDocuments;
  final List<String> uploadedCollections;
  final List<String> errors;

  const MigrationResult({
    required this.totalDocuments,
    required this.uploadedCollections,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  String get collectionsText => uploadedCollections.join('\n• ');
}

class _UploadCount {
  final int count;
  final String? error;
  const _UploadCount(this.count, {this.error});
}
