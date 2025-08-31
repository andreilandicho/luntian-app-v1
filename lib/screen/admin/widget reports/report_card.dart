import 'package:flutter/material.dart';
import 'dart:math' as math;

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
  final List<Map<String, String>> people;

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
  });

  @override
  State<ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<ReportCard> {
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

  Future<Map<String, String>?> _pickAssignee() async {
  String query = "";
  List<Map<String, String>> filtered = List.from(widget.people);

  // Group people alphabetically
  Map<String, List<Map<String, String>>> groupAlphabetically(List<Map<String, String>> list) {
    final Map<String, List<Map<String, String>>> grouped = {};
    for (var p in list) {
      final letter = p["name"]!.substring(0, 1).toUpperCase();
      grouped.putIfAbsent(letter, () => []).add(p);
    }
    final sortedKeys = grouped.keys.toList()..sort();
    final sortedMap = { for (var k in sortedKeys) k : grouped[k]! };
    return sortedMap;
  }

  // Build the grouped user list
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
              leading: CircleAvatar(
                backgroundImage: AssetImage(p["avatar"]!),
              ),
              title: Text(p["name"]!),
              onTap: () => Navigator.pop(context, p),
            );
          })
        ];
      }).toList(),
    );
  }

  if (_isDesktop) {
    // Desktop: dialog with search
    return await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text("Assign to"),
              content: SizedBox(
                width: 300,
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
                              .where((p) => p["name"]!
                                  .toLowerCase()
                                  .contains(query))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 250,
                      child: buildList(setState),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text("Cancel"),
                ),
              ],
            );
          },
        );
      },
    );
  } else {
    // Mobile: bottom sheet with search
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
                                .where((p) => p["name"]!
                                    .toLowerCase()
                                    .contains(query))
                                .toList();
                          });
                        },
                      ),
                    ),
                    Flexible(
                      child: buildList(setState),
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
    final chosen = await _pickAssignee();
    if (chosen == null) return;

    // Save inside report (so it's recorded for later use/history).
    widget.report["assignedTo"] = chosen["name"];

    // Show snackbar with avatar + name BEFORE removing (so context is valid).
    ScaffoldMessenger.of(context).showSnackBar(
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

    // Inform parent to remove from Pending (disappear immediately).
    widget.onAssign(widget.report);
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
        border: Border.all(color: Colors.black.withOpacity(0.05)),
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
                child: images.isEmpty
                    ? Container(
                        color: Colors.grey[200],
                        child: const Center(child: Icon(Icons.image, size: 40)),
                      )
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged: (i) => setState(() => _currentImageIndex = i),
                        itemBuilder: (_, i) => Image.asset(
                          images[i],
                          fit: BoxFit.cover,
                          width: double.infinity,
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
