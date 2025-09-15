import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/admin/widget reports/report_card.dart';

Color _priorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case "high":
      return Colors.red;
    case "medium":
      return Colors.orange;
    case "low":
      return Colors.green;
    default:
      return Colors.grey;
  }
}

class PendingPage extends StatefulWidget {
  final List<Map<String, dynamic>> reports;
  

  const PendingPage({
    super.key,
    this.reports = const [],
  });

  @override
  State<PendingPage> createState() => _PendingPageState();
}

class _PendingPageState extends State<PendingPage> {
  String selectedFilter = "All";
  String selectedSort = "Newest First";

  final List<String> filters = ["All", "High", "Medium", "Low"];
  final List<String> sortOptions = [
    "Newest First",
    "Oldest First",
    "Priority High → Low",
    "Priority Low → High"
  ];

  late List<Map<String, dynamic>> allReports;

  final GlobalKey _filterIconKey = GlobalKey();
  double _tallestCardHeight = 0;

  @override
  void initState() {
    super.initState();
    allReports = _generateMockReports();
  }

  List<Map<String, dynamic>> _generateMockReports() {
    final priorities = ["High", "Medium", "Low"];
    return List.generate(12, (index) {
      return {
        "userName": "User ${index + 1}",
        "location": "Barangay ${index + 1}",
        "hazardous": index % 2 == 0,
        "priority": priorities[index % priorities.length],
        "images": [
          "assets/garbage.png",
          "assets/garbage.png",
          "assets/garbage.png",
        ],
        "description":
            "Sample description for report number ${index + 1}. This is a preview of the issue the user has reported.",
        "createdAt":
            DateTime.now().subtract(Duration(hours: (index + 1) * 3)),
      };
    });
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  bool _isDesktop(BuildContext context) =>
  MediaQuery.of(context).size.width >= 800;

  final List<Map<String, String>> dummyPeople = [
    {"name": "Alice", "avatar": "assets/profile picture.png"},
    {"name": "Bob", "avatar": "assets/profile picture.png"},
    {"name": "Charlie", "avatar": "assets/profile picture.png"},
    {"name": "Diana", "avatar": "assets/profile picture.png"},
    {"name": "Ethan", "avatar": "assets/profile picture.png"},
    {"name": "Fiona", "avatar": "assets/profile picture.png"},
    {"name": "George", "avatar": "assets/profile picture.png"},
    {"name": "Hannah", "avatar": "assets/profile picture.png"},
    {"name": "Ian", "avatar": "assets/profile picture.png"},
    {"name": "Jasmine", "avatar": "assets/profile picture.png"},
    {"name": "Kevin", "avatar": "assets/profile picture.png"},
    {"name": "Laura", "avatar": "assets/profile picture.png"},
    {"name": "Michael", "avatar": "assets/profile picture.png"},
    {"name": "Nina", "avatar": "assets/profile picture.png"},
    {"name": "Oscar", "avatar": "assets/profile picture.png"},
    {"name": "Paula", "avatar": "assets/profile picture.png"},
    {"name": "Quinn", "avatar": "assets/profile picture.png"},
    {"name": "Rachel", "avatar": "assets/profile picture.png"},
    {"name": "Sam", "avatar": "assets/profile picture.png"},
    {"name": "Tina", "avatar": "assets/profile picture.png"},
    {"name": "Uma", "avatar": "assets/profile picture.png"},
    {"name": "Victor", "avatar": "assets/profile picture.png"},
    {"name": "Wendy", "avatar": "assets/profile picture.png"},
    {"name": "Xavier", "avatar": "assets/profile picture.png"},
    {"name": "Yara", "avatar": "assets/profile picture.png"},
    {"name": "Zack", "avatar": "assets/profile picture.png"},
  ]..sort((a, b) => a["name"]!.compareTo(b["name"]!));

  /// Mobile: bottom sheet with filter & sort
  void _showFilterSortMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Filter by Priority",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...filters.map((filter) {
                    final isSelected = selectedFilter == filter;
                    return ListTile(
                      leading: filter == "All"
                          ? const Icon(Icons.all_inclusive)
                          : Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _priorityColor(filter),
                                shape: BoxShape.circle,
                              ),
                            ),
                      title: Text(filter),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                      onTap: () {
                        setModalState(() => selectedFilter = filter);
                      },
                    );
                  }),
                  const Divider(height: 24),
                  const Text("Sort by",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...sortOptions.map((sort) {
                    final isSelected = selectedSort == sort;
                    return ListTile(
                      title: Text(sort),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.blue)
                          : null,
                      onTap: () {
                        setModalState(() => selectedSort = sort);
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Apply both filter and sort
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "Apply",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Desktop: quick popup menu with filter & sort
  void _showQuickFilterMenu() async {
    final RenderBox iconBox =
        _filterIconKey.currentContext!.findRenderObject() as RenderBox;
    final Offset position = iconBox.localToGlobal(Offset.zero);

    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + iconBox.size.height,
        position.dx + iconBox.size.width,
        position.dy,
      ),
      items: [
        const PopupMenuItem<String>(
          value: "_header_filter",
          child: Text(
            "Filter by Priority",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...filters.map((filter) => PopupMenuItem<String>(
              value: "filter:$filter",
              child: Row(
                children: [
                  filter == "All"
                      ? const Icon(Icons.all_inclusive, size: 18)
                      : Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _priorityColor(filter),
                            shape: BoxShape.circle,
                          ),
                        ),
                  const SizedBox(width: 8),
                  Text(filter),
                  if (selectedFilter == filter)
                    const Spacer(),
                  if (selectedFilter == filter)
                    const Icon(Icons.check, color: Colors.blue, size: 16),
                ],
              ),
            )),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: "_header_sort",
          child: Text(
            "Sort by",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...sortOptions.map((sort) => PopupMenuItem<String>(
              value: "sort:$sort",
              child: Row(
                children: [
                  Text(sort),
                  if (selectedSort == sort) const Spacer(),
                  if (selectedSort == sort)
                    const Icon(Icons.check, color: Colors.blue, size: 16),
                ],
              ),
            )),
      ],
    );

    if (selected != null) {
      if (selected.startsWith("filter:")) {
        setState(() => selectedFilter = selected.split(":")[1]);
      } else if (selected.startsWith("sort:")) {
        setState(() => selectedSort = selected.split(":")[1]);
      }
    }
  }

  List<Map<String, dynamic>> _applyFilterAndSort() {
    List<Map<String, dynamic>> filtered = selectedFilter == "All"
        ? List.from(allReports)
        : allReports
            .where((r) =>
                r["priority"].toString().toLowerCase() ==
                selectedFilter.toLowerCase())
            .toList();

    switch (selectedSort) {
      case "Newest First":
        filtered.sort((a, b) =>
            (b["createdAt"] as DateTime).compareTo(a["createdAt"] as DateTime));
        break;
      case "Oldest First":
        filtered.sort((a, b) =>
            (a["createdAt"] as DateTime).compareTo(b["createdAt"] as DateTime));
        break;
      case "Priority High → Low":
        const order = {"High": 1, "Medium": 2, "Low": 3};
        filtered.sort((a, b) =>
            order[a["priority"]]!.compareTo(order[b["priority"]]!));
        break;
      case "Priority Low → High":
        const orderRev = {"High": 3, "Medium": 2, "Low": 1};
        filtered.sort((a, b) =>
            orderRev[a["priority"]]!.compareTo(orderRev[b["priority"]]!));
        break;
    }

    return filtered;
  }

  void _updateTallestHeight(double height) {
    if (height > _tallestCardHeight) {
      setState(() {
        _tallestCardHeight = height;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _applyFilterAndSort();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
            pinned: true,
            elevation: 1,
            titleSpacing: 0,
            toolbarHeight: 56,
            title: Row(
              children: [
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Pending Reports (${filteredReports.length})",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Marykate'),
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: "Filter & Sort",
                  child: InkWell(
                    key: _filterIconKey,
                    onTap: () {
                      if (_isDesktop(context)) {
                        _showQuickFilterMenu();
                      } else {
                        _showFilterSortMenu();
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child:
                          const Icon(Icons.filter_list, color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final report = filteredReports[index];
                  return ReportCard(
                    report: report,
                    priorityColor: _priorityColor(report["priority"]),
                    timeAgo: _timeAgo(report["createdAt"] as DateTime),
                    onMarkInProgress: () {
                      setState(() {
                        allReports.remove(report);
                      });
                    },
                    fixedHeight: _tallestCardHeight > 0 ? _tallestCardHeight : null,
                    onHeightMeasured: _updateTallestHeight,
                    people: dummyPeople, // new
                    onAssign: (updatedReport) {
                      setState(() {
                        allReports.remove(report); // remove from pending
                        // here you could add to "In Progress" list later
                      });
                    },
                  );
                },
                childCount: filteredReports.length,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 500,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.74,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
