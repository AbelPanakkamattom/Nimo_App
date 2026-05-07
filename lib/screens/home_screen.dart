import 'package:flutter/material.dart';

import 'ai_screen.dart';
import 'calls_screen.dart';
import 'chats_screen.dart';
import 'email_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  int currentIndex = 0;

  final List<Widget> screens =
  const [
    ChatsScreen(),
    EmailScreen(),
    CallsScreen(),
    AIScreen(),
    ProfileScreen(),
  ];

  final List<_BottomItem>
  items = const [
    _BottomItem(
      icon: Icons.chat_bubble_rounded,
      label: "Chats",
    ),

    _BottomItem(
      icon: Icons.email_rounded,
      label: "Email",
    ),

    _BottomItem(
      icon: Icons.call_rounded,
      label: "Calls",
    ),

    _BottomItem(
      icon: Icons.auto_awesome_rounded,
      label: "AI",
    ),

    _BottomItem(
      icon: Icons.person_rounded,
      label: "Profile",
    ),
  ];

  /// =========================
  /// 🔄 CHANGE TAB
  /// =========================

  void changeTab(int index) {
    if (currentIndex == index) {
      return;
    }

    setState(() {
      currentIndex = index;
    });
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

      extendBody: true,

      /// =========================
      /// 📱 MAIN CONTENT
      /// =========================

      body: Stack(
        children: [
          /// 🔥 BACKGROUND
          Container(
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
          ),

          /// 🔥 SCREENS
          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.only(
                bottom: 95,
              ),

              child: IndexedStack(
                index: currentIndex,
                children: screens,
              ),
            ),
          ),
        ],
      ),

      /// =========================
      /// 🔻 BOTTOM NAVIGATION
      /// =========================

      bottomNavigationBar:
      SafeArea(
        minimum:
        const EdgeInsets.only(
          left: 14,
          right: 14,
          bottom: 14,
        ),

        child: Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),

          decoration:
          BoxDecoration(
            color:
            Colors.white.withValues(
              alpha: 0.97,
            ),

            borderRadius:
            BorderRadius.circular(
              32,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(
                  alpha: 0.08,
                ),
                blurRadius: 18,
                offset:
                const Offset(
                  0,
                  8,
                ),
              ),
            ],
          ),

          child: Row(
            mainAxisAlignment:
            MainAxisAlignment
                .spaceAround,

            children:
            List.generate(
              items.length,
                  (index) {
                final active =
                    currentIndex ==
                        index;

                return InkWell(
                  borderRadius:
                  BorderRadius.circular(
                    24,
                  ),

                  onTap: () {
                    changeTab(
                      index,
                    );
                  },

                  child:
                  AnimatedContainer(
                    duration:
                    const Duration(
                      milliseconds:
                      250,
                    ),

                    curve: Curves
                        .easeInOut,

                    padding:
                    EdgeInsets.symmetric(
                      horizontal:
                      active
                          ? 16
                          : 12,
                      vertical: 10,
                    ),

                    decoration:
                    BoxDecoration(
                      color: active
                          ? primary
                          : Colors
                          .transparent,

                      borderRadius:
                      BorderRadius.circular(
                        22,
                      ),
                    ),

                    child: Row(
                      children: [
                        Icon(
                          items[index]
                              .icon,

                          size: 22,

                          color: active
                              ? Colors
                              .white
                              : Colors
                              .grey
                              .shade600,
                        ),

                        if (active)
                          ...[
                            const SizedBox(
                              width: 7,
                            ),

                            Text(
                              items[index]
                                  .label,

                              style:
                              const TextStyle(
                                color: Colors
                                    .white,
                                fontWeight:
                                FontWeight.w600,
                                fontSize:
                                14,
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

/// =====================================
/// 🔻 BOTTOM ITEM MODEL
/// =====================================

class _BottomItem {
  final IconData icon;
  final String label;

  const _BottomItem({
    required this.icon,
    required this.label,
  });
}