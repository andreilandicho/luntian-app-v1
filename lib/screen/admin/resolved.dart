import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_application_1/screen/admin/widget reports/resolved_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class ResolvedPage extends StatefulWidget {
  const ResolvedPage({super.key});

  @override
  State<ResolvedPage> createState() => _ResolvedPageState();
}

class _ResolvedPageState extends State<ResolvedPage> {
  String selectedFilter = "All";
  String selectedSort = "Newest First";

  final List<String> filters = ["All", "High", "Medium", "Low"];
  final List<String> sortOptions = [
    "Newest First",
    "Oldest First",
    "Priority High → Low",
    "Priority Low → High"
  ];

  List<Map<String, dynamic>> allReports = [];
  final GlobalKey _filterIconKey = GlobalKey();
  double _tallestCardHeight = 0;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    await _fetchReports();
    await _fetchOfficialNames();
  }

  Future<void> _fetchReports() async {
    final prefs = await SharedPreferences.getInstance();
    final barangayId = prefs.getInt('barangay_id'); // the logged-in user's barangay

      if (barangayId == null) {
        throw Exception("No barangay_id found for logged in user");
      }
      try {
        // First, try a simpler query to understand your schema
        final List<dynamic> data = await Supabase.instance.client
            .from('reports')
            .select('''
              *,
              report_solutions(*),
              report_ratings(*),
              report_assignments(*),
              users!reports_user_id_fkey(*)
            ''')
            .eq('status', 'resolved')
            .eq('barangay_id', barangayId) // Adjust as needed
            .order('created_at', ascending: false);

        setState(() {
          allReports = data.map((e) {
            final map = Map<String, dynamic>.from(e);

            // Basic report info from reports table
            map["reportId"] = map["report_id"];
            map["description"] = map["description"];
            map["priority"] = map["priority"];
            map["hazardous"] = map["hazardous"] ?? false;
            
            // Location - extract latitude and longitude from reports table
            // Check for different possible field names
             // Location - extract latitude and longitude from multiple possible fields
            map["latitude"] = map["latitude"] ?? map["lat"] ?? map["gps_lat"] ?? map["location_lat"];
            map["longitude"] = map["longitude"] ?? map["lon"] ?? map["lng"] ?? map["gps_lng"] ?? map["location_lng"];
            

            map["location"] = (map["latitude"] != null && map["longitude"] != null)
            ? "${map["latitude"]}, ${map["longitude"]}"
            : null;

            // Dates from reports table
            map["createdAt"] = map["created_at"] != null
                ? DateTime.parse(map["created_at"])
                : DateTime.now();
            map["dateSolved"] =
                (map["report_solutions"] != null && (map["report_solutions"] as List).isNotEmpty)
                    ? DateTime.parse(map["report_solutions"][0]["updated_at"])
                    : null;

            // Before photos - from reports table (photo_urls)
            map["beforePhotos"] = List<String>.from(map["photo_urls"] ?? []);
            
            // After photos - from report_solutions table (after_photo_urls)
            map["afterPhotos"] =
                (map["report_solutions"] != null && (map["report_solutions"] as List).isNotEmpty)
                    ? List<String>.from(map["report_solutions"][0]["after_photo_urls"] ?? [])
                    : [];

            // Combine all images for carousel (before + after)
            map["images"] = [...map["beforePhotos"], ...map["afterPhotos"]];
            if (map["images"].isEmpty) {
              map["images"] = ["assets/garbage.png"];
            }

            // Rating & feedback from report_ratings table
            map["rating"] =
                (map["report_ratings"] != null && (map["report_ratings"] as List).isNotEmpty)
                    ? map["report_ratings"][0]["average_user_rate"] ?? 0
                    : 0;
            map["feedback"] =
                (map["report_ratings"] != null && (map["report_ratings"] as List).isNotEmpty)
                    ? map["report_ratings"][0]["comments"] ?? ""
                    : "";

            // Who cleaned it - simplified approach
            map["cleanedBy"] = "Unassigned";
            if (map["report_assignments"] != null && 
                (map["report_assignments"] as List).isNotEmpty) {
              
              final assignment = map["report_assignments"][0];
              
              // Try to get official_id and fetch separately if needed
              if (assignment["official_id"] != null) {
                map["cleanedBy"] = "Official ID: ${assignment["official_id"]}";
              }
            }
            

            // User info (reporter) from users table
            final isAnonymous = map["anonymous"] == true;

            map["userName"] = isAnonymous
                ? "Anonymous Citizen"
                : (map["users"] != null ? map["users"]["name"] : "Unknown");

            map["userProfileUrl"] = isAnonymous
                ? null // ✅ no image at all
                : (map["users"] != null ? map["users"]["user_profile_url"] : null);

            map["userId"] = isAnonymous
                ? null
                : (map["users"] != null ? map["users"]["user_id"] : null);


            return map;
          }).toList();
        });

      } catch (e) {
        debugPrint("Error fetching resolved reports: $e");
        setState(() {
          allReports = [];
        });
      }
    }

    Future<void> _fetchOfficialNames() async {
      try {
        // Get all unique official IDs from ALL assignments (not just first one)
        final officialIdsFromAssignments = allReports
            .expand((report) => report["report_assignments"] ?? [])
            .where((assignment) => assignment?["official_id"] != null)
            .map((assignment) => assignment?["official_id"])
            .where((id) => id != null)
            .cast<int>()
            .toSet()
            .toList();

        if (officialIdsFromAssignments.isEmpty) return;

        // Fetch officials where user_id matches the official_id from assignments
        final officialsResponse = await Supabase.instance.client
            .from('officials')
            .select('official_id, user_id')
            .inFilter('user_id', officialIdsFromAssignments);

        final officialsData = officialsResponse as List<dynamic>;

        // Create a map: user_id -> official data
        final officialsByUserIdMap = <int, dynamic>{};
        for (var official in officialsData) {
          if (official?['user_id'] != null) {
            officialsByUserIdMap[official!['user_id'] as int] = official;
          }
        }

        // Fetch user names for all user IDs
        final userIds = officialsData
            .where((official) => official?['user_id'] != null)
            .map((official) => official!['user_id'] as int)
            .toSet()
            .toList();

        Map<int, dynamic> usersMap = {};
        if (userIds.isNotEmpty) {
          final usersResponse = await Supabase.instance.client
              .from('users')
              .select('user_id, name')
              .inFilter('user_id', userIds);
          
          final usersData = usersResponse as List<dynamic>;
          for (var user in usersData) {
            if (user?['user_id'] != null) {
              usersMap[user!['user_id'] as int] = user;
            }
          }
        }

        // Update ALL assignments with official names, not just the first one
        setState(() {
          for (var report in allReports) {
            final assignments = report["report_assignments"] as List<dynamic>?;
            
            if (assignments != null) {
              for (var assignment in assignments) {
                final officialIdFromAssignment = assignment?["official_id"] as int?;
                
                if (officialIdFromAssignment != null) {
                  if (officialsByUserIdMap.containsKey(officialIdFromAssignment)) {
                    final official = officialsByUserIdMap[officialIdFromAssignment];
                    final userId = official?['user_id'] as int?;
                    
                    if (userId != null && usersMap.containsKey(userId)) {
                      final userName = usersMap[userId]?['name'] as String?;
                      assignment["cleanedBy"] = userName ?? "User ID: $userId";
                    } else {
                      final officialId = official?['official_id'] as int?;
                      assignment["cleanedBy"] = "Official ID: ${officialId ?? 'Unknown'}";
                    }
                  } else {
                    assignment["cleanedBy"] = "Official ID: $officialIdFromAssignment (Not Found)";
                  }
                } else {
                  assignment["cleanedBy"] = "Unassigned";
                }
              }
            }
          }
        });

      } catch (e) {
        debugPrint("Error fetching official names: $e");
      }
    }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 800;

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
            automaticallyImplyLeading: false,
            toolbarHeight: 56,
            title: Row(
              children: [
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Resolved Reports (${filteredReports.length})",
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
                    fixedHeight: _tallestCardHeight > 0
                        ? _tallestCardHeight
                        : null,
                    onHeightMeasured: _updateTallestHeight,
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