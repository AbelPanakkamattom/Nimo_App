import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// 🚀 MAIN FLOW
  Future<void> _start() async {
    await Future.delayed(const Duration(milliseconds: 600));

    final user = supabase.auth.currentUser;

    if (!mounted) return;

    /// ❌ NOT LOGGED IN
    if (user == null) {
      _navigate(const AuthScreen());
      return;
    }

    try {
      /// 🔍 CHECK PROFILE
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      final provider = user.appMetadata['provider'];

      /// 🟢 GOOGLE USER → AUTO CREATE PROFILE
      if (profile == null && provider == 'google') {
        await supabase.from('profiles').insert({
          'id': user.id,
          'email': user.email,
          'name': user.userMetadata?['name'] ?? 'User',
          'created_at': DateTime.now().toIso8601String(),
        });

        _navigate(const HomeScreen());
        return;
      }

      /// 🟡 EMAIL USER WITHOUT PROFILE
      if (profile == null) {
        _navigate(RegisterScreen(email: user.email ?? ""));
        return;
      }

      /// ✅ READY → ALWAYS GO HOME (IMPORTANT)
      _navigate(const HomeScreen());
    } catch (e) {
      debugPrint("❌ Splash error: $e");
      _navigate(const AuthScreen());
    }
  }

  /// 🔥 SAFE NAVIGATION (NO DUPLICATES)
  void _navigate(Widget screen) {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
          (_) => false,
    );
  }

  /// 🎨 UI
  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6C5CE7);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 🔵 LOGO
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat, size: 45, color: primary),
            ),

            const SizedBox(height: 20),

            const Text(
              "NIMO",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}