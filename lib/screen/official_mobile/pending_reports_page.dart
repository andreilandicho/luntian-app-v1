import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/official/offpending_post_card.dart';

class PendingReportsPage extends StatelessWidget {
  const PendingReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(221, 221, 221, 1),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PendingPostCard(
            reporterName: 'Juan Dela Cruz',
            profileImage: 'assets/profilepicture.png',
            reportTime: '7:30 PM',
            reportDate: 'Aug 15, 2025',
            priority: 'Medium',
            isHazardous: false,
            badge: 'Top Reporter',
            postImage: 'assets/garbage.png',
            description: 'There’s a water leak near the community park.',
            location: 'Community Park',
          ),
          PendingPostCard(
            reporterName: 'Maria Clara',
            profileImage: 'assets/profilepicture.png',
            reportTime: '8:00 AM',
            reportDate: 'Aug 16, 2025',
            priority: 'High',
            isHazardous: true,
            badge: 'Top Reporter',
            postImage: 'assets/garbage.png',
            description: 'Garbage pile-up near the main road.',
            location: 'Main Road',
          ),
        ],
      ),
    );
  }
}
