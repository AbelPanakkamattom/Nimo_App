import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'services/supabase_chat_service.dart';

/// =======================================
/// 🌍 GLOBAL SUPABASE CLIENT
/// =======================================

late final SupabaseClient supabase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// STATUS BAR
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor:
      Colors.transparent,
      statusBarIconBrightness:
      Brightness.dark,
    ),
  );

  try {
    /// LOAD ENV
    await dotenv.load(
      fileName: '.env',
    );

    final url =
    dotenv.env['SUPABASE_URL']
        ?.trim();

    final anonKey = dotenv
        .env['SUPABASE_ANON_KEY']
        ?.trim();

    if (url == null ||
        url.isEmpty ||
        anonKey == null ||
        anonKey.isEmpty) {
      throw Exception(
        'Missing Supabase credentials',
      );
    }

    /// INIT SUPABASE
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: true,

      authOptions:
      const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );

    supabase =
        Supabase.instance.client;

    runApp(
      const MyApp(),
    );
  } catch (e) {
    debugPrint(
      'MAIN INIT ERROR: $e',
    );

    runApp(
      const ConfigErrorApp(),
    );
  }
}

/// =======================================
/// 🚀 MAIN APP
/// =======================================

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() =>
      _MyAppState();
}

class _MyAppState
    extends State<MyApp>
    with WidgetsBindingObserver {
  static const Color primary =
  Color(0xFF6C5CE7);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addObserver(this);

    /// USER ONLINE
    SupabaseChatService
        .setOnlineStatus(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .removeObserver(this);

    /// USER OFFLINE
    SupabaseChatService
        .setOnlineStatus(false);

    super.dispose();
  }

  /// =======================================
  /// 📱 APP LIFECYCLE
  /// =======================================

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    if (state ==
        AppLifecycleState.resumed) {
      SupabaseChatService
          .setOnlineStatus(true);
    }

    if (state ==
        AppLifecycleState
            .paused ||
        state ==
            AppLifecycleState
                .detached) {
      SupabaseChatService
          .setOnlineStatus(false);
    }
  }

  /// =======================================
  /// 🎨 THEME
  /// =======================================

  ThemeData buildTheme() {
    return ThemeData(
      useMaterial3: true,

      colorScheme:
      ColorScheme.fromSeed(
        seedColor: primary,
      ),

      scaffoldBackgroundColor:
      const Color(0xFFF5F6FF),

      fontFamily: 'Roboto',

      splashColor:
      Colors.transparent,

      highlightColor:
      Colors.transparent,

      dividerColor:
      Colors.transparent,

      /// APPBAR
      appBarTheme:
      const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor:
        Colors.transparent,

        surfaceTintColor:
        Colors.transparent,

        iconTheme: IconThemeData(
          color: Colors.black,
        ),

        titleTextStyle:
        TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight:
          FontWeight.bold,
        ),
      ),

      /// INPUT
      inputDecorationTheme:
      InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,

        hintStyle: TextStyle(
          color:
          Colors.grey.shade500,
        ),

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),

        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            18,
          ),
          borderSide:
          BorderSide.none,
        ),

        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            18,
          ),
          borderSide:
          BorderSide.none,
        ),

        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            18,
          ),
          borderSide:
          const BorderSide(
            color: primary,
            width: 1.3,
          ),
        ),
      ),

      /// BUTTONS
      elevatedButtonTheme:
      ElevatedButtonThemeData(
        style:
        ElevatedButton.styleFrom(
          backgroundColor:
          primary,
          foregroundColor:
          Colors.white,

          elevation: 0,

          minimumSize:
          const Size(
            double.infinity,
            55,
          ),

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
          ),
        ),
      ),

      /// FAB
      floatingActionButtonTheme:
      const FloatingActionButtonThemeData(
        backgroundColor:
        primary,
        foregroundColor:
        Colors.white,
      ),

      /// CARD
      cardTheme:
      const CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor:
        Colors.white,
      ),

      /// SNACKBAR
      snackBarTheme:
      SnackBarThemeData(
        behavior:
        SnackBarBehavior.floating,

        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(
            14,
          ),
        ),
      ),

      /// BOTTOM SHEET
      bottomSheetTheme:
      const BottomSheetThemeData(
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.white,
      ),
    );
  }

  /// =======================================
  /// UI
  /// =======================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return MaterialApp(
      title: 'NIMO',

      debugShowCheckedModeBanner:
      false,

      theme: buildTheme(),

      /// KEYBOARD DISMISS
      builder:
          (context, child) {
        return GestureDetector(
          onTap: () {
            FocusManager.instance
                .primaryFocus
                ?.unfocus();
          },
          child: child!,
        );
      },

      /// START SCREEN
      home: const SplashScreen(),

      routes: {
        '/auth': (_) =>
        const AuthScreen(),

        '/home': (_) =>
        const HomeScreen(),
      },
    );
  }
}

/// =======================================
/// ❌ CONFIG ERROR APP
/// =======================================

class ConfigErrorApp
    extends StatelessWidget {
  const ConfigErrorApp({
    super.key,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return MaterialApp(
      debugShowCheckedModeBanner:
      false,

      home: Scaffold(
        backgroundColor:
        const Color(
          0xFFF5F6FF,
        ),

        body: Center(
          child: Padding(
            padding:
            const EdgeInsets.all(
              24,
            ),
            child: Container(
              padding:
              const EdgeInsets.all(
                24,
              ),

              decoration:
              BoxDecoration(
                color: Colors.white,

                borderRadius:
                BorderRadius.circular(
                  24,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(
                      alpha: 0.05,
                    ),
                    blurRadius: 15,
                  ),
                ],
              ),

              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 70,
                    color: Colors.red,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'Configuration Error',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  Text(
                    'Supabase credentials are missing.\n\nCheck your .env file.',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      color: Colors
                          .grey.shade700,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  Container(
                    width:
                    double.infinity,

                    padding:
                    const EdgeInsets.all(
                      16,
                    ),

                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFFF5F6FF,
                      ),

                      borderRadius:
                      BorderRadius.circular(
                        16,
                      ),
                    ),

                    child: const Text(
                      'Required:\n\nSUPABASE_URL\nSUPABASE_ANON_KEY',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.w600,
                      ),
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