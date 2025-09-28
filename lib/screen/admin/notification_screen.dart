import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key, this.onUnreadChanged});

  final ValueChanged<int>? onUnreadChanged;

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");
    if (userId == null) return [];

    final response = await _supabase
        .from("email")
        .select("id, title, content, created_at, status, context")
        .eq("user_id", userId)
        .order("created_at", ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  String _timeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    if (diff.inDays == 1) return "Yesterday";
    return DateFormat.yMMMd().format(time);
  }

  Icon _getNotificationIcon(Map<String, dynamic> notif) {
    // Customize icon based on context or status
    if (notif["status"] == null || !(notif["status"] as List).contains("read")) {
      return const Icon(Icons.mark_email_unread, color: Colors.blue, size: 24);
    }

    switch (notif["context"] ?? "") {
      case "report status change":
        return const Icon(Icons.assignment_turned_in, color: Colors.green, size: 24);
      case "system":
        return const Icon(Icons.system_update, color: Colors.orange, size: 24);
      default:
        return const Icon(Icons.notifications, color: Colors.grey, size: 24);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Notifications"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final notifications = snapshot.data ?? [];

          // Count unread notifications
          final unreadCount = notifications
              .where((n) =>
                  (n["status"] == null || !(n["status"] as List).contains("read")))
              .length;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onUnreadChanged?.call(unreadCount);
          });

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                "No notifications yet",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final createdAt =
                  DateTime.tryParse(notif["created_at"]) ?? DateTime.now();
              final isUnread = notif["status"] == null ||
                  !(notif["status"] as List).contains("read");

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isUnread ? Colors.blue.shade300 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                elevation: isUnread ? 3 : 1,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: _getNotificationIcon(notif),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif["title"] ?? "No Title",
                          style: TextStyle(
                            fontWeight:
                                isUnread ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(createdAt),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      notif["content"] ?? "",
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                  trailing: isUnread
                      ? const Icon(Icons.circle, color: Colors.blue, size: 10)
                      : null,
                  onTap: () async {
                    // Mark as read when tapped
                    await _supabase
                        .from("email")
                        .update({"status": ["read"]})
                        .eq("id", notif["id"]);

                    setState(() {}); // Refresh list
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
