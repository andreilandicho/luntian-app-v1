import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert'; // for jsonEncode
import 'package:http/http.dart' as http; // for http.post, etc.


class ReportCard extends StatefulWidget {
  final Map<String, dynamic> report;
  final Color priorityColor;
  final String timeAgo;

  /// Optional legacy callback (you can ignore it if using onAssign).
  final VoidCallback? onMarkInProgress;

  /// Called after we set `assignedTo` and show a snackbar; parent should remove the card.
  final void Function(Map<String, dynamic> updatedReport) onAssign;

  /// For equal heights, if provided by parent.
  final double? fixedHeight;
  final Function(double) onHeightMeasured;

  /// People list comes from parent so you can later swap with a real API.
  final List<Map<String, dynamic>> people;

  /// Whether this card is selectable for batch operations
  final bool selectable;

  /// Whether this card is currently selected
  final bool isSelected;

  /// Callback when selection state changes
  final void Function(bool)? onSelectionChanged;

  const ReportCard({
    super.key,
    required this.report,
    required this.priorityColor,
    required this.timeAgo,
    this.onMarkInProgress,
    required this.onAssign,
    this.fixedHeight,
    required this.onHeightMeasured,
    required this.people,
    this.selectable = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
  final supabase = Supabase.instance.client;
  int _currentImageIndex = 0;
  late final PageController _pageController;
  final GlobalKey _cardKey = GlobalKey();

  bool get _isDesktop =>
      MediaQuery.of(context).size.width >= 800; // same breakpoint as parent

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final h = _cardKey.currentContext?.size?.height ?? 0;
      widget.onHeightMeasured(h);
    });
  }

  void _goToImage(int index, int max) {
    if (index >= 0 && index < max) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<List<Map<String, dynamic>>?> _pickAssignees() async {
    String query = "";
    List<Map<String, dynamic>> filtered = List.from(widget.people);
    Set<String> selectedIds = {};

    // Group people alphabetically
    Map<String, List<Map<String, dynamic>>> groupAlphabetically(
        List<Map<String, dynamic>> list) {
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var p in list) {
        final letter = (p["name"] ?? "").toString().substring(0, 1).toUpperCase();
        grouped.putIfAbsent(letter, () => []).add(p);
      }
      final sortedKeys = grouped.keys.toList()..sort();
      final sortedMap = {for (var k in sortedKeys) k: grouped[k]!};
      return sortedMap;
    }

    // Build the grouped user list with checkboxes
    Widget buildList(StateSetter setState) {
      final grouped = groupAlphabetically(filtered);
      return ListView(
        shrinkWrap: true,
        children: grouped.entries.expand((entry) {
          return [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: Text(
                entry.key,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            ...entry.value.map((p) {
              final userId = p['user_id'] ?? p['id'] ?? p['userId'] ?? p['official_id'];
              final isSelected = selectedIds.contains(userId);
              
              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedIds.add(userId);
                    } else {
                      selectedIds.remove(userId);
                    }
                  });
                },
                secondary: CircleAvatar(
                  backgroundImage: AssetImage(
                      (p["avatar"] ?? "assets/profile picture.png") as String),
                ),
                title: Text((p["name"] ?? "").toString()),
              );
            })
          ];
        }).toList(),
      );
    }

    if (_isDesktop) {
      return await showDialog<List<Map<String, dynamic>>>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setState) {
              return AlertDialog(
                title: const Text("Assign"),
                content: SizedBox(
                  width: 400,
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
                            filtered = widget.people
                                .where((p) => (p["name"] ?? "")
                                    .toString()
                                    .toLowerCase()
                                    .contains(query))
                                .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      SizedBox(height: 300, child: buildList(setState)),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final selectedPeople = widget.people
                          .where((p) {
                            final userId = p['user_id'] ?? p['id'] ?? p['userId'] ?? p['official_id'];
                            return selectedIds.contains(userId);
                          })
                          .toList();
                      Navigator.pop(ctx, selectedPeople);
                    },
                    child: const Text("Assign"),
                  ),
                ],
              );
            },
          );
        },
      );
    } else {
      return await showModalBottomSheet<List<Map<String, dynamic>>>(
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
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
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
                              filtered = widget.people
                                  .where((p) => (p["name"] ?? "")
                                      .toString()
                                      .toLowerCase()
                                      .contains(query))
                                  .toList();
                            });
                          },
                        ),
                      ),
                      Flexible(child: buildList(setState)),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(ctx, null),
                                child: const Text("Cancel"),
                              ),
                            ),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final selectedPeople = widget.people
                                      .where((p) {
                                        final userId = p['user_id'] ?? p['id'] ?? p['userId'] ?? p['official_id'];
                                        return selectedIds.contains(userId);
                                      })
                                      .toList();
                                  Navigator.pop(ctx, selectedPeople);
                                },
                                child: const Text("Assign Selected"),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Future<void> _handleAssign() async {
  final chosenPeople = await _pickAssignees();
  if (chosenPeople == null || chosenPeople.isEmpty) return;

  final reportId = widget.report['reportId'] ??
      widget.report['report_id'] ??
      widget.report['id'];

  if (reportId == null) {
    print('Debug: Report keys: ${widget.report.keys}');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Missing report ID")),
      );
      return;
    }
    //assigning officials
    try {
      // official assignments
      for (final person in chosenPeople) {
        // Handle different possible field names for user ID
        final userId = person['user_id'] ?? 
                      person['id'] ?? 
                      person['userId'] ?? 
                      person['official_id'];

        if (userId == null) {
          print('Debug: Person keys: ${person.keys}');
          continue;
        }
    }
    return;
  }

  try {
    // Insert or upsert assignments safely
    for (final person in chosenPeople) {
      final userId = person['user_id'] ??
          person['id'] ??
          person['userId'] ??
          person['official_id'];
      if (userId == null) continue;

      final insertRes = await supabase
        .from('report_assignments')
        .upsert([
          {
            'report_id': reportId,
            'official_id': userId,
            'assigned_at': DateTime.now().toIso8601String(),
          }
        ], onConflict: 'report_id,official_id');


      if (insertRes == null) {
        print("❌ Insert returned null — check table access or RLS");
      } else if (insertRes.error != null) {
        print("❌ Insert error for user $userId: ${insertRes.error!.message}");
      } else {
        print("✅ Assignment inserted for user $userId");
      }
    }

    // Update report status
    final updateRes = await supabase
        .from('reports')
        .update({'status': 'in_progress'})
        .eq('report_id', reportId);

    if (updateRes == null) {
      print("❌ Update returned null — check table access");
    } else if (updateRes.error != null) {
      print("❌ Update error: ${updateRes.error!.message}");
    } else {
      print("✅ Report status updated");
    }

    // Call backend to trigger emails
    try {
      final backendRes = await http.post(
        Uri.parse("http://localhost:3000/notif/officialAssignment"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"report_id": reportId}),
      );

      if (backendRes.statusCode == 200) {
        print("✅ Official notification triggered successfully");
      } else {
        print("❌ Backend error: ${backendRes.body}");
      }
    } catch (e) {
      print("❌ Failed to call backend: $e");
    }

    if (!mounted) return;

    final names = chosenPeople
        .map((p) => p["name"] ?? p["userName"] ?? "Unknown")
        .join(", ");
    widget.report["assignedTo"] = names;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Assigned to ${chosenPeople.length} person(s)"),
        duration: const Duration(seconds: 2),
      ),
    );

    widget.onAssign(widget.report);
  } catch (e) {
    print("❌ Failed to assign: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to assign report"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}



  @override
  Widget build(BuildContext context) {
    final hazardous = widget.report["hazardous"] == true;
    final images = List<String>.from(widget.report["images"] ?? const <String>[]);

    final card = Container(
      key: _cardKey,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isSelected 
            ? Theme.of(context).primaryColor 
            : Colors.black.withOpacity(0.05),
          width: widget.isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Image area
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image, size: 40)),
                        );
                      },
                    );
                  },
                ),
              ),

              // Selection checkbox (if selectable)
              if (widget.selectable)
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () {
                      if (widget.onSelectionChanged != null) {
                        widget.onSelectionChanged!(!widget.isSelected);
                      }
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: widget.isSelected 
                          ? Theme.of(context).primaryColor 
                          : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: widget.isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                ),

              // Priority ribbon
              Positioned(
                top: 8,
                right: -28,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 90),
                    padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
                    color: widget.priorityColor,
                    child: Center(
                      child: Text(
                        widget.report["priority"] ?? "",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Image nav arrows
              if (_currentImageIndex > 0)
                Positioned(
                  left: 4, top: 0, bottom: 0,
                  child: GestureDetector(
                    onTap: () => _goToImage(_currentImageIndex - 1, images.length),
                    child: const SizedBox(
                      width: 40,
                      child: Icon(Icons.chevron_left, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              if (_currentImageIndex < images.length - 1)
                Positioned(
                  right: 4, top: 0, bottom: 0,
                  child: GestureDetector(
                    onTap: () => _goToImage(_currentImageIndex + 1, images.length),
                    child: const SizedBox(
                      width: 40,
                      child: Icon(Icons.chevron_right, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              // Dots
              if (images.isNotEmpty)
                Positioned(
                  bottom: 8, left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (i) {
                      final active = _currentImageIndex == i;
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

          // Text + Assign button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User + location + hazard + time
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundImage: AssetImage("assets/profile picture.png"),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.report["userName"] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.report["location"] ?? "",
                                    style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: hazardous ? Colors.red : Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    hazardous ? "Hazardous" : "Safe",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "• ${widget.timeAgo}",
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.report["description"] ?? "",
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(height: 1.25),
                  ),

                  const Spacer(),

                  // Assign button
                  ElevatedButton(
                    onPressed: _handleAssign,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size.fromHeight(36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Assign",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.fixedHeight != null) {
      return SizedBox(height: widget.fixedHeight, child: card);
    }
    return card;
  }
}