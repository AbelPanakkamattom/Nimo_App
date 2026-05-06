import 'package:flutter/material.dart';

class CallsScreen extends StatelessWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final calls = _dummyCalls;
    final grouped = _groupCalls(calls);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FF),

      /// 🔝 APP BAR
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        titleSpacing: 12,
        title: Row(
          children: [
            Image.asset(
              "assets/images/nimo_logo.png",
              height: 26,
              errorBuilder: (_, __, ___) => const SizedBox(),
            ),
            const SizedBox(width: 8),
            const Text(
              "Calls",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      /// 📞 BODY
      body: calls.isEmpty
          ? const Center(
        child: Text(
          "No call history",
          style: TextStyle(color: Colors.grey),
        ),
      )
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: grouped.entries.map((entry) {
          if (entry.value.isEmpty) return const SizedBox();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🏷 TITLE
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),

              /// 📦 ITEMS
              ...entry.value.map((call) => CallTile(data: call)),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// 🔹 DUMMY DATA (replace later with Supabase)
  static const List<CallData> _dummyCalls = [
    CallData("Larry Michael", "Today, 9:30 PM", CallType.outgoing),
    CallData("Natalie Nora", "Today, 6:10 PM", CallType.incoming),
    CallData("John Carter", "Yesterday, 8:00 PM", CallType.missed),
    CallData("Jennifer Jones", "Yesterday, 5:45 PM", CallType.incoming),
    CallData("Alex Roy", "Mar 28, 3:20 PM", CallType.outgoing),
  ];

  /// 🔥 GROUP LOGIC (cleaner)
  Map<String, List<CallData>> _groupCalls(List<CallData> calls) {
    final Map<String, List<CallData>> map = {
      "Today": [],
      "Yesterday": [],
      "Older": [],
    };

    for (final call in calls) {
      if (call.time.startsWith("Today")) {
        map["Today"]!.add(call);
      } else if (call.time.startsWith("Yesterday")) {
        map["Yesterday"]!.add(call);
      } else {
        map["Older"]!.add(call);
      }
    }

    return map;
  }
}

/// 📦 MODEL
class CallData {
  final String name;
  final String time;
  final CallType type;

  const CallData(this.name, this.time, this.type);
}

enum CallType { outgoing, incoming, missed }

/// 📞 TILE
class CallTile extends StatelessWidget {
  final CallData data;

  const CallTile({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getCallStyle(data.type);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            /// 👤 AVATAR
            const CircleAvatar(
              radius: 26,
              backgroundColor: Color(0xFF6C5CE7),
              child: Icon(Icons.person, color: Colors.white),
            ),

            const SizedBox(width: 14),

            /// 📛 INFO
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 5),
                      Text(
                        data.time,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            /// 📞 CALL BUTTON
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Calling ${data.name}...")),
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.call,
                  color: Color(0xFF6C5CE7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 STYLE HELPER
  (IconData, Color) _getCallStyle(CallType type) {
    switch (type) {
      case CallType.outgoing:
        return (Icons.call_made, Colors.green);
      case CallType.incoming:
        return (Icons.call_received, Colors.blue);
      case CallType.missed:
        return (Icons.call_missed, Colors.red);
    }
  }
}