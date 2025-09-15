// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/screen/admin/notification_screen.dart';
import 'package:flutter_application_1/screen/admin/profile_screen.dart';
import 'package:flutter_application_1/screen/admin/login_screen.dart';
import 'package:flutter_application_1/screen/admin/pending.dart';
import 'package:flutter_application_1/screen/admin/inprogress.dart';
import 'package:flutter_application_1/screen/admin/resolved.dart';
import 'package:flutter_application_1/screen/admin/request_screen.dart';
import 'package:flutter_application_1/screen/admin/threshold.dart';
import 'package:flutter_application_1/screen/admin/leaderboard.dart';


void main() {
  runApp(const LuntianAdminApp());
}

class LuntianAdminApp extends StatelessWidget {
  const LuntianAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Luntian Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF328E6E),
        scaffoldBackgroundColor: const Color(0xFFF3F7F6),
        fontFamily: 'Poppins',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AdminDashboard(),
    );
  }
}

class AdminDashboard extends StatefulWidget {
  final int initialTab;

  const AdminDashboard({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with TickerProviderStateMixin {
  // Sidebar
  final bool _collapsed = false;
  static const double sidebarWidth = 260;
  static const double sidebarCollapsedWidth = 72;

  String? _hoveredCard; // track which card is hovered

  // Nav
  late int _selectedNav;
  int _unreadCount = 0;

  // Counts for the pie (updated by the date-range filter)
int _pending = 0;
int _inProgress = 0;
int _resolved = 0;

String? _selectedFilter; 
DateTimeRange? _selectedDateRange;

final List<Map<String, dynamic>> _reports = [
  {"date": DateTime(2025, 8, 1), "status": "pending", "critical": true, "priority": "High"},
  {"date": DateTime(2025, 8, 1), "status": "pending", "critical": false, "priority": "Medium"},
  {"date": DateTime(2025, 8, 2), "status": "inProgress", "critical": false, "priority": "Low"},
  {"date": DateTime(2025, 8, 2), "status": "inProgress", "critical": true, "priority": "High"},
  {"date": DateTime(2025, 8, 2), "status": "resolved", "critical": false, "priority": "Medium"},
  {"date": DateTime(2025, 8, 3), "status": "pending", "critical": false, "priority": "Low"},
  {"date": DateTime(2025, 8, 3), "status": "resolved", "critical": true, "priority": "High"},
  {"date": DateTime(2025, 8, 3), "status": "resolved", "critical": false, "priority": "Medium"},
  {"date": DateTime(2025, 8, 4), "status": "pending", "critical": true, "priority": "High"},
  {"date": DateTime(2025, 8, 4), "status": "inProgress", "critical": false, "priority": "Low"},
  {"date": DateTime(2025, 8, 4), "status": "resolved", "critical": false, "priority": "Medium"},
  {"date": DateTime(2025, 8, 5), "status": "pending", "critical": false, "priority": "Medium"},
  {"date": DateTime(2025, 8, 5), "status": "pending", "critical": true, "priority": "High"},
  {"date": DateTime(2025, 8, 5), "status": "inProgress", "critical": false, "priority": "Low"},
  {"date": DateTime(2025, 8, 5), "status": "resolved", "critical": false, "priority": "Medium"},
  {"date": DateTime(2025, 8, 6), "status": "pending", "critical": false, "priority": "Low"},
  {"date": DateTime(2025, 8, 6), "status": "pending", "critical": true, "priority": "High"},
  {"date": DateTime(2025, 8, 6), "status": "inProgress", "critical": false, "priority": "Medium"},
  {"date": DateTime(2025, 8, 6), "status": "resolved", "critical": true, "priority": "High"},
  {"date": DateTime(2025, 8, 7), "status": "pending", "critical": false, "priority": "Medium"},
  {"date": DateTime(2025, 8, 7), "status": "inProgress", "critical": false, "priority": "Low"},
  {"date": DateTime(2025, 8, 7), "status": "resolved", "critical": false, "priority": "Medium"},
  {"date": DateTime(2025, 8, 8), "status": "pending", "critical": true, "priority": "High"},
  {"date": DateTime(2025, 8, 8), "status": "pending", "critical": false, "priority": "Medium"},
  {"date": DateTime(2025, 8, 8), "status": "inProgress", "critical": true, "priority": "High"},
  {"date": DateTime(2025, 8, 8), "status": "resolved", "critical": false, "priority": "Low"},
  {"date": DateTime(2025, 8, 9), "status": "pending", "critical": false, "priority": "Medium"},
  {"date": DateTime(2025, 8, 9), "status": "inProgress", "critical": false, "priority": "Low"},
  {"date": DateTime(2025, 8, 9), "status": "resolved", "critical": true, "priority": "High"},
  {"date": DateTime(2025, 8, 10), "status": "pending", "critical": true, "priority": "High"},
  {"date": DateTime(2025, 8, 10), "status": "pending", "critical": false, "priority": "Medium"},
  {"date": DateTime(2025, 8, 10), "status": "inProgress", "critical": false, "priority": "Low"},
  {"date": DateTime(2025, 8, 10), "status": "resolved", "critical": false, "priority": "Medium"},
  {"date": DateTime(2025, 8, 11), "status": "pending", "critical": true, "priority": "High"},
  {"date": DateTime(2025, 8, 11), "status": "inProgress", "critical": false, "priority": "Low"},
  {"date": DateTime(2025, 8, 11), "status": "resolved", "critical": false, "priority": "Medium"},
  {"date": DateTime(2025, 9, 1), "status": "pending", "critical": true, "priority": "High"},
  {"date": DateTime(2025, 9, 1), "status": "pending", "critical": false, "priority": "Medium"},
  {"date": DateTime(2025, 9, 2), "status": "inProgress", "critical": false, "priority": "Low"},
  {"date": DateTime(2025, 9, 2), "status": "inProgress", "critical": true, "priority": "High"},
  {"date": DateTime(2025, 9, 2), "status": "resolved", "critical": false, "priority": "Medium"},
];

// Multi-select priorities (field)
  final Set<String> _selectedPriorities = {}; // 'High', 'Medium', 'Low'

  // Hazardous filter
  bool? _hazardousOnly;

  // --- Update dashboard counts based on filters ---
  void _updateDataForRange([DateTimeRange? range]) {
    // Start with all reports
    var filtered = _reports;

    // 1️⃣ Apply date filter if provided
    if (range != null) {
      filtered = filtered.where((r) {
        final d = r["date"] as DateTime;
        return !d.isBefore(range.start) && !d.isAfter(range.end);
      }).toList();
    }

    // 2️⃣ Apply priority filter (multi-select)
    if (_selectedPriorities.isNotEmpty) {
      filtered =
          filtered.where((r) => _selectedPriorities.contains(r["priority"])).toList();
    }

    // 3️⃣ Apply hazardous filter (null = all, true = only critical, false = non-critical)
    if (_hazardousOnly != null) {
      filtered = filtered.where((r) => r["critical"] == _hazardousOnly).toList();
    }

    // 4️⃣ Count statuses
    final pending = filtered.where((r) => r["status"] == "pending").length;
    final inProgress = filtered.where((r) => r["status"] == "inProgress").length;
    final resolved = filtered.where((r) => r["status"] == "resolved").length;

    // 5️⃣ Update state
    setState(() {
      _pending = pending;
      _inProgress = inProgress;
      _resolved = resolved;

      // Restart pie chart animation
      _pieController.reset();
      _pieController.forward();
    });
  }

  // Date & time
  Timer? _clockTimer;
  String _liveTime = '';

  // Colors
  final Color sidebarColor = const Color(0xFF328E6E);

  // Animation
  late AnimationController _pieController;
  late Animation<double> _pendingAnim;
  late Animation<double> _inProgressAnim;
  late Animation<double> _resolvedAnim;

@override
void initState() {
  super.initState();
  _startClock();
  _pieController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  _pendingAnim = CurvedAnimation(
    parent: _pieController,
    curve: const Interval(0.0, 0.33, curve: Curves.easeOutCubic),
  );
  _inProgressAnim = CurvedAnimation(
    parent: _pieController,
    curve: const Interval(0.33, 0.66, curve: Curves.easeOutCubic),
  );
  _resolvedAnim = CurvedAnimation(
    parent: _pieController,
    curve: const Interval(0.66, 1.0, curve: Curves.easeOutCubic),
  );

  _updateDataForRange(); // <-- show all dates initially
  _selectedNav = widget.initialTab;
}

  void _startClock() {
    _liveTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _liveTime = DateFormat('hh:mm:ss a').format(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _pieController.dispose();
    super.dispose();
  }

  bool _isSmall(double width) => width < 760;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final autoCollapse = _isSmall(width);
        final effectiveCollapsed = autoCollapse ? true : _collapsed;
        final sWidth =
            effectiveCollapsed ? sidebarCollapsedWidth : sidebarWidth;

        return Scaffold(
          drawer: _isSmall(width)
              ? Drawer(
                  backgroundColor: sidebarColor,
                  child: SafeArea(
                    child: _buildSidebarContent(collapsed: false),
                  ),
                )
              : null,
          body: Column(
            children: [
              if (_isSmall(width))
                Container(
                  color: sidebarColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: Row(
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'LUNTIAN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontFamily: 'Marykate',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Row(
                  children: [
                    if (!_isSmall(width))
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        width: sWidth,
                        curve: Curves.easeInOut,
                        color: sidebarColor,
                        child: SafeArea(
                          child: _buildSidebarContent(
                              collapsed: effectiveCollapsed),
                        ),
                      ),
                    Expanded(
                      child: SafeArea(
                        child: _buildMainContent(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

Widget _buildSidebarContent({required bool collapsed}) {
  return Column(
    children: [
      // --- Logo ---
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              height: 44,
              width: 44,
              child: Image.asset('assets/logo only luntian.png',
                  fit: BoxFit.contain),
            ),
            if (!collapsed) ...[
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'LUNTIAN',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Marykate',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
      ),

      // --- Navigation items ---
      _modernNavTile(
          icon: Symbols.dashboard,
          label: 'Dashboard',
          index: 0,
          collapsed: collapsed),
      _modernNavTile(
          icon: Symbols.report,
          label: 'Threshold Report',
          index: 7,
          collapsed: collapsed),
      _modernNavTile(
          icon: Symbols.person_add,
          label: 'Add Official',
          index: 6,
          collapsed: collapsed),
      _modernNavTile(
          icon: Symbols.leaderboard,
          label: 'Leaderboard',
          index: 8,
          collapsed: collapsed),
      _modernNavTile(
          icon: Symbols.notifications,
          label: 'Notifications',
          index: 1,
          collapsed: collapsed,
          badgeCount: _unreadCount),
      _modernNavTile(
          icon: Symbols.person,
          label: 'Profile',
          index: 2,
          collapsed: collapsed),

      const Spacer(),

      // --- Log out button ---
      Padding(
        padding: const EdgeInsets.all(12.0),
        child: InkWell(
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: Colors.green[700]),
                if (!collapsed) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Log out',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

// --- Modern Nav Tile with active indicator + fade ---
Widget _modernNavTile({
  required IconData icon,
  required String label,
  required int index,
  required bool collapsed,
  int? badgeCount,
}) {
  final bool selected = _selectedNav == index;

  return InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () => setState(() => _selectedNav = index),
    child: Stack(
      children: [
        // --- Active indicator ---
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          left: 0,
          top: 0,
          bottom: 0,
          width: selected ? 4 : 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
            ),
          ),
        ),

        // --- Tile content ---
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding:
              EdgeInsets.symmetric(horizontal: collapsed ? 0 : 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment:
                collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white),
              if (!collapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: collapsed ? 0 : 1,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
              if (badgeCount != null && badgeCount > 0)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildMainContent() {
    switch (_selectedNav) {
      case 0:
        return _dashboardContent(context);
      case 1:
        return NotificationPage(
          onUnreadChanged: (unread) {
            if (unread != _unreadCount) {
              setState(() => _unreadCount = unread);
            }
          },
        );
      case 2:
        return const ProfilePage();
      case 3:
        return const PendingPage();
      case 4:
        return const InProgressPage();
      case 5:
        return const ResolvedPage();
      case 6:
        return const OfficialsDashboardPage();
      case 7:
        return const ThresholdReportPage();
      case 8:
        return const LeaderboardPage();
      default:
        return _dashboardContent(context);
    }
  }

Widget _dashboardContent(BuildContext context) {
  final height = MediaQuery.of(context).size.height;
  const contentPadding = EdgeInsets.all(18.0);

  final total = _pending + _inProgress + _resolved;

  return Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: contentPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height - 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 🔹 Header with date & clock
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DASHBOARD',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Marykate',
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat.yMMMMd().format(DateTime.now()),
                            style: const TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.access_time_outlined,
                                  size: 16, color: Colors.black54),
                              const SizedBox(width: 6),
                              Text(
                                _liveTime,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                _alertsCard(),
                const SizedBox(height: 18),

                // 🔹 STAT CARDS (responsive)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cards = [
                      _statCard(
                        "Pending",
                        _pending,
                        total,
                        Colors.red.shade500,
                        Icons.pending,
                      ),
                      _statCard(
                        "In Progress",
                        _inProgress,
                        total,
                        Colors.yellow.shade600,
                        Icons.work_outline,
                      ),
                      _statCard(
                        "Resolved",
                        _resolved,
                        total,
                        Colors.green.shade600,
                        Icons.check,
                      ),
                    ];

                    if (constraints.maxWidth < 760) {
                      // Small screens: stack vertically
                      return Column(
                        children: cards
                            .map((c) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: c,
                                ))
                            .toList(),
                      );
                    } else {
                      // Large screens: row
                      return Row(
                        children: List.generate(cards.length, (index) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: index == cards.length - 1 ? 0 : 12, // no padding on last card
                              ),
                              child: cards[index],
                            ),
                          );
                        }),
                      );
                    }
                  },
                ),

                const SizedBox(height: 24),

                // 🔹 PIE CHART
                _pieCard(),
              ],
            )
          ),
        ),
      ),
    ],
  );
}

Widget _alertsCard() {
  final overdue = _reports
      .where((r) =>
          r["status"] == "pending" &&
          r["date"].isBefore(DateTime.now().subtract(const Duration(days: 3))))
      .length;

  final pendingThreshold = 5;
  final pendingOverThreshold = _pending > pendingThreshold ? _pending : 0;

  final criticalAlerts = _reports
      .where((r) => r["status"] == "pending" && r["critical"] == true)
      .length;

  final List<Map<String, dynamic>> alerts = [
    {
      "label": "Overdue",
      "value": overdue,
      "icon": Icons.schedule,
      "color": Colors.red,
      "isCritical": false
    },
    {
      "label": "Pending > $pendingThreshold",
      "value": pendingOverThreshold,
      "icon": Icons.pending_actions,
      "color": Colors.amber,
      "isCritical": false
    },
    {
      "label": "Critical",
      "value": criticalAlerts,
      "icon": Icons.warning_amber_rounded,
      "color": Colors.deepOrange,
      "isCritical": true
    },
  ];

  return MouseRegion(
    onEnter: (_) => setState(() => _hoveredCard = "AlertsCard"),
    onExit: (_) => setState(() => _hoveredCard = null),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      transform: (_hoveredCard == "AlertsCard"
          ? (Matrix4.identity()..translate(0.0, -4.0, 0.0))
          : Matrix4.identity()),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: _hoveredCard == "AlertsCard"
                ? Colors.black26
                : Colors.black12,
            blurRadius: _hoveredCard == "AlertsCard" ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: alerts.map((alert) {
            final isCritical = alert["isCritical"] as bool;
            return Column(
              children: [
                CircleAvatar(
                  radius: isCritical ? 30 : 24,
                  backgroundColor: (alert["color"] as Color).withOpacity(0.15),
                  child: Icon(
                    alert["icon"] as IconData,
                    color: alert["color"] as Color,
                    size: isCritical ? 32 : 28,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  alert["label"] as String,
                  style: TextStyle(
                      fontWeight:
                          isCritical ? FontWeight.bold : FontWeight.w600,
                      fontSize: isCritical ? 14 : 13,
                      color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                Text(
                  (alert["value"] as int).toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isCritical ? 20 : 18,
                    color: alert["color"] as Color,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    ),
  );
}

Widget _statCard(String label, int value, int total, Color color, IconData icon) {
  final percent = total > 0 ? ((value / total) * 100).toStringAsFixed(0) : '0';

  return GestureDetector(
    onTap: () {
      // Navigate or filter based on the card label
      setState(() {
        if (label == "Pending") _selectedNav = 3;
        if (label == "In Progress") _selectedNav = 4;
        if (label == "Resolved") _selectedNav = 5;
      });
    },
    child: MouseRegion(
      onEnter: (_) => setState(() => _hoveredCard = label),
      onExit: (_) => setState(() => _hoveredCard = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: (_hoveredCard == label
            ? (Matrix4.identity()..translate(0.0, -4.0, 0.0))
            : Matrix4.identity()) as Matrix4?,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: _hoveredCard == label ? color.withOpacity(0.35) : Colors.black12,
              blurRadius: _hoveredCard == label ? 12 : 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon circle
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.7), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              Text(
                "$value ($percent%)",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: total > 0 ? value / total : 0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _pieCard() {
  final total = (_pending + _inProgress + _resolved).toDouble();

  // --- Empty state ---
  if (total == 0) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: SizedBox(
        height: 260,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
              const SizedBox(height: 12),
              const Text(
                "No reports yet. Everything looks good!",
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final pPending = (_pending / total) * 100;
  final pInProgress = (_inProgress / total) * 100;
  final pResolved = (_resolved / total) * 100;

  return MouseRegion(
    onEnter: (_) {
      setState(() => _hoveredCard = "PieChart");
      _pieController.forward(from: 0);
    },
    onExit: (_) => setState(() => _hoveredCard = null),
    child: AnimatedBuilder(
      animation: _pieController,
      builder: (context, child) {
        final animatedPending = pPending * _pendingAnim.value;
        final animatedInProgress = pInProgress * _inProgressAnim.value;
        final animatedResolved = pResolved * _resolvedAnim.value;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: (_hoveredCard == "PieChart"
              ? (Matrix4.identity()..translate(0.0, -4.0, 0.0))
              : Matrix4.identity()),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: _hoveredCard == "PieChart"
                    ? Colors.green.withOpacity(0.25)
                    : Colors.black12,
                blurRadius: _hoveredCard == "PieChart" ? 12 : 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header with title + filter pills ---
                LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Reports Overview",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedDateRange != null
                            ? "Filtered: ${DateFormat.yMMMd().format(_selectedDateRange!.start)} - ${DateFormat.yMMMd().format(_selectedDateRange!.end)}"
                            : "Showing All Reports",
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      // Only this row handles both filters + priority
                      _filterAndPriorityRow(),
                    ],
                  );
                },
              ),
                const SizedBox(height: 20),

                // --- Animated Pie Chart with KPI inside ---
                SizedBox(
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 80,
                          sections: [
                            PieChartSectionData(
                              color: Colors.redAccent,
                              value: animatedPending,
                              title: "${animatedPending.toStringAsFixed(0)}%",
                              radius: 60,
                              titleStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14),
                            ),
                            PieChartSectionData(
                              color: Colors.amber,
                              value: animatedInProgress,
                              title: "${animatedInProgress.toStringAsFixed(0)}%",
                              radius: 60,
                              titleStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14),
                            ),
                            PieChartSectionData(
                              color: Colors.green,
                              value: animatedResolved,
                              title: "${animatedResolved.toStringAsFixed(0)}%",
                              radius: 60,
                              titleStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Total",
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500)),
                          Text(
                            total.toInt().toString(),
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // --- Legend at bottom ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _legendDot("Pending", Colors.redAccent),
                    _legendDot("In Progress", Colors.amber),
                    _legendDot("Resolved", Colors.green),
                  ],
                )
              ],
            ),
          ),
        );
      },
    ),
  );
}

// --- Custom Date Range Pill ---
Widget _customDateRangePill() {
  final bool selected = _selectedFilter == 'custom';
  return GestureDetector(
    onTap: () async {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        initialDateRange: _selectedDateRange,
      );
      if (picked != null) {
        setState(() {
          _selectedFilter = 'custom';
          _selectedDateRange = picked;
          _updateDataForRange(_selectedDateRange);
        });
      }
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.blue : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        boxShadow: selected
            ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 6)]
            : [],
      ),
      child: Text(
        "Custom Range",
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// --- Combined Filter + Priority Pills ---
Widget _filterAndPriorityRow() {
  final filters = [
    {'label': 'Weekly', 'value': 'weekly'},
    {'label': 'Monthly', 'value': 'monthly'},
    {'label': 'Yearly', 'value': 'yearly'},
  ];

  final priorities = ['High', 'Medium', 'Low'];

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        // --- Date filters ---
        ...filters.map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _filterPill(f['label']!, f['value']!),
            )),
        // --- Custom range ---
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _customDateRangePill(),
        ),
        // --- Priority pills ---
        ...priorities.map((p) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _priorityPill(p),
            )),
      ],
    ),
  );
}

