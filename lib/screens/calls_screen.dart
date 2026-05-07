import 'package:flutter/material.dart';

class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() =>
      _CallsScreenState();
}

class _CallsScreenState
    extends State<CallsScreen> {
  final TextEditingController
  searchController =
  TextEditingController();

  List<CallModel> calls =
      _dummyCalls;

  List<CallModel>
  filteredCalls =
      _dummyCalls;

  @override
  void initState() {
    super.initState();

    searchController.addListener(
      _filterCalls,
    );
  }

  /// =========================
  /// 🔍 SEARCH
  /// =========================

  void _filterCalls() {
    final query =
    searchController.text
        .trim()
        .toLowerCase();

    if (query.isEmpty) {
      setState(() {
        filteredCalls = calls;
      });

      return;
    }

    final result = calls.where((c) {
      return c.name
          .toLowerCase()
          .contains(query) ||
          c.time
              .toLowerCase()
              .contains(query);
    }).toList();

    setState(() {
      filteredCalls = result;
    });
  }

  /// =========================
  /// 📅 GROUP CALLS
  /// =========================

  Map<String, List<CallModel>>
  groupedCalls() {
    final Map<String,
        List<CallModel>>
    map = {
      "Today": [],
      "Yesterday": [],
      "Older": [],
    };

    for (final call
    in filteredCalls) {
      if (call.time.startsWith(
          "Today")) {
        map["Today"]!
            .add(call);
      } else if (call.time
          .startsWith(
          "Yesterday")) {
        map["Yesterday"]!
            .add(call);
      } else {
        map["Older"]!
            .add(call);
      }
    }

    return map;
  }

  /// =========================
  /// 📞 CALL ACTION
  /// =========================

  void callUser(String name) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text("Calling $name..."),
        behavior:
        SnackBarBehavior
            .floating,
      ),
    );
  }

  /// =========================
  /// UI
  /// =========================

  @override
  Widget build(BuildContext context) {
    final grouped =
    groupedCalls();

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6FF),

      body: SafeArea(
        child: Column(
          children: [
            /// =========================
            /// 🔝 HEADER
            /// =========================

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                0,
              ),

              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Calls",
                      style: TextStyle(
                        fontSize: 28,
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
                      BorderRadius.circular(
                        14,
                      ),
                    ),

                    child: IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(
                            context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Create call link soon 🚀",
                            ),
                          ),
                        );
                      },

                      icon: const Icon(
                        Icons.add_ic_call,
                        color: Color(
                          0xFF6C5CE7,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// =========================
            /// 🔍 SEARCH
            /// =========================

            Padding(
              padding:
              const EdgeInsets.all(
                20,
              ),

              child: Container(
                decoration:
                BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    18,
                  ),
                ),

                child: TextField(
                  controller:
                  searchController,

                  decoration:
                  const InputDecoration(
                    hintText:
                    "Search calls...",
                    prefixIcon:
                    Icon(
                      Icons.search,
                    ),
                    border:
                    InputBorder
                        .none,
                  ),
                ),
              ),
            ),

            /// =========================
            /// 📞 CALL LIST
            /// =========================

            Expanded(
              child:
              filteredCalls.isEmpty
                  ? _buildEmpty()
                  : ListView(
                padding:
                const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom:
                  110,
                ),

                children: grouped
                    .entries
                    .map(
                      (
                      entry,
                      ) {
                    if (entry
                        .value
                        .isEmpty) {
                      return const SizedBox();
                    }

                    return Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                      children: [
                        Padding(
                          padding:
                          const EdgeInsets.only(
                            bottom:
                            12,
                            top: 8,
                          ),

                          child:
                          Text(
                            entry
                                .key,
                            style:
                            TextStyle(
                              fontSize:
                              14,
                              fontWeight:
                              FontWeight.w600,
                              color: Colors
                                  .grey
                                  .shade600,
                            ),
                          ),
                        ),

                        ...entry
                            .value
                            .map(
                              (
                              call,
                              ) =>
                              _CallTile(
                                data:
                                call,
                                onCall:
                                    () {
                                  callUser(
                                    call
                                        .name,
                                  );
                                },
                              ),
                        ),
                      ],
                    );
                  },
                ).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// =========================
  /// 📭 EMPTY UI
  /// =========================

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment
            .center,
        children: [
          Icon(
            Icons.call,
            size: 70,
            color:
            Colors.grey.shade400,
          ),

          const SizedBox(
            height: 16,
          ),

          Text(
            "No call history",
            style: TextStyle(
              color:
              Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();

    super.dispose();
  }
}

/// =====================================
/// 📦 CALL MODEL
/// =====================================

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

/// =====================================
/// 📞 CALL TILE
/// =====================================

class _CallTile
    extends StatelessWidget {
  final CallModel data;
  final VoidCallback onCall;

  const _CallTile({
    required this.data,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final (
    icon,
    color,
    ) = _style(data.type);

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),

      padding:
      const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(
          22,
        ),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 10,
          ),
        ],
      ),

      child: Row(
        children: [
          /// 👤 AVATAR
          Container(
            width: 56,
            height: 56,

            decoration:
            const BoxDecoration(
              shape:
              BoxShape.circle,

              gradient:
              LinearGradient(
                colors: [
                  Color(0xFF7B61FF),
                  Color(0xFF6C5CE7),
                ],
              ),
            ),

            child: Center(
              child: Text(
                data.name[0]
                    .toUpperCase(),

                style:
                const TextStyle(
                  color:
                  Colors.white,
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 14,
          ),

          /// 📛 INFO
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,

              children: [
                Text(
                  data.name,

                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight
                        .w600,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: color,
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Expanded(
                      child: Text(
                        data.time,

                        overflow:
                        TextOverflow
                            .ellipsis,

                        style:
                        TextStyle(
                          color: Colors
                              .grey
                              .shade600,
                          fontSize:
                          13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// 📞 ACTION
          InkWell(
            borderRadius:
            BorderRadius.circular(
              20,
            ),

            onTap: onCall,

            child: Container(
              padding:
              const EdgeInsets.all(
                10,
              ),

              decoration:
              BoxDecoration(
                color: const Color(
                  0xFF6C5CE7,
                ).withValues(
                  alpha: 0.1,
                ),

                shape:
                BoxShape.circle,
              ),

              child: Icon(
                data.video
                    ? Icons.videocam
                    : Icons.call,

                color:
                const Color(
                  0xFF6C5CE7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// 🎨 STYLE
  /// =========================

  (
  IconData,
  Color,
  ) _style(CallType type) {
    switch (type) {
      case CallType.incoming:
        return (
        Icons.call_received,
        Colors.green,
        );

      case CallType.outgoing:
        return (
        Icons.call_made,
        Colors.blue,
        );

      case CallType.missed:
        return (
        Icons.call_missed,
        Colors.red,
        );
    }
  }
}

/// =====================================
/// 🔥 DEMO DATA
/// =====================================

const List<CallModel> _dummyCalls = [
  CallModel(
    name: "Abel Sabu",
    time: "Today, 9:30 PM",
    type: CallType.outgoing,
  ),

  CallModel(
    name: "Sahil",
    time: "Today, 7:15 PM",
    type: CallType.incoming,
    video: true,
  ),

  CallModel(
    name: "Jennifer",
    time: "Yesterday, 8:20 PM",
    type: CallType.missed,
  ),

  CallModel(
    name: "Alex Roy",
    time: "Yesterday, 5:30 PM",
    type: CallType.incoming,
  ),

  CallModel(
    name: "Natalie Nora",
    time: "Mar 28, 3:40 PM",
    type: CallType.outgoing,
    video: true,
  ),
];