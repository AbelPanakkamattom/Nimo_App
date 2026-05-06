import 'package:flutter/material.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _controller = TextEditingController();

  void _handleSend() {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    /// 🔥 FUTURE: CALL AI API HERE
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You asked: $text")),
    );

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
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
              "NIMO AI",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  children: [
                    _buildHeroCard(),
                    const SizedBox(height: 25),
                    _buildFeatures(),
                  ],
                ),
              ),
            ),

            /// 💬 INPUT BAR
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  /// 🔥 HERO CARD
  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF8E7BFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.smart_toy, size: 65, color: Colors.white),
          const SizedBox(height: 20),

          const Text(
            "AI Assistant",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Your smart companion for chatting, writing and productivity.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("AI coming soon 🚀")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6C5CE7),
            ),
            child: const Text("Try AI"),
          ),
        ],
      ),
    );
  }

  /// 🧠 FEATURES
  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "What AI can do",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        _FeatureItem(Icons.chat, "Smart chat replies"),
        _FeatureItem(Icons.edit, "Rewrite & improve messages"),
        _FeatureItem(Icons.translate, "Translate instantly"),
        _FeatureItem(Icons.lightbulb, "Generate ideas"),
        _FeatureItem(Icons.summarize, "Summarize conversations"),
      ],
    );
  }

  /// 💬 INPUT BAR (IMPORTANT FOR FUTURE AI)
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Ask AI something...",
                filled: true,
                fillColor: const Color(0xFFF1F2F6),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: _handleSend,
            icon: const Icon(Icons.send, color: Color(0xFF6C5CE7)),
          ),
        ],
      ),
    );
  }
}

/// 🔹 FEATURE TILE (REUSABLE)
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C5CE7)),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}