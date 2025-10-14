// lib/screen/admin/threshold_report_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'html_stub.dart'
    if (dart.library.html) 'html_web.dart';// Only works on web
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/services.dart'; // for 
import 'dart:convert';

class ThresholdReportPage extends StatefulWidget {
  const ThresholdReportPage({super.key});

  @override
  State<ThresholdReportPage> createState() => _ThresholdReportPageState();
}

class _ThresholdReportPageState extends State<ThresholdReportPage>
    with TickerProviderStateMixin {
    List<Map<String, dynamic>> _reports = [];
    bool _isLoading = true;

  Timer? _timer;
  DateTime _now = DateTime.now();

  // Filters
  String? _statusFilter; // "Pending", "In Progress", "Resolved"
  String? _specialFilter; // "NearDeadline", "Expired"
  String _sortBy = "Deadline Asc";
  String _searchQuery = "";

  // Pagination
  int _rowsPerPage = 5;
  int _currentPage = 0;

  // Animations
  late final AnimationController _pendingAnimCtrl;
  late final AnimationController _progressAnimCtrl;
  late final AnimationController _resolvedAnimCtrl;
  late final AnimationController _totalAnimCtrl;
  late final AnimationController _deadlineAnimCtrl;
  late final AnimationController _expiredAnimCtrl;

  @override
  void initState() {
    super.initState();
    _fetchReports();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });

    _pendingAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..forward();
    _progressAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..forward();
    _resolvedAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..forward();
    _totalAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..forward();
    _deadlineAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..forward();
    _expiredAnimCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..forward();
  }

    void _resetPagination() {
    setState(() {
      _currentPage = 0;
    });   
  }

  Future<void> _fetchReports() async {
    final prefs = await SharedPreferences.getInstance();
    final barangayId = prefs.getInt('barangay_id');

    if (barangayId == null) {
      throw Exception("No barangay_id found for logged in user");
    }
    try {
      // STEP 1: Fetch reports + reporter + assignments (only IDs)
      final reportsRes = await Supabase.instance.client
          .from('reports')
          .select('''
            report_id,
            created_at,
            report_deadline,
            status,
            users:user_id(user_id, name),
            report_assignments(assigned_at, official_id)
          ''')
          .eq('barangay_id', barangayId)
          .order('created_at', ascending: false);

      final reportsData = reportsRes as List;

      // STEP 2: Collect all user_ids from assignments (since official_id stores user_id)
      final allUserIds = reportsData
          .expand((r) => (r['report_assignments'] as List?)?.map((a) => a['official_id']) ?? [])
          .where((id) => id != null)
          .toSet()
          .toList();

      // STEP 3: Fetch officials by user_id + their user info
      Map<int, dynamic> officialsMap = {};
      if (allUserIds.isNotEmpty) {
        final officialsRes = await Supabase.instance.client
            .from('officials')
            .select('official_id, user_id, users(name)')
            .inFilter('user_id', allUserIds);

        for (final o in officialsRes) {
          officialsMap[o['user_id']] = o;
        }
      }

      // STEP 4: Merge reports with officials - HANDLE MULTIPLE ASSIGNMENTS
      List<Map<String, dynamic>> reports = [];
      for (final map in reportsData) {
        final reporter = map['users'] ?? {};
        final assignments = (map['report_assignments'] as List?) ?? [];
        
        String officialName = "Unassigned";
        DateTime? assignedAt;
        List<String> allAssignedOfficials = [];

        if (assignments.isNotEmpty) {
          // Sort assignments by date (most recent first)
          assignments.sort((a, b) {
            final aDate = a['assigned_at'] != null ? DateTime.parse(a['assigned_at']) : DateTime(0);
            final bDate = b['assigned_at'] != null ? DateTime.parse(b['assigned_at']) : DateTime(0);
            return bDate.compareTo(aDate);
          });

          // Get the most recent assignment for the main display
          final mostRecentAssignment = assignments[0];
          if (mostRecentAssignment['official_id'] != null) {
            final official = officialsMap[mostRecentAssignment['official_id']];
            officialName = official?['users']?['name'] ?? "Unassigned";
            assignedAt = mostRecentAssignment['assigned_at'] != null
                ? DateTime.parse(mostRecentAssignment['assigned_at'])
                : null;
          }

          // Collect all assigned officials for potential future use
          for (final assignment in assignments) {
            if (assignment['official_id'] != null) {
              final official = officialsMap[assignment['official_id']];
              final name = official?['users']?['name'] ?? "Unknown Official";
              if (!allAssignedOfficials.contains(name)) {
                allAssignedOfficials.add(name);
              }
            }
          }
        }

        reports.add({
          "report_id": map['report_id'],
          "reporter_name": reporter['name'] ?? "Unknown",
          "submission_date": DateTime.parse(map['created_at']),
          "report_deadline": map['report_deadline'] != null
              ? DateTime.parse(map['report_deadline'])
              : DateTime.now(),
          "status": formatStatus(map['status'] ?? "pending"),
          "assigned_official": officialName,
          "all_assigned_officials": allAssignedOfficials, // Store all officials
          "assigned_at": assignedAt,
          "assignment_count": assignments.length, // Store count for reference
        });
      }

      // STEP 5: Update state safely
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error fetching reports: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }


  @override
  void dispose() {
    _timer?.cancel();
    _pendingAnimCtrl.dispose();
    _progressAnimCtrl.dispose();
    _resolvedAnimCtrl.dispose();
    _totalAnimCtrl.dispose();
    _deadlineAnimCtrl.dispose();
    _expiredAnimCtrl.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d, String status) {
    if (status == "Resolved") return "Completed";
    if (d.isNegative) return "Expired";
    return "${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s";
  }

  String formatStatus(String status) {
    switch (status) {
      case "pending":
        return "Pending";
      case "in_progress":
        return "In Progress";
      case "resolved":
        return "Resolved";
      default:
        return status; // fallback
    }
  }


  Color _rowColor(Map<String, dynamic> report) {
    final timeRemaining = report["report_deadline"].difference(_now);
    
    // Only highlight near deadlines for non-resolved reports
    if (report["status"] != "Resolved" &&
        timeRemaining.inHours <= 24 && 
        !timeRemaining.isNegative) {
      return Colors.red.withOpacity(0.08);
    }
    
    switch (report["status"]) {
      case "Pending":
        return Colors.orange.withOpacity(0.08);
      case "In Progress":
        return Colors.blue.withOpacity(0.08);
      case "Resolved":
        return Colors.green.withOpacity(0.08);
      default:
        return Colors.grey.withOpacity(0.08);
    }
  }


List<Map<String, dynamic>> get _filteredReports {
  List<Map<String, dynamic>> list = [..._reports];

  // Special filter first
  // In the _filteredReports getter, update the NearDeadline filter:
  if (_specialFilter == "NearDeadline") {
    list = list.where((r) {
      final d = r["report_deadline"] as DateTime;
      final diff = d.difference(_now);
      return diff.inHours <= 24 && 
            diff > Duration.zero && 
            r["status"] != "Resolved"; // Exclude resolved reports
    }).toList();
    } else if (_specialFilter == "Expired") {
      list = list.where((r) {
        final d = r["report_deadline"] as DateTime;
        return d.isBefore(_now) && r["status"] != "Resolved"; // Exclude resolved reports
      }).toList();
    }

  // Regular status filter
  if (_statusFilter != null) {
    list = list.where((r) => r["status"] == _statusFilter).toList();
  }

  // Search
  if (_searchQuery.isNotEmpty) {
    list = list.where((r) {
      return r["report_id"].toString().contains(_searchQuery) ||
          r["reporter_name"].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r["assigned_official"].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Sorting
  if (_sortBy == "A-Z") {
    list.sort((a, b) => a["reporter_name"].compareTo(b["reporter_name"]));
  } else if (_sortBy == "Deadline Asc") {
    list.sort((a, b) => a["report_deadline"].compareTo(b["report_deadline"]));
  } else if (_sortBy == "Deadline Desc") {
    list.sort((a, b) => b["report_deadline"].compareTo(a["report_deadline"]));
  }

  return list;
}

  void _openGmailWeb(String recipient, String subject, String body) {
    final url = Uri.https(
      'mail.google.com',
      '/mail/',
      {
        'view': 'cm',
        'to': recipient,
        'su': subject,
        'body': body,
      },
    ).toString();

    HtmlHelper().open(url, '_blank');
  }

  // Function to show escalation dialog
  void _showEscalationDialog(Map<String, dynamic> report) {
  final timeRemaining = report["report_deadline"].difference(_now);
  final isExpired = timeRemaining.isNegative;

  final TextEditingController emailController = TextEditingController();
  emailController.text = _generateEmailTemplate(report, isExpired);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange),
          SizedBox(width: 8),
          Text('Escalation Email'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The email content is pre-filled. It will also be copied to your clipboard.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email Content',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.email),
          label: const Text('Send Email'),
          onPressed: () async {
            final content = emailController.text;
            final subject = 'Report Escalation From Luntian App';
            // final recipient = 'mhd@manila.gov.ph';
            final recipient = 'dps@manila.gov.ph';
            final mailtoUri = Uri(
              scheme: 'mailto',
              path: recipient,
              queryParameters: {
                'subject': subject,
                'body': content,
              },
            );

            // 1️⃣ Copy content to clipboard
            await Clipboard.setData(ClipboardData(text: content));

            // 2️⃣ Platform-specific email launch
            if (kIsWeb) {
              // Open Gmail in new tab with pre-filled email
              final gmailUrl = Uri.https(
                'mail.google.com',
                '/mail/',
                {
                  'view': 'cm',
                  'to': recipient,
                  'su': subject,
                  'body': content,
                },
              ).toString();

              HtmlHelper().open(gmailUrl, '_blank');

              if (mounted) Navigator.of(context).pop();

              if (mounted) {
                print("✅ Success!");
              }
            } else {
              // Mobile/Desktop
              try {
                await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);

                if (mounted) Navigator.of(context).pop();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Email client opened. Content copied to clipboard.'),
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              } catch (_) {
                // Fallback dialog if email cannot be launched
                _showClipboardFallbackDialog(content);
              }
            }
          },
        ),
      ],
    ),
  );
}

