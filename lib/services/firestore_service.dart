import 'package:cloud_firestore/cloud_firestore.dart';

/// FirestoreService handles all Firestore database operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection references
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Create a new user document in Firestore after sign up
  Future<void> createUserDocument({
    required String userId,
    required String email,
    required String password,
    String? displayName,
    String? preferredLanguage,
    String? authProvider,
  }) async {
    try {
      final userData = {
        'uid': userId,
        'email': email,
        'password': password,
        'displayName': displayName ?? '',
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isEmailVerified': false,
        'subscriptionStatus': 'free',
        'preferredLanguage': preferredLanguage ?? 'en',
        'isBanned': false,
        'deleted': false,
        'authProvider': authProvider ?? 'email',
        'hasUsed48HourTrial': false,
      };

      await _usersCollection.doc(userId).set(userData);
    } on FirebaseException catch (e) {
      throw handleFirestoreException(e);
    } catch (e) {
      throw 'Failed to create user profile. Please try again.';
    }
  }

  /// Get user document by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final QuerySnapshot query = await _usersCollection
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } on FirebaseException catch (e) {
      throw handleFirestoreException(e);
    } catch (e) {
      throw 'Failed to fetch user data. Please try again.';
    }
  }

  /// Get user document by ID
  Future<Map<String, dynamic>?> getUserDocument(String userId) async {
    try {
      final DocumentSnapshot doc = await _usersCollection.doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } on FirebaseException catch (e) {
      throw handleFirestoreException(e);
    } catch (e) {
      throw 'Failed to fetch user data. Please try again.';
    }
  }

  /// Update user document
  Future<void> updateUserDocument({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _usersCollection.doc(userId).update(data);
    } on FirebaseException catch (e) {
      throw handleFirestoreException(e);
    } catch (e) {
      throw 'Failed to update user data. Please try again.';
    }
  }

  /// Update last login timestamp
  Future<void> updateLastLogin(String userId) async {
    try {
      await _usersCollection.doc(userId).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw handleFirestoreException(e);
    } catch (e) {
      throw 'Failed to update login time. Please try again.';
    }
  }

  /// Update email verification status
  Future<void> updateEmailVerificationStatus(
    String userId,
    bool isVerified,
  ) async {
    try {
      await _usersCollection.doc(userId).update({
        'isEmailVerified': isVerified,
      });
    } on FirebaseException catch (e) {
      throw handleFirestoreException(e);
    } catch (e) {
      throw 'Failed to update verification status. Please try again.';
    }
  }

  /// Update subscription status
  Future<void> updateSubscriptionStatus(String userId, String status) async {
    try {
      await _usersCollection.doc(userId).update({
        'subscriptionStatus': status,
        'subscriptionUpdatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw handleFirestoreException(e);
    } catch (e) {
      throw 'Failed to update subscription. Please try again.';
    }
  }

  /// Delete user document
  Future<void> deleteUserDocument(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } on FirebaseException catch (e) {
      throw handleFirestoreException(e);
    } catch (e) {
      throw 'Failed to delete user data. Please try again.';
    }
  }

  /// Stream of user document for real-time updates
  Stream<DocumentSnapshot?> userDocumentStream(String userId) {
    return _usersCollection.doc(userId).snapshots();
  }

  /// Check if user document exists
  Future<bool> userDocumentExists(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      return doc.exists;
    } on FirebaseException catch (e) {
      throw handleFirestoreException(e);
    } catch (e) {
      throw 'Failed to check user data. Please try again.';
    }
  }

  /// Handle Firestore exceptions and return user-friendly error messages
  String handleFirestoreException(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'You don\'t have permission to perform this action.';
      case 'not-found':
        return 'User data not found.';
      case 'already-exists':
        return 'User profile already exists.';
      case 'resource-exhausted':
        return 'Too many requests. Please try again later.';
      case 'failed-precondition':
        return 'Operation failed. Please try again.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please try again later.';
      case 'deadline-exceeded':
        return 'Request timed out. Please try again.';
      case 'cancelled':
        return 'Request was cancelled.';
      case 'data-loss':
        return 'Data corruption detected. Please contact support.';
      case 'unauthenticated':
        return 'Please sign in again to continue.';
      default:
        return e.message ?? 'A database error occurred. Please try again.';
    }
  }
}
