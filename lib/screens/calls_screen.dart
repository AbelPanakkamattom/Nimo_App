import 'package:flutter/material.dart';

import '../screens/contacts_screen.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color background = Color(0xFFF5F6FF);

  final TextEditingController _searchController = TextEditingController();

  late List<CallModel> _allCalls;
  late List<CallModel> _filteredCalls;

  @override
  void initState() {
    super.initState();
    _allCalls = List<CallModel>.from(_dummyCalls);
    _filteredCalls = List<CallModel>.from(_dummyCalls);
    _searchController.addListener(_filterCalls);
  }

  // =========================================================
  // FILTER CALLS
  // =========================================================

  void _filterCalls() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredCalls = List<CallModel>.from(_allCalls);
      } else {
        _filteredCalls = _allCalls.where((call) {
          return call.name.toLowerCase().contains(query) ||
              call.time.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // =========================================================
  // GROUP CALLS
  // =========================================================

  Map<String, List<CallModel>> _groupCalls() {
    final Map<String, List<CallModel>> grouped = {
      'Today': [],
      'Yesterday': [],
      'Older': [],
    };

    for (final call in _filteredCalls) {
      if (call.time.startsWith('Today')) {
        grouped['Today']!.add(call);
      } else if (call.time.startsWith('Yesterday')) {
        grouped['Yesterday']!.add(call);
      } else {
        grouped['Older']!.add(call);
      }
    }

    return grouped;
  }

  // =========================================================
  // START CALL
  // =========================================================

  void _callUser(CallModel call) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          call.video
              ? 'Starting video call with ${call.name}...'
              : 'Calling ${call.name}...',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // NEW CALL
  // =========================================================

  void _openContacts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ContactsScreen(),
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_outlined,
                size: 48,
                color: primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Call History',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your recent voice and video calls will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openContacts,
              icon: const Icon(Icons.add_call),
              label: const Text('Start New Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Calls',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E1E),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _openContacts,
              tooltip: 'New Call',
              icon: const Icon(
                Icons.add_ic_call,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SEARCH BAR
  // =========================================================

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search calls...',
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey.shade600,
            ),
            border: InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // CALL LIST
  // =========================================================

  Widget _buildCallList() {
    if (_filteredCalls.isEmpty) {
      return _buildEmptyState();
    }

    final groupedCalls = _groupCalls();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: groupedCalls.entries.map((entry) {
        if (entry.value.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
              const EdgeInsets.only(top: 8, bottom: 12),
              child: Text(
                entry.key,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ...entry.value.map(
                  (call) => _CallTile(
                data: call,
                onCall: () => _callUser(call),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _buildCallList(),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _searchController.removeListener(_filterCalls);
    _searchController.dispose();
    super.dispose();
  }
}

// =========================================================
// CALL MODEL
// =========================================================

class CallModel {
  final String name;
  final String time;
  final CallType type;
  final bool video;

  const CallModel({
    required this.name,
    required this.time,
    required this.type,
    this.video = false,
  });
}

enum CallType {
  incoming,
  outgoing,
  missed,
}

// =========================================================
// CALL TILE
// =========================================================

class _CallTile extends StatelessWidget {
  final CallModel data;
  final VoidCallback onCall;

  const _CallTile({
    required this.data,
    required this.onCall,
  });

  (IconData, Color) _getStyle(CallType type) {
    switch (type) {
      case CallType.incoming:
        return (Icons.call_received, Colors.green);
      case CallType.outgoing:
        return (Icons.call_made, Colors.blue);
      case CallType.missed:
        return (Icons.call_missed, Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getStyle(data.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Color(0xFF7B61FF),
                  Color(0xFF6C5CE7),
                ],
              ),
            ),
            child: Center(
              child: Text(
                data.name.isNotEmpty
                    ? data.name[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.time,
                        overflow:
                        TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onCall,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primary.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                data.video
                    ? Icons.videocam
                    : Icons.call,
                color: primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const Color primary = Color(0xFF6C5CE7);
}

// =========================================================
// DUMMY CALL DATA
// =========================================================

const List<CallModel> _dummyCalls = [
  CallModel(
    name: 'Abel Sabu',
    time: 'Today, 9:30 PM',
    type: CallType.outgoing,
  ),
  CallModel(
    name: 'Sahil',
    time: 'Today, 7:15 PM',
    type: CallType.incoming,
    video: true,
  ),
  CallModel(
    name: 'Jennifer',
    time: 'Yesterday, 8:20 PM',
    type: CallType.missed,
  ),
  CallModel(
    name: 'Alex Roy',
    time: 'Yesterday, 5:30 PM',
    type: CallType.incoming,
  ),
  CallModel(
    name: 'Natalie Nora',
    time: 'Mar 28, 3:40 PM',
    type: CallType.outgoing,
    video: true,
  ),
];