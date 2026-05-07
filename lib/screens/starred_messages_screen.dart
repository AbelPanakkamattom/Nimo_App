import 'package:flutter/material.dart';

class StarredMessagesScreen extends StatelessWidget {
  const StarredMessagesScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F6FF),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Starred Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Center(
        child: Padding(
          padding:
          const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.amber
                      .withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_border,
                  size: 50,
                  color: Colors.amber,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'No Starred Messages',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Messages you star will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                  Colors.grey.shade700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}