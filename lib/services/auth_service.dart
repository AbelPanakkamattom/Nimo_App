import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase =
      Supabase.instance.client;

  /// =========================
  /// CURRENT USER
  /// =========================

  static User? get currentUser =>
      _supabase.auth.currentUser;

  static bool get isLoggedIn =>
      currentUser != null;

  /// =========================
  /// REGISTER
  /// =========================

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
        return "Registration failed";
      }

      await _createProfile(
        userId: user.id,
        name: name,
        email: email,
      );

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// =========================
  /// LOGIN
  /// =========================

  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await _updateOnlineStatus(true);

      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  /// =========================
  /// GOOGLE LOGIN
  /// =========================

  static Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn =
      GoogleSignIn(
        scopes: ['email'],
      );

      /// FORCE ACCOUNT PICKER
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser =
      await googleSignIn.signIn();

      if (googleUser == null) {
        return "Google sign in cancelled";
      }

      final GoogleSignInAuthentication
      googleAuth =
      await googleUser.authentication;

      final accessToken =
          googleAuth.accessToken;

      final idToken =
          googleAuth.idToken;

      if (accessToken == null ||
          idToken == null) {
        return "Google token error";
      }

      final response =
      await _supabase.auth
          .signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user;

      if (user == null) {
        return "Google login failed";
      }

      /// CHECK PROFILE EXISTS
      final existing =
      await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existing == null) {
        await _createProfile(
          userId: user.id,
          name:
          user.userMetadata?['name'] ??
              "Nimo User",
          email: user.email ?? '',
          avatarUrl: user
              .userMetadata?['avatar_url'],
        );
      }

      await _updateOnlineStatus(true);

      return null;
    } catch (e) {
      debugPrint(
        "GOOGLE LOGIN ERROR: $e",
      );

      return e.toString();
    }
  }

  /// =========================
  /// LOGOUT
  /// =========================

  static Future<void> logout() async {
    try {
      await _updateOnlineStatus(false);

      final GoogleSignIn googleSignIn =
      GoogleSignIn();

      try {
        await googleSignIn.disconnect();
      } catch (_) {}

      try {
        await googleSignIn.signOut();
      } catch (_) {}

      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint(
        "LOGOUT ERROR: $e",
      );
    }
  }

  /// =========================
  /// RESET PASSWORD
  /// =========================

  static Future<String?> resetPassword(
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
      return e.toString();
    }
  }

  /// =========================
  /// CREATE PROFILE
  /// =========================

  static Future<void> _createProfile({
    required String userId,
    required String name,
    required String email,
    String? avatarUrl,
  }) async {
    try {
      await _supabase
          .from('profiles')
          .insert({
        'id': userId,
        'name': name.trim(),
        'email': email.trim(),
        'avatar_url': avatarUrl ?? '',
        'description': '',
        'is_online': true,
        'last_seen': DateTime.now()
            .toIso8601String(),
        'typing_to': '',
      });
    } catch (e) {
      debugPrint(
        "CREATE PROFILE ERROR: $e",
      );
    }
  }

  /// =========================
  /// ONLINE STATUS
  /// =========================

  static Future<void>
  _updateOnlineStatus(
      bool online,
      ) async {
    try {
      final user = currentUser;

      if (user == null) {
        return;
      }

      await _supabase
          .from('profiles')
          .update({
        'is_online': online,
        'last_seen': DateTime.now()
            .toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      debugPrint(
        "ONLINE STATUS ERROR: $e",
      );
    }
  }

  /// =========================
  /// AUTH STREAM
  /// =========================

  static Stream<AuthState>
  get authStateChanges =>
      _supabase.auth.onAuthStateChange;

  /// =========================
  /// DELETE ACCOUNT
  /// =========================

  static Future<String?> deleteAccount()
  async {
    try {
      final user = currentUser;

      if (user == null) {
        return "User not found";
      }

      await _supabase
          .from('profiles')
          .delete()
          .eq('id', user.id);

      await logout();

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}