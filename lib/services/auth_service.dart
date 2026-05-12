import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'zego_call_service.dart';

class AuthService {
  AuthService._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  static User? get currentUser =>
      _supabase.auth.currentUser;

  static bool get isLoggedIn =>
      currentUser != null;

  static String get currentUserId =>
      currentUser?.id ?? '';

  // ==========================================================
  // REGISTER
  // ==========================================================

  static Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim().toLowerCase(),
        password: password.trim(),
        data: {
          'name': name.trim(),
          'full_name': name.trim(),
        },
      );

      final user = response.user;

      if (user == null) {
        return 'Registration failed.';
      }

      await _ensureProfileExists(
        user: user,
        fallbackName: name,
      );

      await _updateOnlineStatus(true);

      // Initialize ZEGO
      await _initializeZego(user);

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('REGISTER ERROR: $e');
      return 'Registration failed.';
    }
  }

  // ==========================================================
  // LOGIN
  // ==========================================================

  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response =
      await _supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password.trim(),
      );

      final user = response.user;

      if (user != null) {
        await _ensureProfileExists(user: user);
        await _updateOnlineStatus(true);

        // Initialize ZEGO
        await _initializeZego(user);
      }

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('LOGIN ERROR: $e');
      return 'Login failed.';
    }
  }

  // ==========================================================
  // GOOGLE SIGN-IN
  // ==========================================================

  static Future<String?> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo:
        'io.supabase.flutter://login-callback/',
      );

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('GOOGLE LOGIN ERROR: $e');
      return 'Google sign-in failed.';
    }
  }

  // ==========================================================
  // RESET PASSWORD
  // ==========================================================

  static Future<String?> resetPassword(
      String email,
      ) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
      );

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('RESET PASSWORD ERROR: $e');
      return 'Failed to send reset email.';
    }
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  static Future<void> logout() async {
    try {
      await _updateOnlineStatus(false);

      // Stop ZEGO completely
      ZegoCallService.uninit();

      // Sign out from Supabase
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('LOGOUT ERROR: $e');
    }
  }

  // ==========================================================
  // DELETE ACCOUNT
  // ==========================================================

  static Future<String?> deleteAccount() async {
    try {
      final user = currentUser;

      if (user == null) {
        return 'User not found.';
      }

      await _supabase
          .from('profiles')
          .delete()
          .eq('id', user.id);

      await logout();

      return null;
    } catch (e) {
      debugPrint('DELETE ACCOUNT ERROR: $e');
      return 'Failed to delete account.';
    }
  }

  // ==========================================================
  // AUTH STATE CHANGES
  // ==========================================================

  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  // ==========================================================
  // INITIALIZE ZEGO
  // ==========================================================

  static Future<void> _initializeZego(
      User user,
      ) async {
    try {
      final metadata = user.userMetadata ?? {};

      final String userName =
      metadata['full_name']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? metadata['full_name']
          .toString()
          .trim()
          : metadata['name']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? metadata['name']
          .toString()
          .trim()
          : user.email
          ?.split('@')
          .first ??
          'NIMO User';

      // Reset any previous ZEGO session
      ZegoCallService.uninit();

      // IMPORTANT:
      // Pass the original Supabase UUID.
      // ZegoCallService will convert it to
      // a ZEGO-safe ID automatically.
      await ZegoCallService.init(
        userID: user.id,
        userName: userName,
      );

      debugPrint(
        'ZEGO INITIALIZED: '
            '$userName (${user.id})',
      );
    } catch (e) {
      debugPrint('ZEGO INIT ERROR: $e');
    }
  }

  // ==========================================================
  // ENSURE PROFILE EXISTS
  // ==========================================================

  static Future<void> _ensureProfileExists({
    required User user,
    String? fallbackName,
  }) async {
    try {
      final existing = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing != null) {
        return;
      }

      final metadata = user.userMetadata ?? {};

      final String name =
      metadata['full_name']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? metadata['full_name']
          .toString()
          .trim()
          : metadata['name']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? metadata['name']
          .toString()
          .trim()
          : (fallbackName ??
          user.email
              ?.split('@')
              .first ??
          'NIMO User');

      final String avatarUrl =
          metadata['avatar_url']
              ?.toString() ??
              '';

      final now = DateTime.now()
          .toUtc()
          .toIso8601String();

      await _supabase.from('profiles').insert({
        'id': user.id,
        'name': name,
        'full_name': name,
        'display_name': name,
        'email': user.email ?? '',
        'avatar_url': avatarUrl,
        'bio': '',
        'description': '',
        'is_online': true,
        'last_seen': now,
        'typing_to': '',
        'created_at': now,
        'updated_at': now,
      });

      debugPrint('PROFILE CREATED: $name');
    } catch (e) {
      debugPrint('CREATE PROFILE ERROR: $e');
    }
  }

  // ==========================================================
  // UPDATE ONLINE STATUS
  // ==========================================================

  static Future<void> _updateOnlineStatus(
      bool online,
      ) async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    try {
      final now = DateTime.now()
          .toUtc()
          .toIso8601String();

      await _supabase
          .from('profiles')
          .update({
        'is_online': online,
        'last_seen': now,
        'updated_at': now,
      })
          .eq('id', user.id);
    } catch (e) {
      debugPrint('ONLINE STATUS ERROR: $e');
    }
  }
}