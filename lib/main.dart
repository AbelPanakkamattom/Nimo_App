import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

import 'services/notification_service.dart';
import 'services/online_service.dart';
import 'services/zego_call_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =========================================================
  // INSTALL ZEGO SIGNALING PLUGIN GLOBALLY
  // THIS IS REQUIRED FOR CALL INVITATIONS TO WORK
  // =========================================================
  ZegoUIKit().installPlugins([
    ZegoUIKitSignalingPlugin(),
  ]);

  // Lock portrait mode
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Load .env
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('ENV LOAD ERROR: $e');
  }

  // Initialize Supabase
  try {
    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url != null &&
        url.isNotEmpty &&
        anonKey != null &&
        anonKey.isNotEmpty) {
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: false,
      );
    } else {
      debugPrint(
        'SUPABASE_URL or SUPABASE_ANON_KEY missing in .env',
      );
    }
  } catch (e) {
    debugPrint('SUPABASE INIT ERROR: $e');
  }

  // Initialize notifications
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('NOTIFICATION INIT ERROR: $e');
  }

  // Register ZEGO navigator key
  ZegoCallService.registerPlugins();

  runApp(const NimoApp());
}

// =========================================================
// APP ROOT
// =========================================================

class NimoApp extends StatelessWidget {
  const NimoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NIMO',
      debugShowCheckedModeBanner: false,
      navigatorKey: ZegoCallService.navigatorKey,
      theme: _buildTheme(),
      home: const AppBootstrapper(),
      builder: (context, child) {
        return child ?? const SizedBox();
      },
    );
  }
}

// =========================================================
// APP BOOTSTRAPPER
// =========================================================

class AppBootstrapper extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() =>
      _AppBootstrapperState();
}

class _AppBootstrapperState extends State<AppBootstrapper>
    with WidgetsBindingObserver {
  bool _initialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await OnlineService.setOnline();
      await _initializeZego();

      await Future.delayed(
        const Duration(milliseconds: 1800),
      );

      if (!mounted) return;

      setState(() {
        _initialized = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _initializeZego() async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) return;

      final userName =
      user.userMetadata?['full_name']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? user.userMetadata!['full_name']
          .toString()
          .trim()
          : user.userMetadata?['name']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true
          ? user.userMetadata!['name']
          .toString()
          .trim()
          : user.email?.split('@').first ??
          'NIMO User';

      // Pass the original Supabase UUID.
      // ZegoCallService converts it to a ZEGO-safe ID.
      await ZegoCallService.init(
        userID: user.id,
        userName: userName,
      );
    } catch (e) {
      debugPrint('ZEGO INIT ERROR: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    switch (state) {
      case AppLifecycleState.resumed:
        OnlineService.setOnline();
        break;

      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        OnlineService.setOffline();
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OnlineService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return ErrorScreen(
        message: _errorMessage,
      );
    }

    if (!_initialized) {
      return const SplashScreen();
    }

    return const AuthGate();
  }
}

// =========================================================
// AUTH GATE
// =========================================================

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final session =
          Supabase.instance.client.auth.currentSession;

      if (session != null) {
        return const HomeScreen();
      }

      return const AuthScreen();
    } catch (_) {
      return const AuthScreen();
    }
  }
}

// =========================================================
// ERROR SCREEN
// =========================================================

class ErrorScreen extends StatelessWidget {
  final String message;

  const ErrorScreen({
    super.key,
    required this.message,
  });

  static const Color primary =
  Color(0xFF6C5CE7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6FF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
            const EdgeInsets.all(24),
            child: Container(
              padding:
              const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.03,
                    ),
                    blurRadius: 20,
                    offset:
                    const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  const Text(
                    'NIMO Failed to Start',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                      FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Text(
                    message,
                    textAlign:
                    TextAlign.center,
                    style:
                    const TextStyle(
                      color:
                      Colors.grey,
                      height: 1.5,
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
}

// =========================================================
// APP THEME
// =========================================================

ThemeData _buildTheme() {
  const Color primary =
  Color(0xFF6C5CE7);
  const Color secondary =
  Color(0xFF8E7BFF);
  const Color background =
  Color(0xFFF5F6FF);

  final colorScheme =
  ColorScheme.fromSeed(
    seedColor: primary,
    primary: primary,
    secondary: secondary,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor:
    background,
    colorScheme: colorScheme,
  );
}