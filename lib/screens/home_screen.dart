import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/zego_call_service.dart';

import 'ai_screen.dart';
import 'calls_screen.dart';
import 'chats_screen.dart';
import 'contacts_screen.dart';
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

  static const Color background =
  Color(0xFFF5F6FF);

  int _currentIndex = 0;
  bool _zegoInitializing = false;

  // =========================================================
  // SCREENS
  // =========================================================

  late final List<Widget> _screens =
  const [
    ChatsScreen(),
    EmailScreen(),
    CallsScreen(),
    AIScreen(),
    ProfileScreen(),
  ];

  // =========================================================
  // BOTTOM NAV ITEMS
  // =========================================================

  final List<_BottomItem> _items =
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

  // =========================================================
  // INIT STATE
  // =========================================================

  @override
  void initState() {
    super.initState();

    // Initialize ZEGO after the first frame
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _initializeZego();
    });
  }

  // =========================================================
  // INITIALIZE ZEGO
  // =========================================================

  Future<void>
  _initializeZego() async {
    if (_zegoInitializing) {
      return;
    }

    try {
      final user = Supabase
          .instance
          .client
          .auth
          .currentUser;

      if (user == null) {
        debugPrint(
          'No authenticated user found.',
        );
        return;
      }

      // Already initialized
      if (ZegoCallService
          .isInitialized) {
        debugPrint(
          'ZEGO already initialized.',
        );
        return;
      }

      _zegoInitializing = true;

      final metadata =
          user.userMetadata ?? {};

      final fullName =
      metadata['full_name']
          ?.toString()
          .trim();

      final displayName =
      metadata['display_name']
          ?.toString()
          .trim();

      final name =
      metadata['name']
          ?.toString()
          .trim();

      final username =
      metadata['username']
          ?.toString()
          .trim();

      final String userName;

      if (fullName != null &&
          fullName.isNotEmpty) {
        userName = fullName;
      } else if (displayName !=
          null &&
          displayName.isNotEmpty) {
        userName = displayName;
      } else if (name != null &&
          name.isNotEmpty) {
        userName = name;
      } else if (username !=
          null &&
          username.isNotEmpty) {
        userName = username;
      } else {
        userName =
            user.email
                ?.split('@')
                .first ??
                'NIMO User';
      }

      debugPrint(
        'Initializing ZEGO for '
            '${user.id} '
            '($userName)',
      );

      await ZegoCallService.init(
        userID: user.id,
        userName: userName,
      );

      debugPrint(
        'ZEGO initialized successfully.',
      );
    } catch (e) {
      debugPrint(
        'ZEGO INITIALIZATION ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Call service initialization failed: $e',
          ),
          behavior:
          SnackBarBehavior
              .floating,
        ),
      );
    } finally {
      _zegoInitializing = false;
    }
  }

  // =========================================================
  // CHANGE TAB
  // =========================================================

  void _changeTab(int index) {
    if (_currentIndex == index) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  // =========================================================
  // FLOATING ACTION BUTTON
  // =========================================================

  bool get _showFab =>
      _currentIndex != 4;

  IconData _fabIcon() {
    switch (_currentIndex) {
      case 0:
        return Icons.edit_rounded;
      case 1:
        return Icons.add_rounded;
      case 2:
        return Icons.call_rounded;
      case 3:
        return Icons
            .auto_awesome_rounded;
      default:
        return Icons.add_rounded;
    }
  }

  VoidCallback? _fabAction() {
    switch (_currentIndex) {
    // Chats and Calls
      case 0:
      case 2:
        return () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const ContactsScreen(),
            ),
          );
        };

    // Email
      case 1:
        return () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content:
              Text('Compose email'),
              behavior:
              SnackBarBehavior
                  .floating,
            ),
          );
        };

    // AI
      case 3:
        return () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                'Start a new AI conversation',
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

  Widget? _buildFab() {
    if (!_showFab) {
      return null;
    }

    return FloatingActionButton(
      heroTag: 'home_screen_fab',
      onPressed: _fabAction(),
      backgroundColor: primary,
      foregroundColor:
      Colors.white,
      elevation: 10,
      child: Icon(_fabIcon()),
    );
  }

  // =========================================================
  // BOTTOM NAVIGATION BAR
  // =========================================================

  Widget _buildBottomNavigationBar() {
    return SafeArea(
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
          color:
          Colors.white.withAlpha(
            245,
          ),
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
              const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment
              .spaceAround,
          children: List.generate(
            _items.length,
                (index) {
              final active =
                  _currentIndex ==
                      index;

              return InkWell(
                borderRadius:
                BorderRadius.circular(
                  24,
                ),
                onTap: () =>
                    _changeTab(index),
                child:
                AnimatedContainer(
                  duration:
                  const Duration(
                    milliseconds:
                    250,
                  ),
                  curve:
                  Curves.easeInOut,
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
                    color:
                    active
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
                        _items[index]
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
                      if (active) ...[
                        const SizedBox(
                          width: 7,
                        ),
                        Text(
                          _items[index]
                              .label,
                          style:
                          const TextStyle(
                            color:
                            Colors
                                .white,
                            fontWeight:
                            FontWeight
                                .w600,
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
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      background,
      extendBody: true,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      floatingActionButton:
      _buildFab(),
      floatingActionButtonLocation:
      FloatingActionButtonLocation
          .endFloat,
      bottomNavigationBar:
      _buildBottomNavigationBar(),
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