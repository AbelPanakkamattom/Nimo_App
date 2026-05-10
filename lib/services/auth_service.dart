import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static final SupabaseClient _supabase =
      Supabase.instance.client;

  static final GoogleSignIn
  _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  // ==========================================
  // CURRENT USER
  // ==========================================

  static User? get currentUser =>
      _supabase.auth.currentUser;

  static bool get isLoggedIn =>
      currentUser != null;

  static String get currentUserId =>
      currentUser?.id ?? '';

  // ==========================================
  // REGISTER
  // ==========================================

  static Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response =
      await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {
          'name': name.trim(),
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

      await _updateOnlineStatus(
        true,
      );

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint(
        'REGISTER ERROR: $e',
      );
      return 'Registration failed.';
    }
  }

  // ==========================================
  // LOGIN
  // ==========================================

  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth
          .signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await _updateOnlineStatus(
        true,
      );

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint(
        'LOGIN ERROR: $e',
      );
      return 'Login failed.';
    }
  }

  // ==========================================
  // GOOGLE SIGN-IN
  // ==========================================

  static Future<String?>
  signInWithGoogle() async {
    try {
      // Force account picker
      try {
        await _googleSignIn
            .signOut();
      } catch (_) {}

      final googleUser =
      await _googleSignIn.signIn();

      if (googleUser == null) {
        return 'Google sign-in cancelled.';
      }

      final googleAuth =
      await googleUser
          .authentication;

      final accessToken =
          googleAuth.accessToken;
      final idToken =
          googleAuth.idToken;

      if (accessToken == null ||
          idToken == null) {
        return 'Failed to retrieve Google tokens.';
      }

      final response =
      await _supabase.auth
          .signInWithIdToken(
        provider:
        OAuthProvider.google,
        idToken: idToken,
        accessToken:
        accessToken,
      );

      final user = response.user;

      if (user == null) {
        return 'Google sign-in failed.';
      }

      await _ensureProfileExists(
        user: user,
      );

      await _updateOnlineStatus(
        true,
      );

      return null;
    } catch (e) {
      debugPrint(
        'GOOGLE LOGIN ERROR: $e',
      );
      return 'Google sign-in failed.';
    }
  }

  // ==========================================
  // RESET PASSWORD
  // ==========================================

  static Future<String?>
  resetPassword(
      String email,
      ) async {
    try {
      await _supabase.auth
          .resetPasswordForEmail(
        email.trim(),
      );

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint(
        'RESET PASSWORD ERROR: $e',
      );
      return 'Failed to send reset email.';
    }
  }

  // ==========================================
  // LOGOUT
  // ==========================================

  static Future<void> logout() async {
    try {
      await _updateOnlineStatus(
        false,
      );

      try {
        await _googleSignIn
            .disconnect();
      } catch (_) {}

      try {
        await _googleSignIn
            .signOut();
      } catch (_) {}

      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint(
        'LOGOUT ERROR: $e',
      );
    }
  }

  // ==========================================
  // DELETE ACCOUNT
  // ==========================================

  static Future<String?>
  deleteAccount() async {
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
      debugPrint(
        'DELETE ACCOUNT ERROR: $e',
      );
      return 'Failed to delete account.';
    }
  }

  // ==========================================
  // AUTH STREAM
  // ==========================================

  static Stream<AuthState>
  get authStateChanges =>
      _supabase
          .auth
          .onAuthStateChange;

  // ==========================================
  // ENSURE PROFILE EXISTS
  // ==========================================

  static Future<void>
  _ensureProfileExists({
    required User user,
    String? fallbackName,
  }) async {
    try {
      final existing =
      await _supabase
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existing != null) {
        return;
      }

      final metadata =
          user.userMetadata ?? {};

      final name =
      metadata['name']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? metadata['name']
          .toString()
          : (fallbackName ??
          user.email
              ?.split('@')
              .first ??
          'NIMO User');

      final avatarUrl =
          metadata['avatar_url']
              ?.toString() ??
              '';

      await _supabase
          .from('profiles')
          .insert({
        'id': user.id,
        'name': name,
        'email': user.email ?? '',
        'avatar_url':
        avatarUrl,
        'description': '',
        'is_online': true,
        'last_seen':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
        'typing_to': '',
      });
    } catch (e) {
      debugPrint(
        'CREATE PROFILE ERROR: $e',
      );
    }
  }

  // ==========================================
  // UPDATE ONLINE STATUS
  // ==========================================

  static Future<void>
  _updateOnlineStatus(
      bool online,
      ) async {
    final user = currentUser;

    if (user == null) {
      return;
    }

    try {
      await _supabase
          .from('profiles')
          .update({
        'is_online': online,
        'last_seen':
        DateTime.now()
            .toUtc()
            .toIso8601String(),
      })
          .eq('id', user.id);
    } catch (e) {
      debugPrint(
        'ONLINE STATUS ERROR: $e',
      );
    }
  }
}