// --- Priority styled like filter pill ---
Widget _priorityPill(String priority) {
  final bool selected = _selectedPriorities.contains(priority);
  Color color;
  switch (priority) {
    case 'High':
      color = Colors.red.shade400;
      break;
    case 'Medium':
      color = Colors.amber.shade600;
      break;
    case 'Low':
      color = Colors.green.shade400;
      break;
    default:
      color = Colors.grey.shade300;
  }

  return GestureDetector(
    onTap: () {
      setState(() {
        if (selected) {
          _selectedPriorities.remove(priority);
        } else {
          _selectedPriorities.add(priority);
        }
        _updateDataForRange(_selectedDateRange);
      });
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? color : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        boxShadow: selected
            ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6)]
            : [],
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

Widget _filterPill(String text, String value) {
  final bool selected = _selectedFilter == value;
  return GestureDetector(
    onTap: () {
      setState(() {
        if (_selectedFilter == value) {
          // Deselect filter → show all reports
          _selectedFilter = null;
          _selectedDateRange = null;
        } else {
          _selectedFilter = value;

          // compute actual DateTimeRange based on filter
          final now = DateTime.now();
          if (value == "weekly") {
            _selectedDateRange = DateTimeRange(
              start: now.subtract(const Duration(days: 7)),
              end: now,
            );
          } else if (value == "monthly") {
            _selectedDateRange = DateTimeRange(
              start: DateTime(now.year, now.month, 1),
              end: DateTime(now.year, now.month + 1, 0),
          );
          } else if (value == "yearly") {
            _selectedDateRange = DateTimeRange(
              start: DateTime(now.year, 1, 1),
              end: DateTime(now.year, 12, 31),
            );
          }
        }

        _updateDataForRange(_selectedDateRange);
      });
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.blue : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
        boxShadow: selected
            ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 6)]
            : [],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

// --- Legend dots ---
Widget _legendDot(String label, Color color) {
  return InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: () {
      setState(() {
        if (label == 'Pending') _selectedNav = 3;
        if (label == 'In Progress') _selectedNav = 4;
        if (label == 'Resolved') _selectedNav = 5;
      });
    },
    child: Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );
}

}
