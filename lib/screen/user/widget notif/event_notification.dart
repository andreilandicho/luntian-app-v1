import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventNotificationWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback markAsRead;
  final VoidCallback onTap;

  const EventNotificationWidget({
    super.key,
    required this.notification,
    required this.markAsRead,
    required this.onTap,
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
          onTap(); // trigger parent navigation
        },
        leading: const CircleAvatar(
          backgroundImage: AssetImage("assets/logo only luntian.png"),
        ),
       title: Text(
        notification['message'],
        style: TextStyle(
          fontWeight: (notification['read'] ?? false)
              ? FontWeight.normal
              : FontWeight.bold,
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
