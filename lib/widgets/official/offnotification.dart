import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A reusable notification card widget
class NotificationCard extends StatelessWidget {
  final String type; // "assigned", "rejected", "accepted"
  final String message;
  final DateTime timestamp;
  final bool isRead; // ✅ new field
  final VoidCallback? onTap;

  const NotificationCard({
    super.key,
    required this.type,
    required this.message,
    required this.timestamp,
    required this.isRead, // ✅ required
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    // Customize look depending on notification type
    switch (type) {
      case "assigned":
        icon = Icons.assignment;
        color = Colors.blue;
        break;
      case "rejected":
        icon = Icons.cancel;
        color = Colors.red;
        break;
      case "accepted":
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Card(
      color: isRead ? Colors.white : Colors.blue.shade50, // ✅ highlight unread
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          message,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold, // ✅ bold if unread
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy • h:mm a').format(timestamp),
          style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
        ),
        trailing: isRead
            ? null
            : const Icon(Icons.fiber_manual_record,
                size: 12, color: Colors.red), // ✅ red dot for unread
      ),
    );
  }
}
