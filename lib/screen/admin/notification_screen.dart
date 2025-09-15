import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import 'widget notif/report_notif.dart';
import 'widget notif/event_notif.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key, this.onUnreadChanged});

  final ValueChanged<int>? onUnreadChanged;

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final List<Map<String, dynamic>> _notifications = [
    {
      "id": 1,
      "type": "report",
      "title": "New Cleanliness Report",
      "subtitle": "Juan Dela Cruz reported a new case",
      "profile": "assets/profilepicture.png",
      "time": DateTime.now().subtract(const Duration(minutes: 20)),
      "unread": true,
      "report": {
        "userName": "Juan Dela Cruz",
        "location": "Barangay 1",
        "priority": "High",
        "hazardous": true,
        "images": [
          "assets/garbage.png",
          "assets/garbage.png",
          "assets/garbage.png"
        ],
        "description": "Overflowing garbage spotted in Barangay 1.",
        "createdAt": DateTime.now().subtract(const Duration(minutes: 25)),
      }
    },
    {
      "id": 2,
      "type": "event",
      "title": "New Event Proposal",
      "subtitle": "Juan Dela Cruz created an event proposal",
      "profile": "assets/profilepicture.png",
      "time": DateTime.now().subtract(const Duration(hours: 3)),
      "unread": true,
      "event": {
        "date": DateTime.now().add(const Duration(days: 2)),
        "volunteers": 15,
        "description": "Community clean-up drive in the riverbanks.",
        "details": "📍 Location: Riverbanks\n👥 Needed: Youth volunteers",
        "status": "pending",
        "comment": null,
      }
    },
    {
      "id": 3,
      "type": "report",
      "title": "Report Deadline Reminder",
      "subtitle": "The report deadline is approaching",
      "profile": "assets/profilepicture.png",
      "time": DateTime.now().subtract(const Duration(hours: 1)),
      "unread": true,
      "report": {
        "userName": "System",
        "location": "All Barangays",
        "priority": "Medium",
        "hazardous": false,
        "images": [],
        "description": "Please submit your pending reports before the deadline.",
        "createdAt": DateTime.now().subtract(const Duration(hours: 2)),
      }
    },
  ];

  String _filter = "All";
  final Set<int> _selected = {}; // bulk actions

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _timeGroup(DateTime time) {
    final now = DateTime.now();
    if (_isSameDate(time, now)) {
      return "Today";
    } else if (_isSameDate(time, now.subtract(const Duration(days: 1)))) {
      return "Yesterday";
    } else {
      return "Earlier";
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var notif in _notifications) {
        notif["unread"] = false;
      }
    });
  }

  void _deleteSelected() {
    setState(() {
      _notifications.removeWhere((n) => _selected.contains(n["id"]));
      _selected.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Selected notifications deleted")),
    );
  }

  void _delete(int id) {
    setState(() {
      _notifications.removeWhere((n) => n["id"] == id);
      _selected.remove(id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notification deleted")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount =
        _notifications.where((n) => n["unread"] == true).length;

    final deadlineCount = _notifications
        .where((n) =>
            n["type"] == "report" &&
            (n["title"] as String).toLowerCase().contains("deadline"))
        .length;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onUnreadChanged?.call(unreadCount);
    });

    final filtered = _notifications.where((n) {
      if (_filter == "Unread") return n["unread"] == true;
      if (_filter == "Reports") return n["type"] == "report";
      if (_filter == "Events") return n["type"] == "event";
      return true;
    }).toList();

    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var n in filtered) {
      final group = _timeGroup(n["time"]);
      grouped.putIfAbsent(group, () => []).add(n);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Notifications",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          if (_selected.isNotEmpty)
            IconButton(
              tooltip: "Delete selected",
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: _deleteSelected,
            ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filter,
              items: const [
                DropdownMenuItem(value: "All", child: Text("All")),
                DropdownMenuItem(value: "Unread", child: Text("Unread only")),
                DropdownMenuItem(value: "Reports", child: Text("Reports only")),
                DropdownMenuItem(value: "Events", child: Text("Events only")),
              ],
              onChanged: (val) => setState(() => _filter = val!),
              icon: const Icon(Icons.filter_list, color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: _markAllAsRead,
            child:
                const Text("Mark all as read", style: TextStyle(color: Colors.blue)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.9),
                  Colors.blue.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("Unread",
                        style: TextStyle(
                            color: Colors.black87, fontWeight: FontWeight.w600)),
                    Text("$unreadCount",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Column(
                  children: [
                    const Text("Deadlines",
                        style: TextStyle(
                            color: Colors.black87, fontWeight: FontWeight.w600)),
                    Text("$deadlineCount",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Column(
                  children: [
                    const Text("Reports",
                        style: TextStyle(
                            color: Colors.black87, fontWeight: FontWeight.w600)),
                    Text(
                        "${filtered.where((n) => n["type"] == "report").length}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Column(
                  children: [
                    const Text("Events",
                        style: TextStyle(
                            color: Colors.black87, fontWeight: FontWeight.w600)),
                    Text(
                        "${filtered.where((n) => n["type"] == "event").length}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: grouped.isEmpty
                ? const Center(
                    child: Text(
                      "No notifications yet",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: grouped.entries.expand((entry) {
                      return [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          child: Text(entry.key,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87)),
                        ),
                        ...entry.value.map((notif) {
                          Widget child;
                          if (notif["type"] == "report") {
                            child = ReportNotificationWidget(
                              notif: notif,
                              isSelected: _selected.contains(notif["id"]),
                              onDelete: () => _delete(notif["id"]),
                            );
                          } else {
                            child = EventNotificationWidget(
                              notif: notif,
                              isSelected: _selected.contains(notif["id"]),
                              onDelete: () => _delete(notif["id"]),
                            );
                          }

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                notif["unread"] = !(notif["unread"] as bool);
                              });
                            },
                            child: child,
                          );
                        })
                      ];
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
