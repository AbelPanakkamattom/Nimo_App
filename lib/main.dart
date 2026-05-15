import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import 'firebase_options.dart';

import 'providers/theme_provider.dart';

import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

import 'services/notification_service.dart';
import 'services/online_service.dart';
import 'services/zego_call_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService
      .firebaseMessagingBackgroundHandler(
    message,
  );
}

// =========================================================
// MAIN
// =========================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Install Zego signaling plugin
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
    ),
  );

  // Load .env
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('ENV LOADED');
  } catch (e) {
    debugPrint('ENV LOAD ERROR: $e');
  }

  // Initialize Supabase
  try {
    final url =
        dotenv.env['SUPABASE_URL'] ?? '';
    final anonKey =
        dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    if (url.isEmpty || anonKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL or SUPABASE_ANON_KEY missing in .env',
      );
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: false,
    );

    debugPrint('SUPABASE INITIALIZED');
  } catch (e) {
    debugPrint('SUPABASE INIT ERROR: $e');
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('FIREBASE INITIALIZED');
  } catch (e) {
    debugPrint('FIREBASE INIT ERROR: $e');
  }

  // Background push handler
  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  // Initialize notifications
  try {
    await NotificationService.initialize();
    await NotificationService.saveTokenToSupabase();
    NotificationService.listenForTokenRefresh();
    debugPrint('NOTIFICATIONS INITIALIZED');
  } catch (e) {
    debugPrint('NOTIFICATION INIT ERROR: $e');
  }

  // Register Zego plugins
  ZegoCallService.registerPlugins();

  // Check Gemini API key
  final geminiApiKey =
  dotenv.env['GEMINI_API_KEY'];

  if (geminiApiKey == null ||
      geminiApiKey.isEmpty) {
    debugPrint(
      'WARNING: GEMINI_API_KEY missing',
    );
  } else {
    debugPrint('GEMINI API KEY FOUND');
  }

  // Run App with ThemeProvider
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const NimoApp(),
    ),
  );
}

// =========================================================
// ROOT APP
// =========================================================

class NimoApp extends StatelessWidget {
  const NimoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider =
    Provider.of<ThemeProvider>(context);

    // Wait until theme is loaded
    if (!themeProvider.isLoaded) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      );
    }

    return MaterialApp(
      title: 'NIMO',
      debugShowCheckedModeBanner: false,
      navigatorKey:
      ZegoCallService.navigatorKey,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeProvider.themeMode,
      home: const AppBootstrapper(),
      builder: (
          BuildContext context,
          Widget? child,
          ) {
        return child ??
            const SizedBox.shrink();
      },
    );
  }
}

// =========================================================
// APP INITIALIZATION
// =========================================================

class AppBootstrapper
    extends StatefulWidget {
  const AppBootstrapper({super.key});

  @override
  State<AppBootstrapper> createState() =>
      _AppBootstrapperState();
}

class _AppBootstrapperState
    extends State<AppBootstrapper>
    with WidgetsBindingObserver {
  bool _initialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(
      this,
    );

    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await OnlineService.setOnline();
      await _initializeZego();
      await NotificationService
          .saveTokenToSupabase();

      await Future.delayed(
        const Duration(
          milliseconds: 1800,
        ),
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
      final user = Supabase
          .instance
          .client
          .auth
          .currentUser;

      if (user == null) return;

      final metadata =
          user.userMetadata ?? {};

      final userName =
      (metadata['full_name']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true)
          ? metadata['full_name']
          .toString()
          .trim()
          : (metadata['name']
          ?.toString()
          .trim()
          .isNotEmpty ==
          true)
          ? metadata['name']
          .toString()
          .trim()
          : user.email
          ?.split('@')
          .first ??
          'NIMO User';

      await ZegoCallService.init(
        userID: user.id,
        userName: userName,
      );

      debugPrint('ZEGO INITIALIZED');
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
    WidgetsBinding.instance
        .removeObserver(this);

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
      final session = Supabase
          .instance
          .client
          .auth
          .currentSession;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding:
          const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// =========================================================
// LIGHT THEME
// =========================================================

ThemeData _buildLightTheme() {
  const primary = Color(0xFF6C5CE7);

  final colorScheme =
  ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor:
    const Color(0xFFF5F6FF),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor:
      Color(0xFFF5F6FF),
      foregroundColor:
      Colors.black87,
      surfaceTintColor:
      Colors.transparent,
    ),
  );
}

// =========================================================
// DARK THEME
// =========================================================

ThemeData _buildDarkTheme() {
  const primary = Color(0xFF6C5CE7);

  final colorScheme =
  ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.dark,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor:
    const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      backgroundColor:
      Color(0xFF121212),
      foregroundColor:
      Colors.white,
      surfaceTintColor:
      Colors.transparent,
    ),
  );
}