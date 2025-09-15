import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportNotificationWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback markAsRead;
  final VoidCallback onTap; // ✅ NEW

  const ReportNotificationWidget({
    super.key,
    required this.notification,
    required this.markAsRead,
    required this.onTap, // ✅ NEW
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ListTile(
        onTap: () {
          markAsRead();
          onTap(); // ✅ pass back to parent
        },
        leading: CircleAvatar(
          backgroundImage: AssetImage(
              notification['post']?['userProfile'] ?? 'assets/logo only luntian.png'),
        ),
        title: Text(
          notification['message'],
          style: TextStyle(
            fontWeight: notification['read'] ? FontWeight.normal : FontWeight.bold,
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy • h:mm a').format(notification['timestamp']),
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
        ),
        trailing: notification['read']
            ? null
            : const Icon(Icons.circle, size: 10, color: Colors.blue),
      ),
    );
  }
}
