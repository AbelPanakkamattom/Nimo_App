import 'package:flutter/material.dart';
import 'chats_screen.dart';
import 'email_screen.dart';
import 'calls_screen.dart';
import 'ai_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  final List<Widget> screens = const [
    ChatsScreen(),
    EmailScreen(),
    CallsScreen(),
    AIScreen(),
    ProfileScreen(),
  ];

  void _changeTab(int i) {
    if (index == i) return;
    setState(() => index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),

      /// 📱 MAIN CONTENT
      body: IndexedStack(
        index: index,
        children: screens,
      ),

      /// 🔻 FIXED BOTTOM NAV (PROPER WAY)
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final active = index == i;

            return GestureDetector(
              onTap: () => _changeTab(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF6C5CE7)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      _items[i].icon,
                      color: active ? Colors.white : Colors.grey,
                    ),
                    if (active) ...[
                      const SizedBox(width: 6),
                      Text(
                        _items[i].label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// 🔹 NAV ITEMS
class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem(this.icon, this.label);
}

/// 🔹 NAV LIST
const List<_NavItem> _items = [
  _NavItem(Icons.chat, "Chats"),
  _NavItem(Icons.email, "Email"),
  _NavItem(Icons.call, "Calls"),
  _NavItem(Icons.auto_awesome, "AI"),
  _NavItem(Icons.person, "Profile"),
];