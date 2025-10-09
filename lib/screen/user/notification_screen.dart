import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int? userId;
  List notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('user_data');

    if (userDataString != null) {
      final userMap = jsonDecode(userDataString);
      final storedId = userMap['id'];
      debugPrint("📦 Loaded userId from prefs: $storedId");

      if (!mounted) return;
      setState(() {
        userId = storedId;
      });

      await _fetchNotifications(storedId);
    } else {
      debugPrint("⚠️ No user data in prefs. Cannot fetch notifications.");
      if (!mounted) return;
      setState(() {
        userId = null;
        notifications = [];
        isLoading = false;
      });
    }
  }

  Future<void> _fetchNotifications(int id) async {
    setState(() => isLoading = true);
    //request url
    try {
      final response =
          await http.get(Uri.parse("http://luntian-app-v1-production.up.railway.app/notifications/$id"));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          notifications = data;
          isLoading = false;
        });
      } else {
        debugPrint("❌ Failed to fetch notifications: ${response.body}");
        if (!mounted) return;
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ Exception fetching notifications: $e");
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'New Report Submission':
        return Icons.note_add_rounded;
      case 'Report Due Reminder':
        return Icons.access_time_rounded;
      case 'Report Assignment':
        return Icons.assignment_ind_rounded;
      case 'Report Approved':
        return Icons.check_circle_rounded;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'New Report Submission':
        return Colors.blueAccent;
      case 'Report Due Reminder':
        return Colors.orangeAccent;
      case 'Report Assignment':
        return Colors.purpleAccent;
      case 'Report Approved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String timeAgo(String dateString) {
    final date = DateTime.tryParse(dateString)?.toLocal();
    if (date == null) return "";

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return "${difference.inSeconds}s ago";
    if (difference.inMinutes < 60) return "${difference.inMinutes}m ago";
    if (difference.inHours < 24) return "${difference.inHours}h ago";
    if (difference.inDays < 7) return "${difference.inDays}d ago";
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(
                  child: Text(
                    "No notifications yet",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount:
                      notifications.length > 20 ? 20 : notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final title = n['title'] ?? 'General';

                    // Assign icon and color based on title
                    IconData icon;
                    Color color;
                    switch (title) {
                      case 'New Report Submission':
                        icon = Icons.note_add_rounded;
                        color = Colors.blueAccent;
                        break;
                      case 'Report Due Reminder':
                        icon = Icons.access_time_rounded;
                        color = Colors.orangeAccent;
                        break;
                      case 'Report Assignment':
                        icon = Icons.assignment_ind_rounded;
                        color = Colors.purpleAccent;
                        break;
                      case 'Report Approved':
                        icon = Icons.check_circle_rounded;
                        color = Colors.green;
                        break;
                      default:
                        icon = Icons.notifications;
                        color = Colors.grey;
                    }

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: color.withOpacity(0.2),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        subtitle: Text(
                          n['content'] ?? "No content",
                          style: const TextStyle(
                              fontSize: 14, color: Colors.black87),
                        ),
                        trailing: Text(
                          n['created_at'] != null
                              ? timeAgo(n['created_at'])
                              : "",
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
