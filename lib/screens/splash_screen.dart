import 'dart:async';

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

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const Color primary = Color(0xFF6C5CE7);

  final SupabaseClient supabase = Supabase.instance.client;

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _start();
  }

  // =========================================================
  // ANIMATIONS
  // =========================================================
  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _controller.forward();
  }

  // =========================================================
  // START APP LOGIC
  // =========================================================
  Future<void> _start() async {
    try {
      // Keep splash visible for at least 2.5 seconds
      await Future.delayed(
        const Duration(milliseconds: 2500),
      );

      final user = supabase.auth.currentUser;

      if (!mounted) return;

      // Not logged in
      if (user == null) {
        _navigate(const AuthScreen());
        return;
      }

      // Check if profile exists
      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      final provider = user.appMetadata['provider'];

      // Auto-create profile for Google sign-in
      if (profile == null && provider == 'google') {
        await supabase.from('profiles').insert({
          'id': user.id,
          'email': user.email,
          'name':
          user.userMetadata?['name'] ??
              user.email?.split('@').first ??
              'User',
          'avatar_url':
          user.userMetadata?['avatar_url'] ?? '',
          'description': '',
          'is_online': true,
          'last_seen': DateTime.now()
              .toUtc()
              .toIso8601String(),
          'created_at': DateTime.now()
              .toUtc()
              .toIso8601String(),
        });

        if (!mounted) return;

        _navigate(const HomeScreen());
        return;
      }

      // Registered user without profile
      if (profile == null) {
        _navigate(
          RegisterScreen(
            email: user.email ?? '',
          ),
        );
        return;
      }

      // Existing user
      _navigate(const HomeScreen());
    } on TimeoutException {
      if (!mounted) return;
      _navigate(const AuthScreen());
    } catch (e) {
      debugPrint('SPLASH ERROR: $e');

      if (!mounted) return;
      _navigate(const AuthScreen());
    }
  }

  // =========================================================
  // NAVIGATION
  // =========================================================
  void _navigate(Widget screen) {
    if (!mounted || _navigating) return;

    _navigating = true;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
          (route) => false,
    );
  }

  // =========================================================
  // PREMIUM LOGO
  // =========================================================
  Widget _buildLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Soft glow behind logo
        Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.22),
                blurRadius: 70,
                spreadRadius: 15,
              ),
            ],
          ),
        ),

        // Glass circle background
        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFF8F6FF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.9),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.75),
                blurRadius: 18,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: primary.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
        ),

        // Logo image
        SizedBox(
          width: 120,
          height: 120,
          child: Image.asset(
            'assets/images/nimo_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.auto_awesome,
                size: 90,
                color: primary,
              );
            },
          ),
        ),
      ],
    );
  }

  // =========================================================
  // BUILD
  // =========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.15),
            radius: 1.15,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF7F5FF),
              Color(0xFFF1EDFF),
              Color(0xFFEAE4FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium Logo
                    _buildLogo(),

                    const SizedBox(height: 44),

                    // App Name
                    const Text(
                      'NIMO',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 7,
                        color: Color(0xFF151515),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tagline
                    Text(
                      'Connect • Communicate • Create',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.8,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 52),

                    // Premium Loader
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        strokeCap: StrokeCap.round,
                        valueColor:
                        const AlwaysStoppedAnimation<Color>(
                          primary,
                        ),
                        backgroundColor:
                        primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}