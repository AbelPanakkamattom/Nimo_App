import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_screen.dart';
import 'register_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color secondary = Color(0xFF8E7BFF);
  static const Color background = Color(0xFFF5F6FF);

  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController emailController = TextEditingController();

  StreamSubscription<AuthState>? authSubscription;

  bool loadingEmail = false;
  bool loadingGoogle = false;

  @override
  void initState() {
    super.initState();
    _listenAuthChanges();
  }

  // ==========================================================
  // AUTH LISTENER
  // ==========================================================

  void _listenAuthChanges() {
    authSubscription = supabase.auth.onAuthStateChange.listen(
          (data) async {
        final session = data.session;

        if (session == null || !mounted) return;

        final user = session.user;

        try {
          final profile = await supabase
              .from('profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();

          if (!mounted) return;

          if (profile != null) {
            _navigate(const HomeScreen());
          } else {
            _navigate(
              RegisterScreen(
                email: user.email ?? '',
              ),
            );
          }
        } catch (e) {
          debugPrint('Auth listener error: $e');
        }
      },
    );
  }

  void _navigate(Widget screen) {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
          (route) => false,
    );
  }

  // ==========================================================
  // HELPERS
  // ==========================================================

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  // ==========================================================
  // EMAIL OTP LOGIN
  // ==========================================================

  Future<void> sendOtp() async {
    final email = emailController.text.trim().toLowerCase();

    if (!isValidEmail(email)) {
      showMessage('Enter a valid email address');
      return;
    }

    if (loadingEmail) return;

    setState(() {
      loadingEmail = true;
    });

    try {
      await supabase.auth.signInWithOtp(email: email);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerifyOtpScreen(email: email),
        ),
      );
    } on AuthException catch (e) {
      showMessage(e.message);
    } catch (e) {
      showMessage('Failed to send OTP: $e');
    } finally {
      if (mounted) {
        setState(() {
          loadingEmail = false;
        });
      }
    }
  }

  // ==========================================================
  // GOOGLE LOGIN
  // ==========================================================

  Future<void> loginWithGoogle() async {
    if (loadingGoogle) return;

    setState(() {
      loadingGoogle = true;
    });

    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } on AuthException catch (e) {
      showMessage(e.message);
    } catch (e) {
      showMessage('Google login failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          loadingGoogle = false;
        });
      }
    }
  }

  // ==========================================================
  // FUTURE LOGIN PROVIDERS
  // ==========================================================

  void showComingSoon(String provider) {
    showMessage('$provider login coming soon.');
  }

  // ==========================================================
  // UI WIDGETS
  // ==========================================================

  Widget _buildLogo() {
    return Hero(
      tag: 'nimo_logo',
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: primary.withAlpha(45),
              blurRadius: 35,
              spreadRadius: 3,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/nimo_logo.png',
          width: 180,
          height: 180,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return const Icon(
              Icons.chat_bubble_rounded,
              size: 120,
              color: primary,
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeature({
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: primary,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => sendOtp(),
        decoration: InputDecoration(
          hintText: 'Enter your email',
          prefixIcon: const Icon(Icons.email_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              secondary,
              primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primary.withAlpha(80),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: loadingEmail ? null : sendOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: loadingEmail
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
              : const Text(
            'Continue with Email',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon({
    required String asset,
    required String tooltip,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 62,
          height: 62,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: loading
              ? const CircularProgressIndicator(strokeWidth: 2.2)
              : Image.asset(
            asset,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return const Icon(
                Icons.login,
                color: primary,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(color: Colors.grey.shade300),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'OR CONTINUE WITH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: Colors.grey.shade300),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: [
            _buildSocialIcon(
              asset: 'assets/images/google.png',
              tooltip: 'Google',
              onTap: loginWithGoogle,
              loading: loadingGoogle,
            ),
            _buildSocialIcon(
              asset: 'assets/images/apple.png',
              tooltip: 'Apple',
              onTap: () => showComingSoon('Apple'),
            ),
            _buildSocialIcon(
              asset: 'assets/images/yahoo.png',
              tooltip: 'Yahoo',
              onTap: () => showComingSoon('Yahoo'),
            ),
            _buildSocialIcon(
              asset: 'assets/images/samsung.png',
              tooltip: 'Samsung',
              onTap: () => showComingSoon('Samsung'),
            ),
            _buildSocialIcon(
              asset: 'assets/images/outlook.png',
              tooltip: 'Outlook',
              onTap: () => showComingSoon('Outlook'),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 60,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const Spacer(),

                    _buildLogo(),

                    const SizedBox(height: 24),

                    const Text(
                      'Welcome to NIMO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Fast, secure and realtime messaging.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 10,
                      children: [
                        _buildFeature(
                          icon: Icons.lock,
                          text: 'Secure',
                        ),
                        _buildFeature(
                          icon: Icons.flash_on,
                          text: 'Realtime',
                        ),
                        _buildFeature(
                          icon: Icons.smart_toy,
                          text: 'AI Powered',
                        ),
                      ],
                    ),

                    const SizedBox(height: 42),

                    _buildEmailField(),

                    const SizedBox(height: 18),

                    _buildPrimaryButton(),

                    const SizedBox(height: 32),

                    _buildSocialLoginSection(),

                    const Spacer(),

                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Text(
                        'By continuing you agree to NIMO Terms & Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.6,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    authSubscription?.cancel();
    emailController.dispose();
    super.dispose();
  }
}

// ==========================================================
// VERIFY OTP SCREEN
// ==========================================================

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  static const Color primary = Color(0xFF6C5CE7);

  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController otpController = TextEditingController();

  bool loading = false;

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      showMessage('Enter 6-digit OTP');
      return;
    }

    if (loading) return;

    setState(() {
      loading = true;
    });

    try {
      await supabase.auth.verifyOTP(
        email: widget.email,
        token: otp,
        type: OtpType.email,
      );

      final user = supabase.auth.currentUser;

      if (user == null) {
        showMessage('Authentication failed');
        return;
      }

      final profile = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (profile != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeScreen(),
          ),
              (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterScreen(
              email: widget.email,
            ),
          ),
              (route) => false,
        );
      }
    } on AuthException catch (e) {
      showMessage(e.message);
    } catch (e) {
      showMessage('Invalid OTP: $e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> resendOtp() async {
    try {
      await supabase.auth.signInWithOtp(
        email: widget.email,
      );
      showMessage('OTP sent again.');
    } catch (_) {
      showMessage('Failed to resend OTP.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/nimo_logo.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 24),

                const Text(
                  'Verify OTP',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Enter the 6-digit code sent to',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  widget.email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),

                const SizedBox(height: 36),

                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 10,
                  ),
                  decoration: const InputDecoration(
                    hintText: '------',
                    counterText: '',
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: loading ? null : verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                    ),
                    child: loading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                        : const Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                TextButton(
                  onPressed: resendOtp,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }
}