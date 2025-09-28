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
    // Use safe defaults
    final bool unread = notif["unread"] as bool? ?? false;
    final String title = notif["title"] ?? "No title";
    final String subtitle = notif["subtitle"] ?? "No details";
    final String? profile = notif["profile"];
    final Map<String, dynamic> event = notif["event"] ?? {};
    final DateTime? date = event["date"] is DateTime ? event["date"] : null;
    final int volunteers = event["volunteers"] ?? 0;
    final String description = event["description"] ?? "No description";
    final String details = event["details"] ?? "";
    final String status = event["status"] ?? "pending";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: profile != null ? AssetImage(profile) : null,
          child: profile == null ? const Icon(Icons.event) : null,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: unread ? Colors.black : Colors.grey[700],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            const SizedBox(height: 4),
            if (date != null)
              Text("📅 ${date.toLocal().toString().split(" ")[0]}"),
            Text("👥 Volunteers: $volunteers"),
            Text(description),
            if (details.isNotEmpty) Text(details),
            Text("Status: $status"),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) {
                // handled in parent
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