// Clipboard fallback dialog
void _showClipboardFallbackDialog(String content) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Email Client Not Available'),
      content: const Text(
          'The email content has been copied to your clipboard. Please open your email app manually and paste it.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('OK')),
      ],
    ),
  );
}




  // Show fallback dialog when email client can't be opened


  // Function to generate email template
  String _generateEmailTemplate(Map<String, dynamic> report, bool isExpired) {
    final submissionDate = DateFormat('yyyy-MM-dd HH:mm').format(report["submission_date"]);
    final deadlineDate = DateFormat('yyyy-MM-dd HH:mm').format(report["report_deadline"]);
    
    String statusContext = "";
    if (isExpired) {
      statusContext = "has EXPIRED and requires immediate attention";
    } else if (report["status"] == "Pending") {
      statusContext = "is still PENDING and requires follow-up";
    } else if (report["status"] == "In Progress") {
      statusContext = "is IN PROGRESS but may need additional resources";
    }
    
    // Build assigned officials string - include all officials
    String assignedOfficialsText;
    if (report["all_assigned_officials"].isEmpty) {
      assignedOfficialsText = "Unassigned";
    } else if (report["all_assigned_officials"].length == 1) {
      assignedOfficialsText = report["all_assigned_officials"].first;
    } else {
      assignedOfficialsText = report["all_assigned_officials"].join(", ");
    }

    return "Good day! Department of Public Services,\n\n"
        "I am writing to escalate the following report that requires urgent attention:\n\n"
        "Report ID: ${report["report_id"]}\n"
        "Reporter Name: ${report["reporter_name"]}\n"
        "Submission Date: $submissionDate\n"
        "Report Deadline: $deadlineDate\n"
        "Current Status: ${report["status"]}\n"
        "Assigned Official(s): $assignedOfficialsText\n\n"
        "This report $statusContext. Please prioritize this matter and provide an update on the resolution plan.\n\n"
        "Thank you for your immediate attention to this matter.\n\n"
        "Sincerely,\n"
        "[Your Name]";
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 760;

    final pendingCount = _reports.where((r) => r["status"] == "Pending").length;
    final inProgressCount =
        _reports.where((r) => r["status"] == "In Progress").length;
    final resolvedCount =
        _reports.where((r) => r["status"] == "Resolved").length;

    final totalReports = _reports.length;
    final nearDeadlineReports = _reports
    .where((r) =>
        r["report_deadline"].difference(_now).inHours <= 24 &&
        r["report_deadline"].isAfter(_now) &&
        r["status"] != "Resolved") // Exclude resolved reports
    .toList();

    final expiredReports = _reports
      .where((r) => r["report_deadline"].isBefore(_now) && r["status"] != "Resolved") // Exclude resolved
      .toList();

    final start = _currentPage * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, _filteredReports.length);
    final pageReports = _filteredReports.sublist(start, end);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics Row
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 900;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          SizedBox(
                            width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 32) / 3,
                            child: _metricCard(
                              controller: _totalAnimCtrl,
                              icon: Icons.bar_chart,
                              title: "Total Reports",
                              value: totalReports,
                              subtitle: "All reports submitted",
                              color: Colors.purple,
                              progress: totalReports == 0 ? 0 : 1,
                              onTap: () => setState(() {
                                _statusFilter = null;
                                _specialFilter = null;
                                _resetPagination();
                              }),
                            ),
                          ),
                          SizedBox(
                            width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 32) / 3,
                            child: _metricCard(
                              controller: _deadlineAnimCtrl,
                              icon: Icons.alarm,
                              title: "Near Deadline",
                              value: nearDeadlineReports.length,
                              subtitle: nearDeadlineReports.isNotEmpty
                                  ? "Next: ${_formatDuration(nearDeadlineReports.first["report_deadline"].difference(_now), nearDeadlineReports.first["status"])}"
                                  : "No reports near deadline",
                              color: Colors.red,
                              progress: totalReports == 0
                                  ? 0
                                  : nearDeadlineReports.length / totalReports,
                              onTap: () => setState(() {
                                _statusFilter = null;
                                _specialFilter = "NearDeadline";
                                _sortBy = "Deadline Asc";
                                _resetPagination();
                              }),
                            ),
                          ),
                          SizedBox(
                            width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 32) / 3,
                            child: _metricCard(
                              controller: _expiredAnimCtrl,
                              icon: Icons.close,
                              title: "Expired",
                              value: expiredReports.length,
                              subtitle: "Reports past deadline",
                              color: Colors.black87,
                              progress: totalReports == 0
                                  ? 0
                                  : expiredReports.length / totalReports,
                              onTap: () => setState(() {
                                _statusFilter = null;
                                _specialFilter = "Expired";
                                _sortBy = "Deadline Desc";
                                _resetPagination();
                              }),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Status summary Row
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 900;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: [
                          SizedBox(
                            width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 32) / 3,
                            child: _metricCard(
                              controller: _pendingAnimCtrl,
                              icon: Icons.pending_actions,
                              title: "Pending",
                              value: pendingCount,
                              subtitle: "Waiting to be processed",
                              color: Colors.orange,
                              progress: totalReports == 0 ? 0 : pendingCount / totalReports,
                              onTap: () => setState(() {
                                _statusFilter = "Pending";
                                _specialFilter = null; // clear special filter
                                _resetPagination();
                              }),
                            ),
                          ),
                          SizedBox(
                            width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 32) / 3,
                            child: _metricCard(
                              controller: _progressAnimCtrl,
                              icon: Icons.autorenew,
                              title: "In Progress",
                              value: inProgressCount,
                              subtitle: "Currently being handled",
                              color: Colors.blue,
                              progress: totalReports == 0 ? 0 : inProgressCount / totalReports,
                              onTap: () => setState(() {
                                _statusFilter = "In Progress";
                                _specialFilter = null; // clear special filter
                                _resetPagination();
                              }),
                            ),
                          ),
                          SizedBox(
                            width: isNarrow ? constraints.maxWidth : (constraints.maxWidth - 32) / 3,
                            child: _metricCard(
                              controller: _resolvedAnimCtrl,
                              icon: Icons.check_circle,
                              title: "Resolved",
                              value: resolvedCount,
                              subtitle: "Marked as resolved",
                              color: Colors.green,
                              progress: totalReports == 0 ? 0 : resolvedCount / totalReports,
                              onTap: () => setState(() {
                                _statusFilter = "Resolved";
                                _specialFilter = null; // clear special filter
                                _resetPagination();
                              }),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Search + Filters
                LayoutBuilder(builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 800;
                  return Wrap(
                    runSpacing: 12,
                    spacing: 16,
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: isNarrow ? constraints.maxWidth : 350,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Search by ID, Name, or Official...",
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onChanged: (val) =>
                              setState(() => _searchQuery = val.trim()),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _sortBy,
                            items: const [
                              DropdownMenuItem(
                                  value: "Deadline Asc",
                                  child: Text("Sort by Deadline ↑")),
                              DropdownMenuItem(
                                  value: "Deadline Desc",
                                  child: Text("Sort by Deadline ↓")),
                              DropdownMenuItem(
                                  value: "A-Z", child: Text("Sort by Name A-Z")),
                            ],
                            onChanged: (val) => setState(() => _sortBy = val!),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _statusFilter,
                            hint: const Text("Filter Status"),
                            items: const [
                              DropdownMenuItem(value: "Pending", child: Text("Pending")),
                              DropdownMenuItem(value: "In Progress", child: Text("In Progress")),
                              DropdownMenuItem(value: "Resolved", child: Text("Resolved")),
                            ],
                            onChanged: (val) => setState(() => _statusFilter = val),
                          ),
                        ),
                      ),
                      if (_statusFilter != null)
                        TextButton.icon(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _statusFilter = null),
                          label: const Text("Clear Filter"),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 16),

                // Table with pagination footer inside card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 1200),
                          child: DataTable(
                            columnSpacing: 28,
                            headingRowHeight: 56,
                            dataRowHeight: 56,
                            headingTextStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            columns: const [
                              DataColumn(label: Text('ID'), numeric: true),
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Submission Date')),
                              DataColumn(label: Text('Report Deadline')),
                              DataColumn(label: Text('Time Remaining')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Assigned Official')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: pageReports.map((report) {
                              final submission = report["submission_date"] as DateTime;
                              final deadline = report["report_deadline"] as DateTime;
                              final timeRemaining = deadline.difference(_now);
                              final isResolved = report["status"] == "Resolved";

                              return DataRow(
                                color: WidgetStateProperty.all(_rowColor(report)),
                                cells: [
                                  DataCell(Center(
                                      child: Text(report["report_id"].toString()))),
                                  DataCell(Text(report["reporter_name"])),
                                  DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(submission))),
                                  DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(deadline))),
                                  DataCell(Row(
                                  children: [
                                    if (timeRemaining.inHours <= 24 && 
                                        !timeRemaining.isNegative && 
                                        report["status"] != "Resolved")
                                      const Tooltip(
                                        message: "Near Deadline",
                                        child: Icon(Icons.notifications_active, size: 16, color: Colors.red),
                                      ),
                                    const SizedBox(width: 4),
                                    Text(_formatDuration(timeRemaining, report["status"])),
                                  ],
                                )),
                                  DataCell(_statusChip(report["status"])),
                                  DataCell(
                                    Tooltip(
                                      message: report["all_assigned_officials"].join("\n"),
                                      child: Text(
                                        report["assignment_count"] > 1 
                                            ? "Official (${report["assignment_count"]})" 
                                            : report["assigned_official"],
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    isResolved 
                                      ? const SizedBox.shrink()
                                      : IconButton(
                                          icon: const Icon(Icons.warning_amber, color: Colors.red),
                                          tooltip: "Escalate Report",
                                          onPressed: () => _showEscalationDialog(report),
                                        ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Showing ${start + 1}-$end of ${_filteredReports.length}"),
                            Row(
                              children: [
                                DropdownButton<int>(
                                  value: _rowsPerPage,
                                  items: const [
                                    DropdownMenuItem(value: 5, child: Text("5")),
                                    DropdownMenuItem(value: 10, child: Text("10")),
                                    DropdownMenuItem(value: 15, child: Text("15")),
                                    DropdownMenuItem(value: 20, child: Text("20")),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _rowsPerPage = val;
                                        _currentPage = 0;
                                      });
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _currentPage > 0
                                      ? () => setState(() => _currentPage--)
                                      : null,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: end < _filteredReports.length
                                      ? () => setState(() => _currentPage++)
                                      : null,
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    switch (status) {
      case "Pending":
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade800;
        break;
      case "In Progress":
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade800;
        break;
      case "Resolved":
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        break;
      default:
        bg = Colors.grey.shade200;
        fg = Colors.black87;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _metricCard({
    required AnimationController controller,
    required IconData icon,
    required String title,
    required int value,
    required String subtitle,
    required Color color,
    required double progress,
    VoidCallback? onTap,
  }) {
    final animation = IntTween(begin: 0, end: value).animate(controller);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.6)], // soft gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Stack(
          children: [
            // Faded background icon
            Positioned(
              right: -4,
              top: -4,
              child: Icon(
                icon,
                size: 60,
                color: Colors.white.withOpacity(0.15), // subtle white overlay
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Text(
                      animation.value.toString(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    color: Colors.white,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}