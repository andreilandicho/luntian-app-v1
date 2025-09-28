import 'package:flutter/material.dart';

class ReportNotificationWidget extends StatelessWidget {
  final Map<String, dynamic> notif;
  final bool isSelected;
  final VoidCallback onDelete;

  const ReportNotificationWidget({
    super.key,
    required this.notif,
    required this.isSelected,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUnread = notif["unread"] as bool? ?? false;

    final String title = notif["title"] ?? "No title";
    final String subtitle = notif["subtitle"] ?? "No details";
    final String? profile = notif["profile"];

    // ✅ Detect deadline notifications
    final bool isDeadline =
        title.toLowerCase().contains("deadline") ||
        subtitle.toLowerCase().contains("deadline");

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Colors.blue
              : isDeadline
                  ? Colors.redAccent
                  : isUnread
                      ? Colors.blue.shade400
                      : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      elevation: isUnread ? 4 : 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              backgroundImage:
                  profile != null ? AssetImage(profile) : null,
              radius: 22,
              child: profile == null
                  ? const Icon(Icons.report, color: Colors.white)
                  : null,
            ),
            if (isDeadline)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Icon(Icons.alarm,
                      size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Icon(
              isDeadline ? Icons.alarm : Icons.report,
              size: 16,
              color: isDeadline ? Colors.redAccent : Colors.redAccent,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      isUnread ? FontWeight.bold : FontWeight.normal,
                  color: isDeadline ? Colors.redAccent : null,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color:
                isDeadline ? Colors.redAccent.shade200 : Colors.grey[700],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
