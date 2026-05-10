import 'package:flutter/material.dart';

class EmailScreen extends StatelessWidget {
  const EmailScreen({super.key});

  static const Color primary = Color(0xFF6C5CE7);
  static const Color background = Color(0xFFF5F6FF);

  void _showNotifyMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'You’ll be notified when NIMO Mail launches 🚀',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: primary.withAlpha(26),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color:
                    Colors.grey.shade700,
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(
      BuildContext context,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6C5CE7),
            Color(0xFF8E7BFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
        BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primary.withAlpha(64),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding:
            const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white
                  .withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.email_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'NIMO Mail',
            style: TextStyle(
              color: Colors.white,
              fontWeight:
              FontWeight.bold,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Smart email experience powered by AI.\nComing soon to NIMO.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () =>
                  _showNotifyMessage(
                    context,
                  ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.white,
                foregroundColor:
                primary,
                elevation: 0,
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                    16,
                  ),
                ),
              ),
              child: const Text(
                'Notify Me',
                style: TextStyle(
                  fontWeight:
                  FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Email module is under active development.',
              style: TextStyle(
                fontWeight:
                FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor:
        Colors.transparent,
        surfaceTintColor:
        Colors.transparent,
        foregroundColor:
        Colors.black,
        title: const Text(
          'Email',
          style: TextStyle(
            fontWeight:
            FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            40,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildHeroCard(context),

              const SizedBox(height: 32),

              const Text(
                'Upcoming Features',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              _buildFeatureCard(
                icon: Icons.inbox_rounded,
                title: 'Unified Inbox',
                subtitle:
                'Manage all your emails from one beautiful place.',
              ),

              _buildFeatureCard(
                icon:
                Icons.smart_toy_rounded,
                title: 'AI Smart Replies',
                subtitle:
                'Generate intelligent replies instantly.',
              ),

              _buildFeatureCard(
                icon: Icons.send_rounded,
                title:
                'Fast Email Sending',
                subtitle:
                'Send professional emails securely.',
              ),

              _buildFeatureCard(
                icon:
                Icons.security_rounded,
                title:
                'Private & Secure',
                subtitle:
                'Your emails remain encrypted and protected.',
              ),

              const SizedBox(height: 24),

              _buildStatusCard(),
            ],
          ),
        ),
      ),
    );
  }
}