import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/chats_screen.dart';
import 'screens/contacts_screen.dart';
import 'screens/profile_screen.dart';

/// 🌍 GLOBAL CLIENT
late final SupabaseClient supabase;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    /// 🔐 LOAD ENV
    await dotenv.load(fileName: ".env");

    final url = dotenv.env['SUPABASE_URL']?.trim();
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim();

    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      throw Exception("Missing Supabase credentials");
    }

    /// 🚀 INIT SUPABASE
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      debug: true,
    );

    supabase = Supabase.instance.client;

    runApp(const MyApp());
  } catch (e) {
    runApp(const ConfigErrorApp());
  }
}

/// =======================
/// 🔥 MAIN APP
/// =======================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "NIMO",
      debugShowCheckedModeBanner: false,

      /// 🎨 THEME
      theme: _buildTheme(),

      /// 👇 DISMISS KEYBOARD
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child!,
        );
      },

      /// 🚀 ENTRY POINT
      home: const RootDecider(),

      /// ROUTES
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/chats': (_) => const ChatsScreen(),
        '/contacts': (_) => const ContactsScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }

  ThemeData _buildTheme() {
    const primary = Color(0xFF6C5CE7);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary),
      scaffoldBackgroundColor: const Color(0xFFF5F6FF),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// =======================
/// 🧠 ROOT DECIDER (FIXED)
/// =======================
class RootDecider extends StatefulWidget {
  const RootDecider({super.key});

  @override
  State<RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends State<RootDecider> {
  @override
  void initState() {
    super.initState();
    _handleAuth();
  }

  Future<void> _handleAuth() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final session = supabase.auth.currentSession;

    if (!mounted) return;

    if (session == null) {
      Navigator.pushReplacementNamed(context, '/auth');
    } else {
      Navigator.pushReplacementNamed(context, '/chats');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}

/// =======================
/// ❌ ERROR SCREEN
/// =======================
class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "❌ Missing Supabase configuration\n\n"
                  "Check your .env file\n\n"
                  "Required:\nSUPABASE_URL\nSUPABASE_ANON_KEY",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}