import 'package:flutter/material.dart';

class EventNotificationWidget extends StatelessWidget {
  final Map<String, dynamic> notif;
  final bool isSelected;
  final VoidCallback onDelete;

  const EventNotificationWidget({
    super.key,
    required this.notif,
    required this.isSelected,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnread = notif["unread"] as bool;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Colors.blue
              : isUnread
                  ? Colors.blue.shade400
                  : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      elevation: isUnread ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: AssetImage(notif["profile"]),
          radius: 22,
        ),
        title: Row(
          children: [
            const Icon(Icons.event, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                notif["title"],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          notif["subtitle"],
          style: TextStyle(color: Colors.grey[700]),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
