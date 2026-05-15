import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/call_model.dart';
import '../services/call_history_service.dart';
import '../services/zego_call_service.dart';
import '../widgets/profile_avatarz.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color background = Color(0xFFF5F6FF);

  final TextEditingController _searchController =
  TextEditingController();

  String _search = '';

  // =========================================================
  // START VOICE CALL
  // =========================================================

  Future<void> _startVoiceCall(
      CallModel call,
      ) async {
    try {
      await ZegoCallService.startVoiceCall(
        targetUserID: call.otherUserId,
        targetUserName: call.otherUserName,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Voice call failed: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // START VIDEO CALL
  // =========================================================

  Future<void> _startVideoCall(
      CallModel call,
      ) async {
    try {
      await ZegoCallService.startVideoCall(
        targetUserID: call.otherUserId,
        targetUserName: call.otherUserName,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Video call failed: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // FILTER CALLS
  // =========================================================

  List<CallModel> _filterCalls(
      List<CallModel> calls,
      ) {
    final query =
    _search.trim().toLowerCase();

    if (query.isEmpty) {
      return calls;
    }

    return calls.where((call) {
      return call.otherUserName
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  // =========================================================
  // SECTION TITLE
  // =========================================================

  String _sectionTitle(
      DateTime date,
      ) {
    final local = date.toLocal();
    final now = DateTime.now();

    final today =
    DateTime(now.year, now.month, now.day);

    final yesterday = today.subtract(
      const Duration(days: 1),
    );

    final target = DateTime(
      local.year,
      local.month,
      local.day,
    );

    if (target == today) {
      return 'Today';
    }

    if (target == yesterday) {
      return 'Yesterday';
    }

    return 'Older';
  }

  // =========================================================
  // GROUP CALLS
  // =========================================================

  Map<String, List<CallModel>>
  _groupCalls(
      List<CallModel> calls,
      ) {
    final grouped =
    <String, List<CallModel>>{
      'Today': [],
      'Yesterday': [],
      'Older': [],
    };

    for (final call in calls) {
      final title =
      _sectionTitle(call.createdAt);

      grouped[title]!.add(call);
    }

    grouped.removeWhere(
          (key, value) => value.isEmpty,
    );

    return grouped;
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String _formatDate(
      DateTime date,
      ) {
    final local = date.toLocal();
    final section =
    _sectionTitle(local);

    if (section == 'Today') {
      return 'Today, ${DateFormat('h:mm a').format(local)}';
    }

    if (section == 'Yesterday') {
      return 'Yesterday, ${DateFormat('h:mm a').format(local)}';
    }

    return DateFormat(
      'MMM d, h:mm a',
    ).format(local);
  }

  // =========================================================
  // DIRECTION ICON
  // =========================================================

  IconData _directionIcon(
      CallModel call,
      ) {
    if (call.isMissed) {
      return Icons.call_missed;
    }

    if (call.isOutgoing) {
      return Icons.north_east;
    }

    return Icons.south_west;
  }

  // =========================================================
  // DIRECTION COLOR
  // =========================================================

  Color _directionColor(
      CallModel call,
      ) {
    if (call.isMissed) {
      return Colors.red;
    }

    if (call.isOutgoing) {
      return Colors.blue;
    }

    return Colors.green;
  }

  // =========================================================
  // CALL TYPE ICON
  // =========================================================

  IconData _callTypeIcon(
      CallModel call,
      ) {
    return call.isVideoCall
        ? Icons.videocam_rounded
        : Icons.call_rounded;
  }

  // =========================================================
  // FORMAT DURATION
  // =========================================================

  String _formatDuration(
      int seconds,
      ) {
    if (seconds <= 0) {
      return '';
    }

    final duration =
    Duration(seconds: seconds);

    final hours =
        duration.inHours;
    final minutes =
        duration.inMinutes % 60;
    final secs =
        duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    if (minutes > 0) {
      return '${minutes}m ${secs}s';
    }

    return '${secs}s';
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(
            Icons.call_outlined,
            size: 72,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No calls yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight:
              FontWeight.w600,
              color:
              Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your voice and video calls will appear here.',
            style: TextStyle(
              color:
              Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CALL TILE
  // =========================================================

  Widget _buildCallTile(
      CallModel call,
      ) {
    final durationText =
    _formatDuration(
      call.duration,
    );

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          26,
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withAlpha(
              10,
            ),
            blurRadius: 12,
            offset:
            const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(
          16,
        ),
        child: Row(
          children: [
            ProfileAvatar(
              name:
              call.otherUserName,
              imageUrl:
              call.otherUserAvatar,
              radius: 30,
              isOnline: false,
            ),

            const SizedBox(
              width: 16,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    call.otherUserName,
                    maxLines: 1,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 17,
                      fontWeight:
                      FontWeight
                          .bold,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Row(
                    children: [
                      Icon(
                        _directionIcon(
                          call,
                        ),
                        size: 18,
                        color:
                        _directionColor(
                          call,
                        ),
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Expanded(
                        child: Text(
                          _formatDate(
                            call
                                .createdAt,
                          ),
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style:
                          TextStyle(
                            fontSize:
                            14,
                            color: Colors
                                .grey
                                .shade600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (durationText
                      .isNotEmpty) ...[
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      'Duration: $durationText',
                      style:
                      TextStyle(
                        fontSize:
                        12,
                        color: Colors
                            .grey
                            .shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            InkWell(
              onTap: () {
                if (call.isVideoCall) {
                  _startVideoCall(
                    call,
                  );
                } else {
                  _startVoiceCall(
                    call,
                  );
                }
              },
              borderRadius:
              BorderRadius.circular(
                30,
              ),
              child: Container(
                width: 54,
                height: 54,
                decoration:
                BoxDecoration(
                  color: primary
                      .withAlpha(
                    20,
                  ),
                  shape:
                  BoxShape.circle,
                ),
                child: Icon(
                  _callTypeIcon(
                    call,
                  ),
                  color: primary,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SECTION
  // =========================================================

  Widget _buildSection(
      String title,
      List<CallModel> calls,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
          const EdgeInsets.only(
            bottom: 14,
            top: 6,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w700,
              color:
              Colors.grey.shade700,
            ),
          ),
        ),
        ...calls.map(
          _buildCallTile,
        ),
      ],
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

      floatingActionButton:
      FloatingActionButton(
        backgroundColor:
        primary,
        elevation: 8,
        onPressed: () {},
        child: const Icon(
          Icons.add_call,
          color: Colors.white,
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding:
              const EdgeInsets
                  .fromLTRB(
                22,
                18,
                22,
                0,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Calls',
                      style:
                      TextStyle(
                        fontSize:
                        36,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    ),
                  ),
                  Container(
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.white,
                      borderRadius:
                      BorderRadius
                          .circular(
                        18,
                      ),
                    ),
                    child:
                    IconButton(
                      onPressed:
                          () {},
                      icon:
                      const Icon(
                        Icons
                            .add_ic_call,
                        color:
                        primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // SEARCH
            Padding(
              padding:
              const EdgeInsets
                  .all(22),
              child: Container(
                decoration:
                BoxDecoration(
                  color:
                  Colors.white,
                  borderRadius:
                  BorderRadius
                      .circular(
                    22,
                  ),
                ),
                child: TextField(
                  controller:
                  _searchController,
                  onChanged:
                      (value) {
                    setState(() {
                      _search =
                          value
                              .trim();
                    });
                  },
                  decoration:
                  const InputDecoration(
                    hintText:
                    'Search calls...',
                    prefixIcon:
                    Icon(
                      Icons.search,
                    ),
                    border:
                    InputBorder
                        .none,
                    contentPadding:
                    EdgeInsets.symmetric(
                      vertical:
                      18,
                    ),
                  ),
                ),
              ),
            ),

            // CALL HISTORY
            Expanded(
              child:
              StreamBuilder<
                  List<
                      CallModel>>(
                stream:
                CallHistoryService
                    .getCallHistory(),
                builder: (
                    context,
                    snapshot,
                    ) {
                  if (snapshot
                      .connectionState ==
                      ConnectionState
                          .waiting) {
                    return const Center(
                      child:
                      CircularProgressIndicator(
                        color:
                        primary,
                      ),
                    );
                  }

                  final allCalls =
                      snapshot.data ??
                          [];

                  // Keep only voice and video calls
                  final callHistory =
                  allCalls
                      .where(
                        (call) =>
                    call.isVideoCall ||
                        !call.isVideoCall,
                  )
                      .toList();

                  final filteredCalls =
                  _filterCalls(
                    callHistory,
                  );

                  if (filteredCalls
                      .isEmpty) {
                    return _buildEmptyState();
                  }

                  final grouped =
                  _groupCalls(
                    filteredCalls,
                  );

                  return ListView(
                    padding:
                    const EdgeInsets
                        .fromLTRB(
                      22,
                      0,
                      22,
                      100,
                    ),
                    children:
                    grouped.entries
                        .map(
                          (
                          entry,
                          ) =>
                          _buildSection(
                            entry.key,
                            entry.value,
                          ),
                    )
                        .toList(),
                  );
                },
              ),
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
    _searchController.dispose();
    super.dispose();
  }
}