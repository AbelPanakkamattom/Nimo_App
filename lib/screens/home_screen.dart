import 'package:flutter/material.dart';

import 'ai_screen.dart';
import 'calls_screen.dart';
import 'chats_screen.dart';
import 'contacts_screen.dart';
import 'email_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // =========================================================
  // COLORS
  // =========================================================

  static const Color primary = Color(0xFF6C5CE7);
  static const Color background = Color(0xFFF5F6FF);

  // =========================================================
  // STATE
  // =========================================================

  int currentIndex = 0;

  // =========================================================
  // SCREENS
  // =========================================================

  final List<Widget> screens = const [
    ChatsScreen(),
    EmailScreen(),
    CallsScreen(),
    AIScreen(),
    ProfileScreen(),
  ];

  // =========================================================
  // NAVIGATION ITEMS
  // =========================================================

  final List<_BottomItem> items = const [
    _BottomItem(
      icon: Icons.chat_bubble_rounded,
      label: 'Chats',
    ),
    _BottomItem(
      icon: Icons.email_rounded,
      label: 'Email',
    ),
    _BottomItem(
      icon: Icons.call_rounded,
      label: 'Calls',
    ),
    _BottomItem(
      icon: Icons.auto_awesome_rounded,
      label: 'AI',
    ),
    _BottomItem(
      icon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  // =========================================================
  // TAB CHANGE
  // =========================================================

  void changeTab(int index) {
    if (currentIndex == index) return;

    setState(() {
      currentIndex = index;
    });
  }

  // =========================================================
  // FLOATING ACTION BUTTON
  // =========================================================

  bool get _showFab => currentIndex != 4;

  IconData _buildFabIcon() {
    switch (currentIndex) {
      case 0:
        return Icons.edit_rounded; // Chats
      case 1:
        return Icons.add_rounded; // Email
      case 2:
        return Icons.call_rounded; // Calls
      case 3:
        return Icons.auto_awesome_rounded; // AI
      default:
        return Icons.add_rounded;
    }
  }

  VoidCallback? _buildFabAction() {
    switch (currentIndex) {
    // =====================================================
    // CHATS → OPEN CONTACTS SCREEN
    // =====================================================
      case 0:
        return () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ContactsScreen(),
            ),
          );
        };

    // =====================================================
    // EMAIL
    // =====================================================
      case 1:
        return () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Compose email'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        };

    // =====================================================
    // CALLS
    // =====================================================
      case 2:
        return () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ContactsScreen(),
            ),
          );
        };

    // =====================================================
    // AI
    // =====================================================
      case 3:
        return () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Start a new AI conversation'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        };

      default:
        return null;
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      extendBody: true,

      // =====================================================
      // MAIN CONTENT
      // =====================================================
      body: SafeArea(
        child: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
      ),

      // =====================================================
      // FLOATING ACTION BUTTON
      // =====================================================
      floatingActionButton: _showFab
          ? FloatingActionButton(
        onPressed: _buildFabAction(),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 10,
        child: Icon(_buildFabIcon()),
      )
          : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // =====================================================
      // CUSTOM BOTTOM NAVIGATION BAR
      // =====================================================
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: 14,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(245),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
                  (index) {
                final bool active = currentIndex == index;

                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => changeTab(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: active ? 16 : 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: active ? primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          items[index].icon,
                          size: 22,
                          color: active
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                        if (active) ...[
                          const SizedBox(width: 7),
                          Text(
                            items[index].label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================
// BOTTOM NAVIGATION ITEM MODEL
// =========================================================

class _BottomItem {
  final IconData icon;
  final String label;

  const _BottomItem({
    required this.icon,
    required this.label,
  });
}