import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

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
      // Add a default comment field so we can use it if status is revised/rejected
      "comment": null,
    }
  },
  {
    "id": 3,
    "type": "report",
    "title": "New Cleanliness Report",
    "subtitle": "Maria Santos reported a new case",
    "profile": "assets/profilepicture.png",
    "time": DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    "unread": false,
    "report": {
      "userName": "Maria Santos",
      "location": "Barangay 2",
      "priority": "Medium",
      "hazardous": false,
      "images": [
        "assets/garbage.png",
        "assets/garbage.png",
        "assets/garbage.png"
      ],
      "description": "Clogged drainage observed near Barangay Hall.",
      "createdAt": DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    }
  },
  {
    "id": 4,
    "type": "report",
    "title": "New Cleanliness Report",
    "subtitle": "Pedro Ramirez reported a new case",
    "profile": "assets/profilepicture.png",
    "time": DateTime.now().subtract(const Duration(hours: 5)),
    "unread": true,
    "report": {
      "userName": "Pedro Ramirez",
      "location": "Barangay 3",
      "priority": "Low",
      "hazardous": false,
      "images": ["assets/garbage.png", "assets/garbage.png"],
      "description": "Scattered leaves and plastic bottles on the street.",
      "createdAt": DateTime.now().subtract(const Duration(hours: 6)),
    }
  }
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

  void _toggleRead(int id) {
    setState(() {
      final notif = _notifications.firstWhere((n) => n["id"] == id);
      notif["unread"] = !(notif["unread"] as bool);
    });
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

  void _showCommentDialog(Map<String, dynamic> notif, String status) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Comment for $status"),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: "Enter comment"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              notif["status"] = status;
              notif["comment"] = controller.text;
            });
            Navigator.pop(context);
            Navigator.pop(context); // close both dialogs
          },
          child: const Text("Submit"),
        ),
      ],
    ),
  );
}

  Future<Map<String, String>?> _pickAssignee() async {
    String query = "";
    // Keep a master list; filter from it each time
    final List<Map<String, String>> people = [
      {"name": "Alice", "avatar": "assets/profilepicture.png"},
      {"name": "Bob", "avatar": "assets/profilepicture.png"},
      {"name": "Charlie", "avatar": "assets/profilepicture.png"},
      {"name": "Diana", "avatar": "assets/profilepicture.png"},
      {"name": "Ethan", "avatar": "assets/profilepicture.png"},
      {"name": "Fiona", "avatar": "assets/profilepicture.png"},
      {"name": "George", "avatar": "assets/profilepicture.png"},
      {"name": "Hannah", "avatar": "assets/profilepicture.png"},
      {"name": "Ian", "avatar": "assets/profilepicture.png"},
      {"name": "Jasmine", "avatar": "assets/profilepicture.png"},
      {"name": "Kevin", "avatar": "assets/profilepicture.png"},
      {"name": "Laura", "avatar": "assets/profilepicture.png"},
      {"name": "Michael", "avatar": "assets/profilepicture.png"},
      {"name": "Nina", "avatar": "assets/profilepicture.png"},
      {"name": "Oscar", "avatar": "assets/profilepicture.png"},
      {"name": "Paula", "avatar": "assets/profilepicture.png"},
      {"name": "Quinn", "avatar": "assets/profilepicture.png"},
      {"name": "Rachel", "avatar": "assets/profilepicture.png"},
      {"name": "Sam", "avatar": "assets/profilepicture.png"},
      {"name": "Tina", "avatar": "assets/profilepicture.png"},
      {"name": "Uma", "avatar": "assets/profilepicture.png"},
      {"name": "Victor", "avatar": "assets/profilepicture.png"},
      {"name": "Wendy", "avatar": "assets/profilepicture.png"},
      {"name": "Xavier", "avatar": "assets/profilepicture.png"},
      {"name": "Yara", "avatar": "assets/profilepicture.png"},
      {"name": "Zack", "avatar": "assets/profilepicture.png"},
    ];
    List<Map<String, String>> filtered = List.from(people);
    

    Map<String, List<Map<String, String>>> groupAlphabetically(List<Map<String, String>> list) {
      final Map<String, List<Map<String, String>>> grouped = {};
      for (var p in list) {
        final letter = p["name"]!.substring(0, 1).toUpperCase();
        grouped.putIfAbsent(letter, () => []).add(p);
      }
      final sortedKeys = grouped.keys.toList()..sort();
      return {for (var k in sortedKeys) k: grouped[k]!};
    }

    Widget buildList(StateSetter setState) {
      final grouped = groupAlphabetically(filtered);
      return ListView(
        shrinkWrap: true,
        children: grouped.entries.expand((entry) {
          return [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            ...entry.value.map((p) {
              return ListTile(
                leading: CircleAvatar(backgroundImage: AssetImage(p["avatar"]!)),
                title: Text(p["name"]!),
                onTap: () => Navigator.pop(context, p),
              );
            })
          ];
        }).toList(),
      );
    }

    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return await showDialog<Map<String, String>>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              return AlertDialog(
                title: const Text("Assign to"),
                content: SizedBox(
                  width: 320,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: "Search...",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            query = val.toLowerCase();
                            filtered = people
                                .where((p) => p["name"]!.toLowerCase().contains(query))
                                .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      SizedBox(height: 260, child: buildList(setState)),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text("Cancel")),
                ],
              );
            },
          );
        },
      );
    } else {
      return await showModalBottomSheet<Map<String, String>>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              return SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: "Search...",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (val) {
                            setState(() {
                              query = val.toLowerCase();
                              filtered = people
                                  .where((p) => p["name"]!.toLowerCase().contains(query))
                                  .toList();
                            });
                          },
                        ),
                      ),
                      Flexible(child: buildList(setState)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
  }

  void _openNotification(Map<String, dynamic> notif) {
    setState(() => notif["unread"] = false);

    if (notif["type"] == "report") {
      final report = notif["report"];
      final images = List<String>.from(report["images"] ?? []);
      final bool hazardous = report["hazardous"] == true;
      final PageController pageController = PageController();
      int currentIndex = 0;

      // Capture root context for SnackBar
      final rootContext = context;

      showDialog(
        context: context,
        builder: (_) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: 360,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Image carousel with ribbon + arrows + dots
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: images.isEmpty
                                  ? Container(
                                      color: Colors.grey[200],
                                      child: const Center(child: Icon(Icons.image, size: 40)),
                                    )
                                  : PageView.builder(
                                      controller: pageController,
                                      itemCount: images.length,
                                      onPageChanged: (i) => setState(() => currentIndex = i),
                                      itemBuilder: (_, i) {
                                        return Image.asset(
                                          images[i],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                        );
                                      },
                                    ),
                            ),
                          ),
                          // Ribbon (Priority)
                          Positioned(
                            top: 10,
                            right: -30,
                            child: Transform.rotate(
                              angle: math.pi / 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 40),
                                color: report["priority"] == "High"
                                    ? Colors.red
                                    : report["priority"] == "Medium"
                                        ? Colors.orange
                                        : Colors.green,
                                child: Text(
                                  report["priority"] ?? "Low",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Prev button
                          if (currentIndex > 0)
                            Positioned(
                              left: 4,
                              top: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () {
                                  pageController.previousPage(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const SizedBox(
                                  width: 40,
                                  child: Icon(Icons.chevron_left, color: Colors.white, size: 28),
                                ),
                              ),
                            ),
                          // Next button
                          if (currentIndex < images.length - 1)
                            Positioned(
                              right: 4,
                              top: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () {
                                  pageController.nextPage(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: const SizedBox(
                                  width: 40,
                                  child: Icon(Icons.chevron_right, color: Colors.white, size: 28),
                                ),
                              ),
                            ),
                          // Dots
                          if (images.isNotEmpty)
                            Positioned(
                              bottom: 8,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(images.length, (i) {
                                  final active = currentIndex == i;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    width: active ? 8 : 6,
                                    height: active ? 8 : 6,
                                    decoration: BoxDecoration(
                                      color: active ? Colors.white : Colors.white.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // User + Location + Hazardous
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 18,
                            backgroundImage: AssetImage("assets/profilepicture.png"),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(report["userName"] ?? "",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        report["location"] ?? "",
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: hazardous ? Colors.red : Colors.green,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        hazardous ? "Hazardous" : "Safe",
                                        style: const TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Description
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          report["description"] ?? "",
                          style: const TextStyle(fontSize: 13, height: 1.3),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Assign button
                      ElevatedButton(
                        onPressed: () async {
                          final chosen = await _pickAssignee();
                          if (chosen == null) return;

                          setState(() {
                            notif["assignedTo"] = chosen["name"];
                          });

                          // Close dialog (optional). If you prefer to keep it open, remove the next line.
                          Navigator.of(ctx).pop();

                          ScaffoldMessenger.of(rootContext).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundImage: AssetImage(chosen["avatar"]!),
                                  ),
                                  const SizedBox(width: 8),
                                  Text("Assigned to ${chosen["name"]}"),
                                ],
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: const Size.fromHeight(36),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Assign", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } else if (notif["type"] == "event") {
  final event = notif["event"];
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 340,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // shrink to fit
            children: [
              // Title + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      notif["title"] ?? "Event",
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
                      vertical: 2,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: event["status"] == "accepted"
                          ? Colors.green[100]
                          : event["status"] == "rejected"
                              ? Colors.red[100]
                              : Colors.orange[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      (event["status"] ?? "pending").toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        height: 1.1,
                        color: event["status"] == "accepted"
                            ? Colors.green[800]
                            : event["status"] == "rejected"
                                ? Colors.red[800]
                                : Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              if (event["date"] != null)
                Text(
                  "📅 ${DateFormat.yMMMd().add_jm().format(event["date"])}",
                  style: const TextStyle(fontSize: 12.5, height: 1.2),
                ),
              if (event["volunteers"] != null)
                Text(
                  "👥 Volunteers: ${event["volunteers"]}",
                  style: const TextStyle(fontSize: 12.5, height: 1.2),
                ),

              if (event["description"] != null) ...[
                const SizedBox(height: 2),
                Text(
                  event["description"],
                  style: const TextStyle(fontSize: 13, height: 1.2),
                ),
              ],

              if (event["details"] != null) ...[
                const SizedBox(height: 2),
                Text(
                  event["details"],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    height: 1.2,
                  ),
                ),
              ],

              if (event["comment"] != null) ...[
                const SizedBox(height: 2),
                Text(
                  "💬 ${event["comment"]}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
              ],

              const SizedBox(height: 8), // compact spacing before buttons

              // Buttons
              Wrap(
                spacing: 6,
                runSpacing: 4, // tighter vertical spacing if wrapped
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        event["status"] = "accepted";
                      });
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text("Accept"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      textStyle: const TextStyle(fontSize: 13, height: 1.1),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _showCommentDialog(event, "rejected");
                    },
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    label: const Text("Reject",
                        style: TextStyle(fontSize: 13, color: Colors.red)),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      _showCommentDialog(event, "revise");
                    },
                    icon: const Icon(Icons.edit,
                        size: 16, color: Colors.orange),
                    label: const Text("Revise",
                        style: TextStyle(fontSize: 13, color: Colors.orange)),
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

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n["unread"] == true).length;

    // notify parent about unread count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onUnreadChanged?.call(unreadCount);
    });

    // filter
    final filtered = _notifications.where((n) {
      if (_filter == "Unread") return n["unread"] == true;
      if (_filter == "Reports") return n["type"] == "report";
      if (_filter == "Events") return n["type"] == "event";
      return true;
    }).toList();

    // group by time
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
            child: const Text("Mark all as read", style: TextStyle(color: Colors.blue)),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      "Unread",
                      style: TextStyle(
                          color: Colors.blue.shade900, fontWeight: FontWeight.w600),
                    ),
                    Text("$unreadCount",
                        style:
                            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "Reports",
                      style: TextStyle(
                          color: Colors.blue.shade900, fontWeight: FontWeight.w600),
                    ),
                    Text(
                        "${filtered.where((n) => n["type"] == "report").length}",
                        style:
                            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      "Events",
                      style: TextStyle(
                          color: Colors.blue.shade900, fontWeight: FontWeight.w600),
                    ),
                    Text(
                        "${filtered.where((n) => n["type"] == "event").length}",
                        style:
                            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ),
          // List
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
                    children: grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: Text(entry.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87)),
                          ),
                          ...entry.value.map((notif) {
                            final bool isUnread = notif["unread"] as bool;
                            final bool isSelected = _selected.contains(notif["id"]);
                            final idKey = ValueKey<int>(notif["id"] as int);

                            final card = Card(
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
                            child: InkWell(
                              onTap: () {
                                if (_selected.isNotEmpty) {
                                  setState(() {
                                    if (isSelected) {
                                      _selected.remove(notif["id"]);
                                    } else {
                                      _selected.add(notif["id"]);
                                    }
                                  });
                                } else {
                                  _openNotification(notif);
                                }
                              },
                              onLongPress: () {
                                setState(() {
                                  _selected.add(notif["id"]);
                                });
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: isUnread
                                    ? BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.withOpacity(0.2),
                                            Colors.blue.withOpacity(0.05)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      )
                                    : null,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: AssetImage(notif["profile"]),
                                    radius: 22,
                                  ),
                                  title: Row(
                                    children: [
                                      if (notif["type"] == "report")
                                        const Padding(
                                          padding: EdgeInsets.only(right: 6.0),
                                          child: Icon(Icons.report, size: 16, color: Colors.redAccent),
                                        )
                                      else
                                        const Padding(
                                          padding: EdgeInsets.only(right: 6.0),
                                          child: Icon(Icons.event, size: 16),
                                        ),
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
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notif["subtitle"],
                                        style: TextStyle(color: Colors.grey[700]),
                                      ),
                                      if (notif["assignedTo"] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Chip(
                                            label: Text("Assigned: ${notif["assignedTo"]}"),
                                            backgroundColor: Colors.blue.shade50,
                                            labelStyle: const TextStyle(fontSize: 11, color: Colors.blue),
                                            visualDensity: VisualDensity.compact,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          DateFormat('MMM d, yyyy • h:mm a').format(notif["time"]),
                                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == "toggle_read") _toggleRead(notif["id"]);
                                      if (value == "delete") _delete(notif["id"]);
                                    },
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(
                                        value: "toggle_read",
                                        child: Text(isUnread ? "Mark as read" : "Mark as unread"),
                                      ),
                                      const PopupMenuItem(
                                        value: "delete",
                                        child: Text("Delete"),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );

                            // Enable swipe-to-delete on mobile
                            final isNarrow = MediaQuery.of(context).size.width < 800;
                            if (!isNarrow) return card;

                            return Dismissible(
                              key: idKey,
                              direction: _selected.isEmpty
                                  ? DismissDirection.endToStart
                                  : DismissDirection.none,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.red.shade400, Colors.red.shade600],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              confirmDismiss: (_) async {
                                return _selected.isEmpty;
                              },
                              onDismissed: (_) => _delete(notif["id"]),
                              child: card,
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
