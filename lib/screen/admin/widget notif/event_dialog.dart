import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventNotificationDialog {
  static void open(
    BuildContext context,
    Map<String, dynamic> notif,
    Function(Map<String, dynamic>, String) showCommentDialog,
  ) {
    final event = notif["event"] ?? {};

    final String title = notif["title"] ?? "Event";
    final String? description = event["description"];
    final String? details = event["details"];
    final String? comment = event["comment"];
    final String status = event["status"] ?? "pending";
    final DateTime? date = event["date"] is DateTime ? event["date"] : null;
    final int? volunteers = event["volunteers"];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 360, // fixed width to prevent shrinking
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title + Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2, horizontal: 8),
                      decoration: BoxDecoration(
                        color: status == "accepted"
                            ? Colors.green[100]
                            : status == "rejected"
                                ? Colors.red[100]
                                : Colors.orange[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          height: 1.1,
                          color: status == "accepted"
                              ? Colors.green[800]
                              : status == "rejected"
                                  ? Colors.red[800]
                                  : Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                if (date != null)
                  Text(
                    "📅 ${DateFormat.yMMMd().add_jm().format(date)}",
                    style: const TextStyle(fontSize: 12.5, height: 1.2),
                  ),
                if (volunteers != null)
                  Text(
                    "👥 Volunteers: $volunteers",
                    style: const TextStyle(fontSize: 12.5, height: 1.2),
                  ),

                if (description != null) ...[
                  const SizedBox(height: 6),
                  Text(description,
                      style: const TextStyle(fontSize: 13, height: 1.2)),
                ],
                if (details != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      height: 1.2,
                    ),
                  ),
                ],
                if (comment != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "💬 $comment",
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                  ),
                ],
                const SizedBox(height: 10),

                // Buttons
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        event["status"] = "accepted";
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text("Accept"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        textStyle:
                            const TextStyle(fontSize: 13, height: 1.1),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        showCommentDialog(event, "rejected");
                      },
                      icon: const Icon(Icons.close,
                          size: 16, color: Colors.red),
                      label: const Text(
                        "Reject",
                        style: TextStyle(fontSize: 13, color: Colors.red),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showCommentDialog(event, "revise");
                      },
                      icon: const Icon(Icons.edit,
                          size: 16, color: Colors.orange),
                      label: const Text(
                        "Revise",
                        style:
                            TextStyle(fontSize: 13, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
