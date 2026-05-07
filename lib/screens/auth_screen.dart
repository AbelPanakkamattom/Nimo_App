import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_screen.dart';
import 'register_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() =>
      _AuthScreenState();
}

class _AuthScreenState
    extends State<AuthScreen> {
  final SupabaseClient supabase =
      Supabase.instance.client;

  final TextEditingController
  emailController =
  TextEditingController();

  StreamSubscription<AuthState>?
  authSubscription;

  bool loadingEmail = false;
  bool loadingGoogle = false;

  static const Color primary =
  Color(0xFF6C5CE7);

  @override
  void initState() {
    super.initState();

    listenAuth();
  }

  /// =====================================
  /// 🔥 AUTH LISTENER
  /// =====================================

  void listenAuth() {
    authSubscription = supabase
        .auth.onAuthStateChange
        .listen(
          (data) async {
        final session =
            data.session;

        if (session == null) {
          return;
        }

        final user =
            session.user;

        try {
          final profile =
          await supabase
              .from('profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();

          if (!mounted) return;

          if (profile != null) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const HomeScreen(),
              ),
                  (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RegisterScreen(
                      email:
                      user.email ??
                          '',
                    ),
              ),
                  (route) => false,
            );
          }
        } catch (_) {}
      },
    );
  }

  /// =====================================
  /// 🔔 SNACKBAR
  /// =====================================

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(text),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  /// =====================================
  /// 📧 EMAIL VALIDATION
  /// =====================================

  bool isValidEmail(
      String email,
      ) {
    return RegExp(
      r'^[^@]+@[^@]+\.[^@]+',
    ).hasMatch(email);
  }

  /// =====================================
  /// 📩 SEND OTP
  /// =====================================

  Future<void> sendOtp() async {
    final email =
    emailController.text
        .trim()
        .toLowerCase();

    if (!isValidEmail(email)) {
      showMessage(
        'Enter valid email',
      );
      return;
    }

    if (loadingEmail) return;

    setState(() {
      loadingEmail = true;
    });

    try {
      await supabase.auth
          .signInWithOtp(
        email: email,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VerifyOtpScreen(
                email: email,
              ),
        ),
      );
    } catch (_) {
      showMessage(
        'Failed to send OTP',
      );
    } finally {
      if (mounted) {
        setState(() {
          loadingEmail = false;
        });
      }
    }
  }

  /// =====================================
  /// 🔵 GOOGLE LOGIN
  /// =====================================

  Future<void>
  loginWithGoogle() async {
    if (loadingGoogle) return;

    setState(() {
      loadingGoogle = true;
    });

    try {
      await supabase.auth
          .signInWithOAuth(
        OAuthProvider.google,
        redirectTo:
        'io.supabase.flutter://login-callback/',
        authScreenLaunchMode:
        LaunchMode.externalApplication,
      );
    } catch (_) {
      showMessage(
        'Google login failed',
      );

      if (mounted) {
        setState(() {
          loadingGoogle = false;
        });
      }
    }
  }

  /// =====================================
  /// UI
  /// =====================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6FF),

      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context)
                .unfocus();
          },
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 20,
            ),
            child: SizedBox(
              height:
              MediaQuery.of(context)
                  .size
                  .height -
                  60,
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment
                    .center,
                children: [
                  /// LOGO
                  Container(
                    width: 100,
                    height: 100,
                    decoration:
                    BoxDecoration(
                      color: primary
                          .withValues(
                        alpha: 0.1,
                      ),
                      shape:
                      BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat,
                      size: 50,
                      color: primary,
                    ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  const Text(
                    'Welcome to NIMO',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  const Text(
                    'Fast, secure & realtime messaging',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(
                    height: 40,
                  ),

                  /// EMAIL FIELD
                  Container(
                    decoration:
                    BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                      BorderRadius
                          .circular(
                        18,
                      ),
                    ),
                    child: TextField(
                      controller:
                      emailController,
                      keyboardType:
                      TextInputType
                          .emailAddress,
                      decoration:
                      const InputDecoration(
                        hintText:
                        'Enter your email',
                        prefixIcon:
                        Icon(
                          Icons
                              .email_outlined,
                        ),
                        border:
                        InputBorder.none,
                        contentPadding:
                        EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  /// EMAIL BUTTON
                  SizedBox(
                    width:
                    double.infinity,
                    height: 56,
                    child:
                    ElevatedButton(
                      onPressed:
                      loadingEmail
                          ? null
                          : sendOtp,
                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        primary,
                        foregroundColor:
                        Colors.white,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                        ),
                      ),
                      child:
                      loadingEmail
                          ? const SizedBox(
                        width: 24,
                        height:
                        24,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2.5,
                          color: Colors
                              .white,
                        ),
                      )
                          : const Text(
                        'Continue with Email',
                        style:
                        TextStyle(
                          fontSize:
                          16,
                          fontWeight:
                          FontWeight
                              .w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  /// DIVIDER
                  Row(
                    children: [
                      Expanded(
                        child:
                        Divider(
                          color: Colors
                              .grey
                              .shade300,
                        ),
                      ),
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                        child: Text(
                          'OR',
                          style:
                          TextStyle(
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                        Divider(
                          color: Colors
                              .grey
                              .shade300,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  /// GOOGLE BUTTON
                  SizedBox(
                    width:
                    double.infinity,
                    height: 56,
                    child:
                    OutlinedButton(
                      onPressed:
                      loadingGoogle
                          ? null
                          : loginWithGoogle,
                      style:
                      OutlinedButton.styleFrom(
                        backgroundColor:
                        Colors.white,
                        side: BorderSide(
                          color: Colors
                              .grey
                              .shade300,
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                        ),
                      ),
                      child:
                      loadingGoogle
                          ? const SizedBox(
                        width: 24,
                        height:
                        24,
                        child:
                        CircularProgressIndicator(),
                      )
                          : const Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons
                                .g_mobiledata,
                            size: 40,
                            color:
                            Colors.red,
                          ),
                          SizedBox(
                            width: 6,
                          ),
                          Text(
                            'Continue with Google',
                            style:
                            TextStyle(
                              color:
                              Colors.black,
                              fontSize:
                              15,
                              fontWeight:
                              FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  Text(
                    'By continuing you agree to NIMO Terms & Privacy Policy',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      color: Colors
                          .grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
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

/// =====================================
/// 🔐 VERIFY OTP SCREEN
/// =====================================

class VerifyOtpScreen
    extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyOtpScreen>
  createState() =>
      _VerifyOtpScreenState();
}

class _VerifyOtpScreenState
    extends State<
        VerifyOtpScreen> {
  final SupabaseClient supabase =
      Supabase.instance.client;

  final TextEditingController
  otpController =
  TextEditingController();

  bool loading = false;

  static const Color primary =
  Color(0xFF6C5CE7);

  /// =====================================
  /// 🔔 SNACKBAR
  /// =====================================

  void showMessage(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(text),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  /// =====================================
  /// ✅ VERIFY OTP
  /// =====================================

  Future<void> verifyOtp() async {
    final otp =
    otpController.text.trim();

    if (otp.length != 6) {
      showMessage(
        'Enter 6-digit OTP',
      );
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

      final user =
          supabase.auth.currentUser;

      if (user == null) {
        showMessage(
          'Authentication failed',
        );
        return;
      }

      final profile =
      await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (profile != null) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
            const HomeScreen(),
          ),
              (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                RegisterScreen(
                  email:
                  widget.email,
                ),
          ),
              (route) => false,
        );
      }
    } catch (_) {
      showMessage(
        'Invalid OTP',
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  /// =====================================
  /// UI
  /// =====================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6FF),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
        Colors.transparent,
      ),

      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context)
                .unfocus();
          },
          child: Padding(
            padding:
            const EdgeInsets.all(
              24,
            ),
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment
                  .center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration:
                  BoxDecoration(
                    color: primary
                        .withValues(
                      alpha: 0.1,
                    ),
                    shape:
                    BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    size: 42,
                    color: primary,
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                const Text(
                  'Verify OTP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                Text(
                  widget.email,
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 35,
                ),

                /// OTP FIELD
                Container(
                  decoration:
                  BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius
                        .circular(
                      18,
                    ),
                  ),
                  child: TextField(
                    controller:
                    otpController,
                    keyboardType:
                    TextInputType
                        .number,
                    maxLength: 6,
                    textAlign:
                    TextAlign.center,
                    style:
                    const TextStyle(
                      fontSize: 22,
                      letterSpacing:
                      8,
                      fontWeight:
                      FontWeight.bold,
                    ),
                    decoration:
                    const InputDecoration(
                      hintText:
                      '------',
                      counterText:
                      '',
                      border:
                      InputBorder.none,
                      contentPadding:
                      EdgeInsets.symmetric(
                        vertical: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 28,
                ),

                /// VERIFY BUTTON
                SizedBox(
                  width:
                  double.infinity,
                  height: 56,
                  child:
                  ElevatedButton(
                    onPressed:
                    loading
                        ? null
                        : verifyOtp,
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      primary,
                      foregroundColor:
                      Colors.white,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          18,
                        ),
                      ),
                    ),
                    child:
                    loading
                        ? const SizedBox(
                      width:
                      24,
                      height:
                      24,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2.5,
                        color: Colors
                            .white,
                      ),
                    )
                        : const Text(
                      'Verify OTP',
                      style:
                      TextStyle(
                        fontSize:
                        16,
                        fontWeight:
                        FontWeight
                            .w600,
                      ),
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