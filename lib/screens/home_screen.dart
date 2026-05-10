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
  static const Color primary =
  Color(0xFF6C5CE7);

  int currentIndex = 0;

  final List<Widget> screens =
  const [
    ChatsScreen(),
    EmailScreen(),
    CallsScreen(),
    AIScreen(),
    ProfileScreen(),
  ];

  final List<_BottomItem> items =
  const [
    _BottomItem(
      icon:
      Icons.chat_bubble_rounded,
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
      icon:
      Icons.auto_awesome_rounded,
      label: 'AI',
    ),
    _BottomItem(
      icon:
      Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  void changeTab(int index) {
    if (currentIndex == index) {
      return;
    }

    setState(() {
      currentIndex = index;
    });
  }

  VoidCallback? _buildFabAction() {
    switch (currentIndex) {
      case 0:
        return () {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Start a new chat',
              ),
              behavior:
              SnackBarBehavior
                  .floating,
            ),
          );
        };

      case 1:
        return () {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Compose email',
              ),
              behavior:
              SnackBarBehavior
                  .floating,
            ),
          );
        };

      case 2:
        return () {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Start a call',
              ),
              behavior:
              SnackBarBehavior
                  .floating,
            ),
          );
        };

      case 3:
        return () {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            const SnackBar(
              content: Text(
                'Ask NIMO AI',
              ),
              behavior:
              SnackBarBehavior
                  .floating,
            ),
          );
        };

      default:
        return null;
    }
  }

  IconData _buildFabIcon() {
    switch (currentIndex) {
      case 0:
        return Icons.edit_rounded;
      case 1:
        return Icons.add_rounded;
      case 2:
        return Icons.call_rounded;
      case 3:
        return Icons.auto_awesome_rounded;
      default:
        return Icons.add_rounded;
    }
  }

  bool get _showFab {
    return currentIndex != 4;
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(
        0xFFF5F6FF,
      ),
      extendBody: true,

      body: Stack(
        children: [
          Container(
            decoration:
            const BoxDecoration(
              gradient:
              LinearGradient(
                colors: [
                  Color(
                    0xFFF7F8FF,
                  ),
                  Color(
                    0xFFEDE9FF,
                  ),
                ],
                begin:
                Alignment
                    .topCenter,
                end: Alignment
                    .bottomCenter,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.only(
                bottom: 100,
              ),
              child: IndexedStack(
                index: currentIndex,
                children: screens,
              ),
            ),
          ),
        ],
      ),

      floatingActionButton:
      _showFab
          ? FloatingActionButton(
        onPressed:
        _buildFabAction(),
        backgroundColor:
        primary,
        foregroundColor:
        Colors.white,
        child: Icon(
          _buildFabIcon(),
        ),
      )
          : null,

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
          decoration: BoxDecoration(
            color: Colors.white
                .withAlpha(245),
            borderRadius:
            BorderRadius.circular(
              32,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withAlpha(18),
                blurRadius: 20,
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
                  BorderRadius
                      .circular(
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
                      vertical:
                      10,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      active
                          ? primary
                          : Colors
                          .transparent,
                      borderRadius:
                      BorderRadius
                          .circular(
                        22,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          items[index]
                              .icon,
                          size: 22,
                          color:
                          active
                              ? Colors
                              .white
                              : Colors
                              .grey
                              .shade600,
                        ),
                        if (active)
                          ...[
                            const SizedBox(
                              width:
                              7,
                            ),
                            Text(
                              items[
                              index]
                                  .label,
                              style:
                              const TextStyle(
                                color:
                                Colors.white,
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

class _BottomItem {
  final IconData icon;
  final String label;

  const _BottomItem({
    required this.icon,
    required this.label,
  });
}