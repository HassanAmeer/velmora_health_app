import 'package:velmora/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firestore_service.dart';
import 'user_service.dart';

/// AuthService handles all Firebase Authentication operations
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  // The serverClientId MUST match the Web Client ID (client_type: 3) in google-services.json.
  // Without this, idToken is null on Android and Firebase sign-in fails.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '238336819139-1a4cgs92nou6i5bdjeaiv2ol6m9cshdj.apps.googleusercontent.com',
  );

  /// Get the current authenticated user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Get user ID of current user
  String? get userId => currentUser?.uid;

  /// Firestore service instance for direct access
  FirestoreService get firestoreService => _firestoreService;

  /// Sign up with email and password
  /// Creates user in Auth and Firestore
  /// Returns UserCredential on success, throws exception on failure
  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      // Get current language from SharedPreferences
      String currentLanguage = 'en';
      try {
        final prefs = await SharedPreferences.getInstance();
        currentLanguage = prefs.getString('preferred_language') ?? 'en';
      } catch (e) {
        debugPrint('Error getting language: $e');
      }

      // Create user document in Firestore
      if (userCredential.user != null) {
        await _firestoreService.createUserDocument(
          userId: userCredential.user!.uid,
          email: email.trim(),
          password: password,
          displayName:
              userCredential.user!.displayName ?? email.trim().split('@')[0],
          preferredLanguage: currentLanguage,
          authProvider: 'email',
        );
        await NotificationService().addInAppNotification(
          title: 'Welcome to Velmora AI!',
          body:
              'We are thrilled to have you here. Let\'s strengthen your relationship together.',
          type: 'system',
          overrideUid: userCredential.user!.uid,
        );
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on FirebaseException catch (e) {
      throw _firestoreService.handleFirestoreException(e);
    } catch (e) {
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Login with email and password
  /// Updates last login in Firestore
  /// Returns UserCredential on success, throws exception on failure
  Future<UserCredential> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Pre-login check: Fetch user by email from Firestore
      final userData = await _firestoreService.getUserByEmail(email);

      // 2. Check if records are empty or user is deleted
      if (userData == null || userData['deleted'] == true) {
        throw 'No account found with this email. Please sign up first.';
      }

      // 3. Check if user is banned
      if (userData['isBanned'] == true) {
        throw 'This account has been banned. Please contact support.';
      }

      // 4. Proceed to Firebase Auth only if checks pass
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email.trim(), password: password);

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;
        // Update last login timestamp in Firestore
        await _firestoreService.updateLastLogin(uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e.toString().contains('banned') ||
          e.toString().contains('No account found')) {
        rethrow;
      }
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Sign out the current user
  /// Returns void on success, throws exception on failure
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to sign out. Please try again.';
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to send password reset email. Please try again.';
    }
  }

  /// Reload user data
  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to reload user data. Please try again.';
    }
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // PRE-LOGIN CHECK: Check if user is deleted or banned in Firestore
      final userData = await _firestoreService.getUserByEmail(googleUser.email);
      if (userData != null) {
        if (userData['deleted'] == true) {
          await _googleSignIn.signOut();
          throw 'No account found with this email. Please sign up first.';
        }
        if (userData['isBanned'] == true) {
          await _googleSignIn.signOut();
          throw 'This account has been banned. Please contact support.';
        }
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      // Get current language from SharedPreferences
      String currentLanguage = 'en';
      try {
        final prefs = await SharedPreferences.getInstance();
        currentLanguage = prefs.getString('preferred_language') ?? 'en';
      } catch (e) {
        debugPrint('Error getting language: $e');
      }

      // Create or update user document in Firestore
      if (userCredential.user != null) {
        final existingUser = await _firestoreService.getUserDocument(
          userCredential.user!.uid,
        );
        if (existingUser == null) {
          await _firestoreService.createUserDocument(
            userId: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            password: '12345678',
            displayName: userCredential.user!.displayName,
            preferredLanguage: currentLanguage,
            authProvider: 'google',
          );
          await NotificationService().addInAppNotification(
            title: 'Welcome to Velmora AI!',
            body:
                'We are thrilled to have you here. Let\'s strengthen your relationship together.',
            type: 'system',
            overrideUid: userCredential.user!.uid,
          );
        } else {
          // Check if user is deleted
          if (existingUser['deleted'] == true) {
            await _firebaseAuth.signOut();
            throw 'No account found with this email. Please sign up first.';
          }
          await _firestoreService.updateLastLogin(userCredential.user!.uid);
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e.toString().contains('banned') ||
          e.toString().contains('No account found')) {
        rethrow;
      }
      if (e.toString().contains('NETWORK')) {
        throw 'Network error. Please check your internet connection.';
      }
      throw 'Google Sign-In failed: $e';
    }
  }

  /// Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      // Trigger the Apple Sign-In flow
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // PRE-LOGIN CHECK: Check if user is deleted or banned in Firestore
      final emailFromApple = credential.email ?? '';
      if (emailFromApple.isNotEmpty) {
        final userData = await _firestoreService.getUserByEmail(emailFromApple);
        if (userData != null) {
          if (userData['deleted'] == true) {
            throw 'No account found with this email. Please sign up first.';
          }
          if (userData['isBanned'] == true) {
            throw 'This account has been banned. Please contact support.';
          }
        }
      }

      // Create an OAuthCredential for Apple Sign-In
      final oAuthProvider = OAuthProvider('apple.com')
        ..addScope('email')
        ..addScope('name');

      // Get the Apple credential
      final authCredential = oAuthProvider.credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credentials
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(authCredential);

      // Get current language from SharedPreferences
      String currentLanguage = 'en';
      try {
        final prefs = await SharedPreferences.getInstance();
        currentLanguage = prefs.getString('preferred_language') ?? 'en';
      } catch (e) {
        debugPrint('Error getting language: $e');
      }

      // Create or update user document in Firestore
      if (userCredential.user != null) {
        final existingUser = await _firestoreService.getUserDocument(
          userCredential.user!.uid,
        );
        if (existingUser == null) {
          // Handle Apple's anonymous email format
          final email = credential.email ?? userCredential.user!.email ?? '';
          final displayName = credential.givenName != null
              ? '${credential.givenName} ${credential.familyName ?? ''}'.trim()
              : userCredential.user!.displayName;

          await _firestoreService.createUserDocument(
            userId: userCredential.user!.uid,
            email: email,
            password: '12345678',
            displayName: displayName,
            preferredLanguage: currentLanguage,
            authProvider: 'apple',
          );
          await NotificationService().addInAppNotification(
            title: 'Welcome to Velmora AI!',
            body:
                'We are thrilled to have you here. Let\'s strengthen your relationship together.',
            type: 'system',
            overrideUid: userCredential.user!.uid,
          );
        } else {
          // Check if user is deleted
          if (existingUser['deleted'] == true) {
            await _firebaseAuth.signOut();
            throw 'No account found with this email. Please sign up first.';
          }
          await _firestoreService.updateLastLogin(userCredential.user!.uid);
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on SignInWithAppleException catch (e) {
      // Check if user canceled - the error message usually contains "canceled" or "cancelled"
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('cancel')) {
        return null; // User canceled the sign-in
      }
      throw 'Apple Sign-In failed: $e';
    } catch (e) {
      if (e.toString().contains('banned') ||
          e.toString().contains('No account found')) {
        rethrow;
      }
      if (e.toString().contains('NETWORK')) {
        throw 'Network error. Please check your internet connection.';
      }
      throw 'Apple Sign-In failed: $e';
    }
  }

  /// Handle FirebaseAuthException and return user-friendly error messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      // Sign up errors
      case 'email-already-in-use':
        return 'This email is already registered. Please use a different email or login.';
      case 'invalid-email':
        return 'Invalid email address. Please check and try again.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';

      // Login errors
      case 'user-disabled':
        return 'This account has been disabled or banned. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';

      // Password reset errors
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      // General errors
      case 'requires-recent-login':
        return 'Please login again to complete this action.';
      case 'user-token-expired':
        return 'Your session has expired. Please login again.';

      default:
        return e.message ??
            'An authentication error occurred. Please try again.';
    }
  }

  /// Check if user is banned
  Future<bool> isUserBanned(String userId) async {
    try {
      final userData = await _firestoreService.getUserDocument(userId);
      return userData?['isBanned'] ?? false;
    } catch (e) {
      debugPrint('Error checking ban status: $e');
      return false;
    }
  }

  /// Delete current user account and data
  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) throw 'User not authenticated';

    try {
      // 1. Delete user data from services
      final userService = UserService();
      await userService.deleteUserData();

      // 2. Delete auth user
      await user.delete();

      // 3. Sign out locally
      await logout();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'For security reasons, please login again before deleting your account.';
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to delete account: $e';
    }
  }
}
