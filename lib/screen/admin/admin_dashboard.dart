// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:html' as html; // ✅ web only
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/screen/admin/notification_screen.dart';
import 'package:flutter_application_1/screen/admin/profile_screen.dart';
import 'package:flutter_application_1/screen/admin/login_screen.dart';
import 'package:flutter_application_1/screen/admin/pending.dart';
import 'package:flutter_application_1/screen/admin/inprogress.dart';
import 'package:flutter_application_1/screen/admin/resolved.dart';

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
    final int initialTab; // 👈 add this

  const AdminDashboard({
    super.key,
    this.initialTab = 0, // default to Dashboard
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  
  // Sidebar
  final bool _collapsed = false;
  static const double sidebarWidth = 260;
  static const double sidebarCollapsedWidth = 72;

  // Nav
  late int _selectedNav; // 👈 make late
  int _unreadCount = 0; // sidebar badge source

  // Right panel mode
  bool _showThreshold = false;

  // Countdown
  final DateTime _deadline = DateTime.now().add(const Duration(days: 7));
  Duration _timeLeft = Duration.zero;
  Timer? _timer;
  Timer? _clockTimer;
  String _liveTime = '';

  // Dummy data
  final int _pending = 90;
  final int _inProgress = 30;
  final int _resolved = 45;
  final List<int> _weekly = [5, 12, 8, 10, 18, 9, 6];
  final List<Map<String, dynamic>> _leaderboard = [
    {'rank': 1, 'name': 'Barangay 630', 'score': 92},
    {'rank': 2, 'name': 'Barangay 631', 'score': 87},
    {'rank': 3, 'name': 'Barangay 632', 'score': 81},
    {'rank': 4, 'name': 'Barangay 633', 'score': 76},
  ];

  final List<Map<String, String>> _sampleReports = [
    {
      'id': 'R-00164',
      'location': 'PUP Main Gate',
      'category': 'Garbage Accumulation',
      'hazardous': 'Yes',
      'priority': 'High',
      'deadlineText': '7 days left',
      'image': 'assets/garbage.png',
    },
    {
      'id': 'R-00165',
      'location': 'PUP Library',
      'category': 'Water Leak',
      'hazardous': 'No',
      'priority': 'Medium',
      'deadlineText': '3 days left',
      'image': 'assets/garbage.png',
    },
    {
      'id': 'R-00166',
      'location': 'PUP Garden',
      'category': 'Fallen Leaves',
      'hazardous': 'No',
      'priority': 'Low',
      'deadlineText': '14 days left',
      'image': 'assets/garbage.png',
    },
  ];

  List<Map<String, String>> get sortedReports {
    final priorityOrder = {'High': 3, 'Medium': 2, 'Low': 1};

    List<Map<String, String>> sortedList = List.from(_sampleReports);
    sortedList.sort((a, b) {
      return (priorityOrder[b['priority']] ?? 0)
          .compareTo(priorityOrder[a['priority']] ?? 0);
    });

    return sortedList;
  }

  // Colors
  final Color sidebarColor = const Color(0xFF328E6E);
  final Color darkCard = const Color(0xFF16423C);
  final Color accent = const Color(0xFF6A9C89);

  // Hover states (desktop)
  final Map<int, bool> _hoverNav = {};
  final Map<int, bool> _hoverLeaderboard = {};

  late AnimationController _pieController;
  late Animation<double> _pendingAnim;
  late Animation<double> _inProgressAnim;
  late Animation<double> _resolvedAnim;
  

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startClock();
    for (var i = 0; i < 10; i++) {
      _hoverNav[i] = false;
      _hoverLeaderboard[i] = false;
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

      _pieController.forward();

      _selectedNav = widget.initialTab; // 👈 use initialTab value

    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _animatePie = true);
    });
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

  void _startTimer() {
    _updateTimeLeft();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeLeft());
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    setState(() {
      _timeLeft = _deadline.isAfter(now) ? _deadline.difference(now) : Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clockTimer?.cancel();
    _pieController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return 'Expired';
    final days = d.inDays;
    final hours = d.inHours.remainder(24).toString().padLeft(2, '0');
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return days > 0 ? '${days}d $hours:$mins:$secs' : '$hours:$mins:$secs';
  }

  String _reportingLabel() {
    final now = DateTime.now();
    // same logic, clarified months
    if (now.month >= 1 && now.month <= 5) {
      final start = DateFormat.MMM().format(DateTime(now.year - 1, 8));
      final end = DateFormat.MMM().format(DateTime(now.year, 5));
      return '$start — $end ${now.year}';
    } else {
      final start = DateFormat.MMM().format(DateTime(now.year, 8));
      final end = DateFormat.MMM().format(DateTime(now.year + 1, 5));
      return '$start — $end ${now.year + (now.month >= 8 ? 1 : 0)}';
    }
  }

  bool _isSmall(double width) => width < 760;
  bool _isMedium(double width) => width >= 760 && width < 1100;

  bool _animatePie = false;

@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final autoCollapse = _isSmall(width);
      final effectiveCollapsed = autoCollapse ? true : _collapsed;
      final sWidth = effectiveCollapsed ? sidebarCollapsedWidth : sidebarWidth;

      return Scaffold(
        // Drawer for mobile view
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
            // ✅ Mobile Top Bar (now always shown for all pages)
            if (_isSmall(width))
              Container(
                color: sidebarColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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

            // ✅ Main Row Layout (Sidebar + Content)
            Expanded(
              child: Row(
                children: [
                  // Sidebar (desktop only)
                  if (!_isSmall(width))
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      width: sWidth,
                      curve: Curves.easeInOut,
                      color: sidebarColor,
                      child: SafeArea(
                        child: _buildSidebarContent(collapsed: effectiveCollapsed),
                      ),
                    ),

                  // Main content
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

/// Sidebar content reused for desktop and mobile drawer
Widget _buildSidebarContent({required bool collapsed}) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              height: 44,
              width: 44,
              child: Image.asset('assets/logo only luntian.png', fit: BoxFit.contain),
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
      _navTile(icon: Icons.dashboard, label: 'Dashboard', index: 0, collapsed: collapsed),
      _navTile(
          icon: Icons.notifications,
          label: 'Notifications',
          index: 1,
          collapsed: collapsed,
          badgeCount: _unreadCount, // ✅ correct
        ),
      _navTile(icon: Icons.person, label: 'Profile', index: 2, collapsed: collapsed),
      const Spacer(),
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

Widget _navTile({
  required IconData icon,
  required String label,
  required int index,
  required bool collapsed,
  int? badgeCount, // optional badge count
}) {
  final bool selected = _selectedNav == index;
  return MouseRegion(
    onEnter: (_) => setState(() => _hoverNav[index] = true),
    onExit: (_) => setState(() => _hoverNav[index] = false),
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () {
        setState(() {
          _selectedNav = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 12),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white24
              : _hoverNav[index]! ? Colors.white.withOpacity(0.04) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: Colors.white),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            if (!collapsed) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _buildMainContent() {
  switch (_selectedNav) {
    case 0: return _dashboardContent(context);
    case 1:return NotificationPage(
        onUnreadChanged: (unread) {
          if (unread != _unreadCount) {
            setState(() => _unreadCount = unread);
          }
        },
    );
    case 2: return const ProfilePage();
    case 3: return const PendingPage();
    case 4: return const InProgressPage();
    case 5: return const ResolvedPage();
    default: return _dashboardContent(context);
  }
}

Widget _dashboardContent(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final height = MediaQuery.of(context).size.height;
  const contentPadding = EdgeInsets.all(18.0);

  return Column(
    children: [
      // 🚫 Removed mobile top bar from here — it's now global above

      // Scrollable dashboard content
      Expanded(
        child: SingleChildScrollView(
          padding: contentPadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height - 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: LayoutBuilder(builder: (context, c) {
                    final narrow = c.maxWidth < 520;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: narrow ? double.infinity : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('DASHBOARD', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'Marykate')),
                              SizedBox(height: 6),
                              Text('BRGY 630', style: TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(DateFormat.yMMMMd().format(DateTime.now()),
                                  style: const TextStyle(color: Colors.black54)),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.access_time_outlined, size: 16, color: Colors.black54),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _liveTime,
                                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),

                const SizedBox(height: 18),

                // Top row: Pie + Action card
                Builder(builder: (context) {
                  if (_isSmall(width)) {
                    return Column(
                      children: [
                        _pieCard(),
                        const SizedBox(height: 12),
                        _rightCard(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _pieCard()),
                      const SizedBox(width: 16),
                      SizedBox(width: 360, child: _rightCard()),
                    ],
                  );
                }),

                const SizedBox(height: 16),

                // Analytics
                SizedBox(height: 320, child: _analyticsCard()),

                const SizedBox(height: 12),

                // Leaderboard or Threshold
                SizedBox(
                  height: 320,
                  child: _showThreshold ? _thresholdDetails() : _leaderboardView(),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _pieCard() {
  final total = (_pending + _inProgress + _resolved).toDouble();
  final pPending = total > 0 ? (_pending / total) * 100 : 0.0;
  final pInProgress = total > 0 ? (_inProgress / total) * 100 : 0.0;
  final pResolved = total > 0 ? (_resolved / total) * 100 : 0.0;

  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    elevation: 6,
    shadowColor: Colors.black12,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isNarrow = constraints.maxWidth < 450; // more generous breakpoint
          final chartHeight = (screenWidth * 0.25).clamp(150.0, 250.0);

          if (isNarrow) {
            // Mobile layout (stacked vertically)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: chartHeight,
                  child: _buildPieChart(pPending, pInProgress, pResolved),
                ),
                const SizedBox(height: 16),
                _pieLegend(total, pPending, pInProgress, pResolved),
              ],
            );
          }

          // Tablet/Desktop layout (row)
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                flex: 2,
                child: SizedBox(
                  height: chartHeight,
                  child: _buildPieChart(pPending, pInProgress, pResolved),
                ),
              ),
              const SizedBox(width: 18),
              Flexible(
                flex: 3,
                child: _pieLegend(total, pPending, pInProgress, pResolved),
              ),
            ],
          );
        },
      ),
    ),
  );
}

Widget _buildPieChart(double pPending, double pInProgress, double pResolved) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final maxRadius = (constraints.maxWidth < constraints.maxHeight
              ? constraints.maxWidth
              : constraints.maxHeight) *
          0.35; // scale radius to fit inside

      return AnimatedBuilder(
        animation: _pieController,
        builder: (context, child) {
          return PieChart(
            PieChartData(
              centerSpaceRadius: maxRadius * 0.6, // scale center hole
              sectionsSpace: 4,
              pieTouchData: PieTouchData(enabled: false),
              sections: [
                PieChartSectionData(
                  value: _pending * _pendingAnim.value,
                  color: Colors.red.shade500,
                  title: '${(pPending * _pendingAnim.value).toStringAsFixed(0)}%',
                  radius: maxRadius,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  titlePositionPercentageOffset: 0.6,
                ),
                PieChartSectionData(
                  value: _inProgress * _inProgressAnim.value,
                  color: Colors.yellow.shade600,
                  title: '${(pInProgress * _inProgressAnim.value).toStringAsFixed(0)}%',
                  radius: maxRadius * 0.85,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  titlePositionPercentageOffset: 0.55,
                ),
                PieChartSectionData(
                  value: _resolved * _resolvedAnim.value,
                  color: Colors.green.shade600,
                  title: '${(pResolved * _resolvedAnim.value).toStringAsFixed(0)}%',
                  radius: maxRadius * 0.7,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  titlePositionPercentageOffset: 0.45,
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _pieLegend(double total, double pPending, double pInProgress, double pResolved) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final isSmallLegend = constraints.maxWidth < 250;
      return SizedBox(
        height: 180,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('REPORT STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Text('Total: ${total.toInt()}', style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              _legendRow(Colors.red.shade500, 'Pending', _pending, '${pPending.toStringAsFixed(0)}%', isSmallLegend),
              const SizedBox(height: 8),
              _legendRow(Colors.yellow.shade600, 'In Progress', _inProgress, '${pInProgress.toStringAsFixed(0)}%', isSmallLegend),
              const SizedBox(height: 8),
              _legendRow(Colors.green.shade600, 'Completed', _resolved, '${pResolved.toStringAsFixed(0)}%', isSmallLegend),
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

Widget _legendRow(
  Color color,
  String label,
  int value,
  String percent,
  bool compact,
) {
  return InkWell(
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    borderRadius: BorderRadius.circular(6),
    onTap: () {
      setState(() {
        if (label == 'Pending') {
          _selectedNav = 3;
        } else if (label == 'In Progress') {
          _selectedNav = 4;
        } else {
          _selectedNav = 5;
        }
      });
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          if (!compact)
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Text(
            percent,
            style: const TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

Widget _rightCard() {
  final deadlineStr = DateFormat.yMMMd().add_jm().format(_deadline);

  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    elevation: 6,
    shadowColor: Colors.black12,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isNarrow = constraints.maxWidth < 450; // matches pieCard logic
          final isVeryNarrow = constraints.maxWidth < 300;

          // Dynamically scale countdown font size
          final countdownFs = (screenWidth * 0.04).clamp(16.0, 22.0);

          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ----- TITLE & LABEL -----
                if (isNarrow)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _iconBadge(Icons.timer),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Action Deadline',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _labelBadge(_reportingLabel()),
                    ],
                  )
                else
                  Row(
                    children: [
                      _iconBadge(Icons.timer),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Action Deadline',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(child: _labelBadge(_reportingLabel())),
                    ],
                  ),

                const SizedBox(height: 12),

                // ----- COUNTDOWN AREA -----
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isNarrow
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDuration(_timeLeft),
                              style: TextStyle(fontSize: countdownFs, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Time left until required action',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Deadline: $deadlineStr',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _thresholdButton(isVeryNarrow),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatDuration(_timeLeft),
                                    style: TextStyle(fontSize: countdownFs, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Time left until required action',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Deadline: $deadlineStr',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ],
                              ),
                            ),
                            _thresholdButton(false),
                          ],
                        ),
                ),

                const SizedBox(height: 14),
              ],
            ),
          );
        },
      ),
    ),
  );
}

Widget _iconBadge(IconData icon) {
  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: accent.withOpacity(0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, color: const Color(0xFF328E6E)),
  );
}

Widget _labelBadge(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      softWrap: false,
    ),
  );
}

Widget _thresholdButton(bool expandFull) {
  final isLeaderboard = _showThreshold;
  final bgColor = isLeaderboard ? darkCard : accent;
  final label = isLeaderboard ? 'Leaderboard' : 'Open Threshold';
  final icon = isLeaderboard ? Icons.leaderboard : Icons.open_in_new;

  final buttonChild = Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: Colors.white),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  final buttonStyle = ElevatedButton.styleFrom(
    backgroundColor: bgColor,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    elevation: 4,
  );

  final button = ElevatedButton(
    onPressed: () => setState(() => _showThreshold = !_showThreshold),
    style: buttonStyle,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: buttonChild,
    ),
  );

  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      transform: Matrix4.translationValues(0, 0, 0),
      child: expandFull
          ? SizedBox(width: double.infinity, child: button)
          : button,
    ),
  );
}

