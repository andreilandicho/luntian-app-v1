// lib/screen/admin/threshold_report_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class ThresholdReportPage extends StatefulWidget {
  const ThresholdReportPage({super.key});

  @override
  State<ThresholdReportPage> createState() => _ThresholdReportPageState();
}

class _ThresholdReportPageState extends State<ThresholdReportPage>
    with TickerProviderStateMixin {
    final List<Map<String, dynamic>> _reports = [
    {
      "report_id": 1,
      "reporter_name": "Juan Dela Cruz",
      "submission_date": DateTime(2025, 9, 1, 10, 30),
      "report_deadline": DateTime(2025, 9, 3, 17, 0),
      "status": "Pending",
      "assigned_official": "Juan Dela Cruz"
    },
    {
      "report_id": 2,
      "reporter_name": "Maria Santos",
      "submission_date": DateTime(2025, 9, 2, 14, 0),
      "report_deadline": DateTime(2025, 9, 5, 17, 0),
      "status": "In Progress",
      "assigned_official": "Maria Santos"
    },
    {
      "report_id": 3,
      "reporter_name": "Pedro Lopez",
      "submission_date": DateTime(2025, 9, 3, 9, 0),
      "report_deadline": DateTime(2025, 9, 4, 12, 0),
      "status": "Resolved",
      "assigned_official": "Pedro Lopez"
    },
    {
      "report_id": 4,
      "reporter_name": "Ana Cruz",
      "submission_date": DateTime(2025, 8, 25, 9, 0),
      "report_deadline": DateTime(2025, 8, 28, 12, 0),
      "status": "Pending",
      "assigned_official": "Ana Cruz"
    },
    {
      "report_id": 5,
      "reporter_name": "Mark Reyes",
      "submission_date": DateTime(2025, 8, 30, 15, 45),
      "report_deadline": DateTime(2025, 9, 2, 10, 0),
      "status": "In Progress",
      "assigned_official": "Mark Reyes"
    },
    {
      "report_id": 6,
      "reporter_name": "Liza Manalo",
      "submission_date": DateTime(2025, 9, 2, 11, 30),
      "report_deadline": DateTime(2025, 9, 6, 17, 0),
      "status": "Resolved",
      "assigned_official": "Liza Manalo"
    },
    {
      "report_id": 7,
      "reporter_name": "Carlo Aquino",
      "submission_date": DateTime(2025, 9, 1, 8, 15),
      "report_deadline": DateTime(2025, 9, 2, 18, 0),
      "status": "Pending",
      "assigned_official": "Carlo Aquino"
    },
    {
      "report_id": 8,
      "reporter_name": "Nina Torres",
      "submission_date": DateTime(2025, 9, 3, 7, 20),
      "report_deadline": DateTime(2025, 9, 7, 17, 0),
      "status": "In Progress",
      "assigned_official": "Nina Torres"
    },
    {
      "report_id": 9,
      "reporter_name": "Jose Rizal",
      "submission_date": DateTime(2025, 8, 20, 9, 0),
      "report_deadline": DateTime(2025, 8, 22, 17, 0),
      "status": "Resolved",
      "assigned_official": "Jose Rizal"
    },
    {
      "report_id": 10,
      "reporter_name": "Andres Bonifacio",
      "submission_date": DateTime(2025, 9, 1, 12, 0),
      "report_deadline": DateTime(2025, 9, 4, 17, 0),
      "status": "Pending",
      "assigned_official": "Andres Bonifacio"
    },
    {
      "report_id": 11,
      "reporter_name": "Emilio Aguinaldo",
      "submission_date": DateTime(2025, 9, 2, 9, 45),
      "report_deadline": DateTime(2025, 9, 6, 15, 0),
      "status": "In Progress",
      "assigned_official": "Emilio Aguinaldo"
    },
    {
      "report_id": 12,
      "reporter_name": "Apolinario Mabini",
      "submission_date": DateTime(2025, 8, 28, 14, 0),
      "report_deadline": DateTime(2025, 8, 30, 10, 0),
      "status": "Pending",
      "assigned_official": "Apolinario Mabini"
    },
    {
      "report_id": 13,
      "reporter_name": "Melchora Aquino",
      "submission_date": DateTime(2025, 9, 2, 16, 0),
      "report_deadline": DateTime(2025, 9, 5, 18, 0),
      "status": "Resolved",
      "assigned_official": "Melchora Aquino"
    },
    {
      "report_id": 14,
      "reporter_name": "Antonio Luna",
      "submission_date": DateTime(2025, 9, 3, 10, 0),
      "report_deadline": DateTime(2025, 9, 3, 23, 59),
      "status": "Pending",
      "assigned_official": "Antonio Luna"
    },
    {
      "report_id": 15,
      "reporter_name": "Gregorio del Pilar",
      "submission_date": DateTime(2025, 8, 31, 9, 30),
      "report_deadline": DateTime(2025, 9, 2, 17, 0),
      "status": "In Progress",
      "assigned_official": "Gregorio del Pilar"
    },
    {
      "report_id": 16,
      "reporter_name": "Diego Silang",
      "submission_date": DateTime(2025, 9, 1, 14, 0),
      "report_deadline": DateTime(2025, 9, 8, 12, 0),
      "status": "Resolved",
      "assigned_official": "Diego Silang"
    },
    {
      "report_id": 17,
      "reporter_name": "Gabriela Silang",
      "submission_date": DateTime(2025, 9, 2, 15, 30),
      "report_deadline": DateTime(2025, 9, 9, 17, 0),
      "status": "Pending",
      "assigned_official": "Gabriela Silang"
    },
    {
      "report_id": 18,
      "reporter_name": "Daniel Padilla",
      "submission_date": DateTime(2025, 9, 3, 11, 15),
      "report_deadline": DateTime(2025, 9, 4, 11, 0),
      "status": "In Progress",
      "assigned_official": "Daniel Padilla"
    },
    {
      "report_id": 19,
      "reporter_name": "Kathryn Bernardo",
      "submission_date": DateTime(2025, 8, 27, 10, 30),
      "report_deadline": DateTime(2025, 8, 29, 17, 0),
      "status": "Resolved",
      "assigned_official": "Kathryn Bernardo"
    },
    {
      "report_id": 20,
      "reporter_name": "Vice Ganda",
      "submission_date": DateTime(2025, 9, 1, 13, 0),
      "report_deadline": DateTime(2025, 9, 3, 23, 59),
      "status": "Pending",
      "assigned_official": "Vice Ganda"
    },
  ];

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

  String _formatDuration(Duration d) {
    if (d.isNegative) return "Expired";
    return "${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s";
  }

  Color _rowColor(Map<String, dynamic> report) {
    final timeRemaining = report["report_deadline"].difference(_now);
    if (timeRemaining.inHours <= 24 && !timeRemaining.isNegative) {
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
  if (_specialFilter == "NearDeadline") {
    list = list.where((r) {
      final d = r["report_deadline"] as DateTime;
      final diff = d.difference(_now);
      return diff.inHours <= 24 && diff > Duration.zero; // deadline within 24h and still future
    }).toList();
  } else if (_specialFilter == "Expired") {
    list = list.where((r) {
      final d = r["report_deadline"] as DateTime;
      return d.isBefore(_now);
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
            r["report_deadline"].isAfter(_now))
        .toList();
    final expiredReports =
        _reports.where((r) => r["report_deadline"].isBefore(_now)).toList();

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
                                ? "Next: ${_formatDuration(nearDeadlineReports.first["report_deadline"].difference(_now))}"
                                : "No reports near deadline",
                            color: Colors.red,
                            progress: totalReports == 0
                                ? 0
                                : nearDeadlineReports.length / totalReports,
                            onTap: () => setState(() {
                              _statusFilter = null;
                              _specialFilter = "NearDeadline";
                              _sortBy = "Deadline Asc";
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
                            ],
                            rows: pageReports.map((report) {
                              final submission = report["submission_date"] as DateTime;
                              final deadline = report["report_deadline"] as DateTime;
                              final timeRemaining = deadline.difference(_now);

                              return DataRow(
                                color: MaterialStateProperty.all(_rowColor(report)),
                                cells: [
                                  DataCell(Center(
                                      child: Text(report["report_id"].toString()))),
                                  DataCell(Text(report["reporter_name"])),
                                  DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(submission))),
                                  DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(deadline))),
                                  DataCell(Row(
                                    children: [
                                      if (timeRemaining.inHours <= 24 &&
                                          !timeRemaining.isNegative)
                                        const Tooltip(
                                            message: "Near Deadline",
                                            child: Icon(Icons.notifications_active,
                                                size: 16, color: Colors.red)),
                                      const SizedBox(width: 4),
                                      Text(_formatDuration(timeRemaining)),
                                    ],
                                  )),
                                  DataCell(_statusChip(report["status"])),
                                  DataCell(Text(report["assigned_official"])),
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
                            Text("Showing ${start + 1}-${end} of ${_filteredReports.length}"),
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

