import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/official/offcompleted_post_card.dart';

class CompletedReportsPage extends StatelessWidget {
  const CompletedReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(221, 221, 221, 1),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CompletedPostCard(
            reporterName: 'Pedro Penduko',
            profileImage: 'assets/profilepicture.png',
            reportTime: '9:00 AM',
            reportDate: 'Aug 10, 2025',
            priority: 'Low',
            isHazardous: false,
            badge: null,
            postImage: 'assets/garbage.png',
            description: 'Fallen branch has been cleared successfully.',
            location: 'Barangay Hall',
          ),
        ],
      ),
    );
  }
}