// Make sure _weekly and sidebarColor are available in your state
// Example:
// List<double> _weekly = [12, 18, 25, 20, 30, 28, 22];
// Color sidebarColor = Colors.green;

Widget _analyticsCard() {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    elevation: 6,
    shadowColor: Colors.black26,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WEEKLY TRASH ANALYTICS — (Mon → Sun)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: 50,
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 10,
                        getDrawingHorizontalLine: (val) =>
                            FlLine(color: Colors.grey.withOpacity(0.12), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 10,
                            reservedSize: 40,
                            getTitlesWidget: (val, meta) => Text(
                              '${val.toInt()} kg',
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (v, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              final idx = v.toInt();
                              if (idx < 0 || idx >= days.length) return const SizedBox();
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 6,
                                child: Text(days[idx], style: const TextStyle(fontSize: 12)),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),

                      // Glassmorphic tooltip
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipRoundedRadius: 12,
                          tooltipPadding: const EdgeInsets.all(0),
                          tooltipBgColor: Colors.transparent,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              final day = dayNames[spot.x.toInt()];
                              final value = spot.y.toStringAsFixed(1);

                              return LineTooltipItem(
                                '$day\n',
                                const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                children: [
                                  TextSpan(
                                    text: '$value kg',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: sidebarColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            }).toList();
                          },
                        ),
                        touchCallback: (event, response) {},
                      ),

                      lineBarsData: [
                        LineChartBarData(
                          spots: List.generate(
                            _weekly.length,
                            (i) => FlSpot(i.toDouble(), _weekly[i].toDouble() * value),
                          ),
                          isCurved: true,
                          color: sidebarColor,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) =>
                                FlDotCirclePainter(radius: 4, color: sidebarColor, strokeWidth: 0),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                sidebarColor.withOpacity(0.18),
                                sidebarColor.withOpacity(0.02),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _leaderboardView() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 6,
      shadowColor: Colors.black12,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('LEADERBOARD', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _leaderboard.length,
              separatorBuilder: (_, __) => const Divider(height: 12),
              itemBuilder: (context, i) {
                final r = _leaderboard[i];
                final rank = r['rank'] as int;
                IconData? medal;
                Color? medalColor;
                if (rank == 1) {
                  medal = Icons.emoji_events;
                  medalColor = Colors.amber[700];
                } else if (rank == 2) {
                  medal = Icons.emoji_events;
                  medalColor = Colors.grey[400];
                } else if (rank == 3) {
                  medal = Icons.emoji_events;
                  medalColor = Colors.brown[400];
                }
                return MouseRegion(
                  onEnter: (_) => setState(() => _hoverLeaderboard[i] = true),
                  onExit: (_) => setState(() => _hoverLeaderboard[i] = false),
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    decoration: BoxDecoration(
                      color: _hoverLeaderboard[i]! ? Colors.grey.withOpacity(0.03) : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      minVerticalPadding: 6,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey[100],
                        child: medal != null
                            ? Icon(medal, color: medalColor, size: 20)
                            : Text('${r['rank']}', style: const TextStyle(color: Colors.black)),
                      ),
                      title: Text(r['name'], style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                      subtitle: Text('Score: ${r['score']}'),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

Widget _thresholdDetails({bool isFullscreen = false}) {
  final deadlineStr = DateFormat.yMMMd().add_jm().format(_deadline);
  final totalSeconds = const Duration(days: 7).inSeconds;
  final remainingSeconds = _timeLeft.inSeconds;
  final progress =
      (remainingSeconds > 0) ? (1 - (remainingSeconds / totalSeconds)) : 1.0;

  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  return Builder(
    builder: (context) => ClipRRect(
      borderRadius: BorderRadius.circular(isFullscreen ? 0 : 16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(isFullscreen ? 0 : 16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.redAccent, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Threshold Monitor',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  Expanded(
                    child: Text(
                      deadlineStr,
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (!isFullscreen)
                    IconButton(
                      icon: const Icon(Icons.open_in_full, size: 20),
                      onPressed: () {
                        showGeneralDialog(
                          context: context,
                          barrierDismissible: true,
                          barrierLabel: "Close",
                          barrierColor: Colors.black54,
                          transitionDuration:
                              const Duration(milliseconds: 300),
                          pageBuilder: (context, anim1, anim2) {
                            return const SizedBox.shrink();
                          },
                          transitionBuilder: (context, anim1, anim2, child) {
                            return Transform.scale(
                              scale:
                                  Curves.easeOutBack.transform(anim1.value),
                              child: Opacity(
                                opacity: anim1.value,
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 800,
                                      maxHeight: 600,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: _thresholdDetails(
                                          isFullscreen: true),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  if (isFullscreen)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),

              const SizedBox(height: 12),
              // Time left
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 18, color: Colors.black54),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Time left: ${_formatDuration(_timeLeft)}',
                        style:
                            const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Reports',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 8),

              // Scrollable reports list
              Expanded(
                child: ListView.builder(
                  itemCount: sortedReports.length,
                  itemBuilder: (context, index) {
                    final report = sortedReports[index];
                    final priorityColor =
                        getPriorityColor(report['priority']!);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: priorityColor.withOpacity(0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                report['image']!,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  width: 96,
                                  height: 96,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image,
                                      size: 36, color: Colors.black26),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Report ID: ${report['id']}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  _reportInfoRow(
                                      'Location', report['location']!),
                                  _reportInfoRow(
                                      'Category', report['category']!),
                                  _reportInfoRow(
                                      'Hazardous', report['hazardous']!),

                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      const Text('Priority: ',
                                          style: TextStyle(fontSize: 13)),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4),
                                        decoration: BoxDecoration(
                                          color:
                                              priorityColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          report['priority']!,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: priorityColor),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),
                                  Text(
                                    'Action Deadline: ${report['deadlineText']}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    ),
  );
}

/// Helper for cleaner report rows
Widget _reportInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      '$label: $value',
      style: const TextStyle(fontSize: 13),
    ),
  );
}

}