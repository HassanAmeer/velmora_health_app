import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:velmora/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:velmora/services/rate_limit_service.dart';
import 'package:velmora/services/error_cache_service.dart';
import 'dart:async' show unawaited;

/// GameService handles all game-related Firestore operations
class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RateLimitService _rateLimitService = RateLimitService();

  /// Get current user ID
  String? get currentUserId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      print('⚠️ [GameService] No user logged in - currentUserId is null');
    }
    return uid;
  }

  /// Collection references
  CollectionReference get _gamesCollection => _firestore.collection('games');

  CollectionReference get _userGamesCollection =>
      _firestore.collection('user_games');

  /// Get all available games
  Future<List<Map<String, dynamic>>> getAvailableGames() async {
    try {
      final QuerySnapshot snapshot = await _gamesCollection.get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw 'Failed to fetch games: $e';
    }
  }

  /// Start a new game session
  Future<String> startGameSession({
    required String gameType,
    required String partnerId,
  }) async {
    try {
      // Check rate limit
      final rateLimitResult = await _rateLimitService.checkRateLimit(
        'game_play',
      );
      if (!rateLimitResult.allowed) {
        throw rateLimitResult.reason ?? 'Rate limit exceeded';
      }

      final sessionData = {
        'userId': currentUserId,
        'partnerId': partnerId,
        'gameType': gameType,
        'status': 'active',
        'currentQuestionIndex': 0,
        'score': 0,
        'startedAt': FieldValue.serverTimestamp(),
        'responses': [],
      };

      final docRef = await _userGamesCollection.add(sessionData);

      // Record rate limit action
      await _rateLimitService.recordAction(
        'game_play',
        metadata: {'gameType': gameType},
      );

      return docRef.id;
    } catch (e) {
      throw 'Failed to start game: $e';
    }
  }

  /// Save user response to a question
  Future<void> saveResponse({
    required String sessionId,
    required String questionId,
    required String response,
    required int questionIndex,
  }) async {
    try {
      final responseData = {
        'questionId': questionId,
        'response': response,
        'answeredAt': FieldValue.serverTimestamp(),
      };

      await _userGamesCollection.doc(sessionId).update({
        'responses': FieldValue.arrayUnion([responseData]),
        'currentQuestionIndex': questionIndex + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to save response: $e';
    }
  }

  /// Update game score
  Future<void> updateScore({
    required String sessionId,
    required int score,
  }) async {
    try {
      await _userGamesCollection.doc(sessionId).update({
        'score': score,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to update score: $e';
    }
  }

  /// Complete game session
  Future<void> completeGameSession(String sessionId) async {
    try {
      await _userGamesCollection.doc(sessionId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      NotificationService().addInAppNotification(
        title: 'Game Completed',
        body: 'You successfully completed a game session!',
        type: 'game',
      );
    } catch (e) {
      throw 'Failed to complete game: $e';
    }
  }

  /// Get user's game history
  Future<List<Map<String, dynamic>>> getUserGameHistory() async {
    try {
      final QuerySnapshot snapshot = await _userGamesCollection
          .where('userId', isEqualTo: currentUserId)
          .orderBy('startedAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
    } catch (e) {
      throw 'Failed to fetch game history: $e';
    }
  }

  /// Get active game session
  Future<Map<String, dynamic>?> getActiveSession() async {
    try {
      final QuerySnapshot snapshot = await _userGamesCollection
          .where('userId', isEqualTo: currentUserId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return {
          'id': snapshot.docs.first.id,
          ...snapshot.docs.first.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      throw 'Failed to fetch active session: $e';
    }
  }

  /// Delete game session
  Future<void> deleteGameSession(String sessionId) async {
    try {
      await _userGamesCollection.doc(sessionId).delete();
    } catch (e) {
      throw 'Failed to delete game session: $e';
    }
  }

  /// Stream of user's game sessions for real-time updates
  Stream<QuerySnapshot> get userGameSessionsStream {
    return _userGamesCollection
        .where('userId', isEqualTo: currentUserId)
        .orderBy('startedAt', descending: true)
        .snapshots();
  }

  // ==================== MISSING METHODS FOR GAME SCREEN ====================

  /// Alias for getAvailableGames - used by GamesScreen
  Future<List<Map<String, dynamic>>> getAllGames() async {
    return getAvailableGames();
  }

  /// Get or create user game progress document
  Future<Map<String, dynamic>> getUserGameProgress() async {
    try {
      final userProgressDoc = _firestore
          .collection('user_game_progress')
          .doc(currentUserId);

      final doc = await userProgressDoc.get();

      if (!doc.exists) {
        // Create default progress document
        final defaultProgress = {
          'userId': currentUserId,
          'playedGames': [],
          'sessions': [],
          'totalScore': 0,
          'favoriteGames': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        await userProgressDoc.set(defaultProgress);
        return defaultProgress;
      }

      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      throw 'Failed to fetch user progress: $e';
    }
  }

  /// Check if user can play a specific game (premium check)
  Future<bool> canPlayGame(String gameId) async {
    try {
      // Get user subscription status
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      final userData = userDoc.data();

      if (userData == null) return false;

      final subscriptionStatus = userData['subscriptionStatus'] ?? 'free';
      final featuresAccess =
          userData['featuresAccess'] as Map<String, dynamic>?;

      // Premium users can play all games
      if (subscriptionStatus == 'premium') return true;

      // Trial users with games access
      if (subscriptionStatus == 'trial' && featuresAccess?['games'] == true) {
        return true;
      }

      // Free users - only allow specific free games
      final freeGames = ['truth_or_truth']; // Define free games
      return freeGames.contains(gameId);
    } catch (e) {
      return false;
    }
  }

  /// Start game session with just gameId (for GamesScreen)
  Future<String> startGameSessionById(String gameId) async {
    try {
      print('🎮 [GameService] Starting session for: $gameId');

      // CRITICAL: Check if user is logged in
      if (currentUserId == null) {
        print('❌ [GameService] No user logged in!');
        throw 'User not logged in. Please sign in to play games.';
      }
      print('🎮 [GameService] User ID: $currentUserId');

      // Check rate limit
      print('🎮 [GameService] Checking rate limit...');
      final rateLimitResult = await _rateLimitService.checkRateLimit(
        'game_play',
      );
      if (!rateLimitResult.allowed) {
        print('❌ [GameService] Rate limit exceeded');
        throw rateLimitResult.reason ?? 'Rate limit exceeded';
      }

      print('🎮 [GameService] Creating session data...');
      final sessionData = {
        'userId': currentUserId,
        'gameId': gameId,
        'gameType': gameId,
        'status': 'active',
        'currentQuestionIndex': 0,
        'score': 0,
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'responses': [],
      };

      print('🎮 [GameService] Adding session to Firestore...');
      final docRef = await _userGamesCollection.add(sessionData);
      print('🎮 [GameService] Session created: ${docRef.id}');

      // Update user progress
      print('🎮 [GameService] Updating user progress...');
      // Don't await - run in background (not critical for gameplay)
      // Use unawaited to fully detach from the async flow
      unawaited(
        _updateUserProgressOnStart(gameId).catchError((e) {
          print('⚠️ [GameService] Background progress update failed: $e');
        }),
      );

      // Record rate limit action (also non-blocking)
      unawaited(
        _rateLimitService
            .recordAction('game_play', metadata: {'gameId': gameId})
            .catchError((e) {
              print('⚠️ [GameService] Background rate limit record failed: $e');
            }),
      );

      print('✅ [GameService] Session started successfully');
      return docRef.id;
    } catch (e, stackTrace) {
      print('❌ [GameService] Error starting session: $e');
      print('❌ [GameService] Stack: $stackTrace');
      throw 'Failed to start game session: $e';
    }
  }

  /// Update user progress when starting a game
  /// COMPLETELY BULLETPROOF - Every operation is isolated with try-catch
  Future<void> _updateUserProgressOnStart(String gameId) async {
    print('🎮 [GameService] Updating user progress for: $gameId');

    // ISOLATION LEVEL 1: User authentication check
    String? userId;
    try {
      userId = currentUserId;
      if (userId == null) {
        print('⚠️ [GameService] Cannot update progress - user not logged in');
        return;
      }
    } catch (e) {
      print('❌ [GameService] ISOLATION 1 FAILED (auth check): $e');
      await ErrorCacheService().logGameError(
        gameId: gameId,
        phase: 'auth_check',
        error: e.toString(),
        stack: StackTrace.current.toString(),
      );
      return;
    }

    // ISOLATION LEVEL 2: Get document reference
    DocumentReference? userProgressDoc;
    try {
      userProgressDoc = _firestore.collection('user_game_progress').doc(userId);
    } catch (e) {
      print('❌ [GameService] ISOLATION 2 FAILED (doc reference): $e');
      await ErrorCacheService().logGameError(
        gameId: gameId,
        phase: 'doc_reference',
        error: e.toString(),
        stack: StackTrace.current.toString(),
      );
      return;
    }

    // ISOLATION LEVEL 3: Fetch document
    DocumentSnapshot? doc;
    try {
      print('🎮 [GameService] Getting user progress doc...');
      doc = await userProgressDoc.get();
      print('🎮 [GameService] Document exists: ${doc.exists}');
    } catch (e) {
      print('❌ [GameService] ISOLATION 3 FAILED (fetch doc): $e');
      await ErrorCacheService().logGameError(
        gameId: gameId,
        phase: 'fetch_doc',
        error: e.toString(),
        stack: StackTrace.current.toString(),
      );
      return;
    }

    // ISOLATION LEVEL 4: Process document data
    if (doc.exists) {
      print('🎮 [GameService] User progress doc exists');

      Map<String, dynamic>? data;
      try {
        data = doc.data() as Map<String, dynamic>?;
        if (data == null) {
          print('⚠️ [GameService] User progress data is null');
          return;
        }
      } catch (e) {
        print('❌ [GameService] ISOLATION 4 FAILED (parse data): $e');
        await ErrorCacheService().logGameError(
          gameId: gameId,
          phase: 'parse_data',
          error: e.toString(),
          stack: StackTrace.current.toString(),
        );
        return;
      }

      // ISOLATION LEVEL 5: Extract playedGames array
      List<dynamic> playedGames = [];
      try {
        final pg = data['playedGames'];
        if (pg != null && pg is List) {
          playedGames = List<dynamic>.from(pg);
        }
        print('🎮 [GameService] Played games count: ${playedGames.length}');
      } catch (e) {
        print('⚠️ [GameService] ISOLATION 5 FAILED (extract playedGames): $e');
        await ErrorCacheService().logGameError(
          gameId: gameId,
          phase: 'extract_playedGames',
          error: e.toString(),
          stack: StackTrace.current.toString(),
        );
        playedGames = [];
      }

      // ISOLATION LEVEL 6: Check if game already exists
      bool gameAlreadyPlayed = false;
      try {
        final existingIndex = playedGames.indexWhere((g) {
          if (g is Map) return g['gameId'] == gameId;
          if (g is String) return g == gameId;
          return false;
        });
        gameAlreadyPlayed = existingIndex != -1;
        print('🎮 [GameService] Game already played: $gameAlreadyPlayed');
      } catch (e) {
        print('⚠️ [GameService] ISOLATION 6 FAILED (check existing): $e');
        await ErrorCacheService().logGameError(
          gameId: gameId,
          phase: 'check_existing',
          error: e.toString(),
          stack: StackTrace.current.toString(),
        );
        gameAlreadyPlayed = false;
      }

      // ISOLATION LEVEL 7: Update existing document
      if (gameAlreadyPlayed) {
        print('🎮 [GameService] Adding to sessions only...');
        await _safeUpdateSessions(userProgressDoc, gameId, userId, gameId);
      } else {
        print('🎮 [GameService] Adding to playedGames and sessions...');
        await _safeUpdatePlayedGamesAndSessions(
          userProgressDoc,
          gameId,
          userId,
          gameId,
        );
      }
    } else {
      // ISOLATION LEVEL 8: Create new document
      print('🎮 [GameService] User progress doc does not exist, creating...');
      await _safeCreateProgressDoc(userProgressDoc, gameId, userId, gameId);
    }

    print('✅ [GameService] User progress updated');
  }

  /// ISOLATED: Safely update sessions array
  /// NOTE: Using DateTime.now() instead of FieldValue.serverTimestamp() inside arrays
  /// to prevent iOS native crash when server timestamp is nested in array operations
  Future<void> _safeUpdateSessions(
    DocumentReference docRef,
    String gameId,
    String userId,
    String errorContextId,
  ) async {
    final now = DateTime.now().toIso8601String();
    try {
      await docRef.update({
        'sessions': FieldValue.arrayUnion([
          {'gameId': gameId, 'startedAt': now},
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ [GameService] Sessions updated successfully');
    } catch (e, stackTrace) {
      print('❌ [GameService] ISOLATION 7 FAILED (update sessions): $e');
      print('❌ [GameService] Stack: $stackTrace');
      await ErrorCacheService().logGameError(
        gameId: errorContextId,
        phase: 'update_sessions',
        error: e.toString(),
        stack: stackTrace.toString(),
      );
      // Try fallback: set with merge
      try {
        await docRef.set({
          'sessions': [
            {'gameId': gameId, 'startedAt': now},
          ],
        }, SetOptions(merge: true));
        print('✅ [GameService] Sessions set with merge fallback');
      } catch (e2, stackTrace2) {
        print('❌ [GameService] Fallback also failed: $e2');
        print('❌ [GameService] Stack: $stackTrace2');
        await ErrorCacheService().logGameError(
          gameId: errorContextId,
          phase: 'sessions_fallback',
          error: e2.toString(),
          stack: stackTrace2.toString(),
        );
      }
    }
  }

  /// ISOLATED: Safely update playedGames and sessions arrays
  /// NOTE: Using DateTime.now() instead of FieldValue.serverTimestamp() inside arrays
  /// to prevent iOS native crash when server timestamp is nested in array operations
  Future<void> _safeUpdatePlayedGamesAndSessions(
    DocumentReference docRef,
    String gameId,
    String userId,
    String errorContextId,
  ) async {
    final now = DateTime.now().toIso8601String();

    // STRATEGY 1: Try both fields
    try {
      await docRef.update({
        'playedGames': FieldValue.arrayUnion([
          {'gameId': gameId, 'startedAt': now},
        ]),
        'sessions': FieldValue.arrayUnion([
          {'gameId': gameId, 'startedAt': now},
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ [GameService] playedGames + sessions updated successfully');
      return;
    } catch (e, stackTrace) {
      print('❌ [GameService] STRATEGY 1 FAILED (both fields): $e');
      print('❌ [GameService] Stack: $stackTrace');
      await ErrorCacheService().logGameError(
        gameId: errorContextId,
        phase: 'update_both_fields',
        error: e.toString(),
        stack: stackTrace.toString(),
      );
    }

    // STRATEGY 2: Try sessions only
    try {
      await docRef.update({
        'sessions': FieldValue.arrayUnion([
          {'gameId': gameId, 'startedAt': now},
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ [GameService] Sessions only updated (strategy 2)');
      return;
    } catch (e, stackTrace) {
      print('❌ [GameService] STRATEGY 2 FAILED (sessions only): $e');
      print('❌ [GameService] Stack: $stackTrace');
      await ErrorCacheService().logGameError(
        gameId: errorContextId,
        phase: 'update_sessions_only',
        error: e.toString(),
        stack: stackTrace.toString(),
      );
    }

    // STRATEGY 3: Try playedGames only
    try {
      await docRef.update({
        'playedGames': FieldValue.arrayUnion([
          {'gameId': gameId, 'startedAt': now},
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ [GameService] playedGames only updated (strategy 3)');
      return;
    } catch (e, stackTrace) {
      print('❌ [GameService] STRATEGY 3 FAILED (playedGames only): $e');
      print('❌ [GameService] Stack: $stackTrace');
      await ErrorCacheService().logGameError(
        gameId: errorContextId,
        phase: 'update_playedGames_only',
        error: e.toString(),
        stack: stackTrace.toString(),
      );
    }

    // STRATEGY 4: Nuclear fallback - set with merge
    try {
      print('🎮 [GameService] Using nuclear fallback (set with merge)...');
      await docRef.set({
        'userId': userId,
        'playedGames': [
          {'gameId': gameId, 'startedAt': now},
        ],
        'sessions': [
          {'gameId': gameId, 'startedAt': now},
        ],
        'totalScore': 0,
        'favoriteGames': [],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('✅ [GameService] Nuclear fallback succeeded');
    } catch (e, stackTrace) {
      print('❌ [GameService] STRATEGY 4 FAILED (nuclear fallback): $e');
      print('❌ [GameService] Stack: $stackTrace');
      await ErrorCacheService().logGameError(
        gameId: errorContextId,
        phase: 'nuclear_fallback',
        error: e.toString(),
        stack: stackTrace.toString(),
      );
      // Completely fail silently - this is non-critical
    }
  }

  /// ISOLATED: Safely create new progress document
  /// NOTE: Using DateTime.now() instead of FieldValue.serverTimestamp() inside arrays
  /// to prevent iOS native crash when server timestamp is nested in array operations
  Future<void> _safeCreateProgressDoc(
    DocumentReference docRef,
    String gameId,
    String userId,
    String errorContextId,
  ) async {
    final now = DateTime.now().toIso8601String();
    try {
      await docRef.set({
        'userId': userId,
        'playedGames': [
          {'gameId': gameId, 'startedAt': now},
        ],
        'sessions': [
          {'gameId': gameId, 'startedAt': now},
        ],
        'totalScore': 0,
        'favoriteGames': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ [GameService] User progress doc created');
    } catch (e, stackTrace) {
      print('❌ [GameService] ISOLATION 8 FAILED (create doc): $e');
      print('❌ [GameService] Stack: $stackTrace');
      await ErrorCacheService().logGameError(
        gameId: errorContextId,
        phase: 'create_doc',
        error: e.toString(),
        stack: stackTrace.toString(),
      );
      // Fail silently - not critical
    }
  }

  // ==================== END MISSING METHODS ====================

  /// Add game to favorites
  Future<void> addToFavorites(String gameId) async {
    try {
      final userDoc = _firestore.collection('users').doc(currentUserId);
      await userDoc.update({
        'favoriteGames': FieldValue.arrayUnion([gameId]),
      });
    } catch (e) {
      throw 'Failed to add to favorites: $e';
    }
  }

  /// Remove game from favorites
  Future<void> removeFromFavorites(String gameId) async {
    try {
      final userDoc = _firestore.collection('users').doc(currentUserId);
      await userDoc.update({
        'favoriteGames': FieldValue.arrayRemove([gameId]),
      });
    } catch (e) {
      throw 'Failed to remove from favorites: $e';
    }
  }
}
