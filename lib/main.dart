import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Screens
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

// Services
import 'services/notification_service.dart';
import 'services/online_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =========================================================
  // LOCK PORTRAIT MODE
  // =========================================================
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // =========================================================
  // STATUS BAR STYLE
  // =========================================================
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // =========================================================
  // LOAD ENVIRONMENT VARIABLES
  // =========================================================
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('ENV LOAD ERROR: $e');
  }

  // =========================================================
  // INITIALIZE SUPABASE
  // =========================================================
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

  // =========================================================
  // INITIALIZE LOCAL NOTIFICATIONS
  // =========================================================
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('NOTIFICATION INIT ERROR: $e');
  }

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
      theme: _buildTheme(),
      home: const AppBootstrapper(),
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

class _AppBootstrapperState
    extends State<AppBootstrapper>
    with WidgetsBindingObserver {
  bool _initialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  // =========================================================
  // INITIALIZE APP SERVICES
  // =========================================================

  Future<void> _initialize() async {
    try {
      // Set current user online if logged in
      await OnlineService.setOnline();

      // Splash delay
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

  // =========================================================
  // APP LIFECYCLE
  // =========================================================

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

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    OnlineService.dispose();
    super.dispose();
  }

  // =========================================================
  // BUILD
  // =========================================================

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
          .instance.client.auth.currentSession;

      if (session != null) {
        return const HomeScreen();
      }

      return const AuthScreen();
    } catch (e) {
      debugPrint('AUTH GATE ERROR: $e');
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
                    color: Colors.black
                        .withAlpha(12),
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
                    style: TextStyle(
                      color: Colors
                          .grey.shade700,
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
    scaffoldBackgroundColor: background,
    colorScheme: colorScheme,

    appBarTheme: const AppBarTheme(
      backgroundColor:
      Colors.transparent,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor:
      Colors.transparent,
      iconTheme: IconThemeData(
        color: Colors.black87,
      ),
      titleTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
    ),

    inputDecorationTheme:
    InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
      ),
      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(18),
        borderSide:
        const BorderSide(
          color: primary,
          width: 1.4,
        ),
      ),
    ),

    elevatedButtonTheme:
    ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor:
        Colors.white,
        minimumSize:
        const Size.fromHeight(56),
        elevation: 0,
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight:
          FontWeight.w600,
        ),
      ),
    ),

    floatingActionButtonTheme:
    const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: CircleBorder(),
    ),

    snackBarTheme:
    SnackBarThemeData(
      backgroundColor: primary,
      contentTextStyle:
      const TextStyle(
        color: Colors.white,
      ),
      behavior:
      SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
      ),
    ),

    dividerTheme: DividerThemeData(
      color: Colors.grey.shade200,
      thickness: 1,
    ),
  );
}