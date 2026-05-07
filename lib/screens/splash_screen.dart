import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen>
    with TickerProviderStateMixin {
  final SupabaseClient supabase =
      Supabase.instance.client;

  late AnimationController
  logoController;

  late Animation<double>
  scaleAnimation;

  late Animation<double>
  fadeAnimation;

  bool navigating = false;

  /// =========================
  /// INIT
  /// =========================

  @override
  void initState() {
    super.initState();

    _initAnimation();

    _start();
  }

  /// =========================
  /// 🎬 ANIMATION
  /// =========================

  void _initAnimation() {
    logoController =
        AnimationController(
          vsync: this,
          duration:
          const Duration(
            milliseconds: 1200,
          ),
        );

    scaleAnimation =
        CurvedAnimation(
          parent: logoController,
          curve: Curves.easeOutBack,
        );

    fadeAnimation =
        CurvedAnimation(
          parent: logoController,
          curve: Curves.easeIn,
        );

    logoController.forward();
  }

  /// =========================
  /// 🚀 START FLOW
  /// =========================

  Future<void> _start() async {
    await Future.delayed(
      const Duration(
        milliseconds: 1200,
      ),
    );

    final user =
        supabase.auth.currentUser;

    if (!mounted) return;

    /// ❌ NOT LOGGED IN
    if (user == null) {
      _navigate(
        const AuthScreen(),
      );
      return;
    }

    try {
      /// 🔍 CHECK PROFILE
      final profile =
      await supabase
          .from('profiles')
          .select()
          .eq(
        'id',
        user.id,
      )
          .maybeSingle();

      if (!mounted) return;

      final provider =
      user.appMetadata[
      'provider'];

      /// 🟢 GOOGLE USER
      if (profile == null &&
          provider == 'google') {
        await supabase
            .from('profiles')
            .insert({
          'id': user.id,
          'email': user.email,
          'name':
          user.userMetadata?[
          'name'] ??
              'User',
          'avatar_url':
          user.userMetadata?[
          'avatar_url'] ??
              '',
          'created_at':
          DateTime.now()
              .toIso8601String(),
        });

        _navigate(
          const HomeScreen(),
        );

        return;
      }

      /// 🟡 EMAIL USER
      if (profile == null) {
        _navigate(
          RegisterScreen(
            email:
            user.email ?? '',
          ),
        );

        return;
      }

      /// ✅ READY
      _navigate(
        const HomeScreen(),
      );
    } catch (e) {
      debugPrint(
        "SPLASH ERROR: $e",
      );

      _navigate(
        const AuthScreen(),
      );
    }
  }

  /// =========================
  /// 🔥 SAFE NAVIGATION
  /// =========================

  void _navigate(
      Widget screen,
      ) {
    if (!mounted ||
        navigating) {
      return;
    }

    navigating = true;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
          (_) => false,
    );
  }

  /// =========================
  /// UI
  /// =========================

  @override
  Widget build(BuildContext context) {
    const primary =
    Color(0xFF6C5CE7);

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6FF),

      body: Container(
        width: double.infinity,
        decoration:
        const BoxDecoration(
          gradient:
          LinearGradient(
            colors: [
              Color(0xFFF7F8FF),
              Color(0xFFEDE9FF),
            ],
            begin:
            Alignment.topCenter,
            end: Alignment
                .bottomCenter,
          ),
        ),

        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: fadeAnimation,

              child: ScaleTransition(
                scale:
                scaleAnimation,

                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,

                  children: [
                    /// 🔥 LOGO
                    Container(
                      width: 110,
                      height: 110,

                      decoration:
                      BoxDecoration(
                        gradient:
                        const LinearGradient(
                          colors: [
                            Color(
                              0xFF7B61FF,
                            ),
                            Color(
                              0xFF6C5CE7,
                            ),
                          ],
                          begin:
                          Alignment
                              .topLeft,
                          end:
                          Alignment
                              .bottomRight,
                        ),

                        shape:
                        BoxShape
                            .circle,

                        boxShadow: [
                          BoxShadow(
                            color: primary
                                .withValues(
                              alpha:
                              0.25,
                            ),
                            blurRadius:
                            25,
                            offset:
                            const Offset(
                              0,
                              10,
                            ),
                          ),
                        ],
                      ),

                      child:
                      const Icon(
                        Icons.chat_bubble_rounded,
                        size: 52,
                        color: Colors
                            .white,
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    /// 🔥 APP NAME
                    const Text(
                      "NIMO",
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight:
                        FontWeight
                            .bold,
                        letterSpacing:
                        1.2,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Text(
                      "Secure realtime messaging",
                      style: TextStyle(
                        color: Colors
                            .grey
                            .shade700,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(
                      height: 40,
                    ),

                    /// 🔄 LOADER
                    SizedBox(
                      width: 26,
                      height: 26,

                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2.8,
                        color:
                        primary,
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

  /// =========================
  /// DISPOSE
  /// =========================

  @override
  void dispose() {
    logoController.dispose();

    super.dispose();
  }
}