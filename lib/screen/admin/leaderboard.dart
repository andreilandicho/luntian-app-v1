import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = "Today"; // ✅ default filter
  late AnimationController _controller;
  late Animation<double> _animRank1;
  late Animation<double> _animRank2;
  late Animation<double> _animRank3;

  // Mock data with trend + extra info
final Map<String, List<Map<String, dynamic>>> leaderboardData = {
  "Today": [
    {"rank": 1, "name": "Brgy. San Juan", "points": 250, "avgTime": "1h 45m", "pending": 2, "highPriority": 1, "trend": "up", "totalReports": 45, "completionRate": 92},
    {"rank": 2, "name": "Brgy. Malinis", "points": 200, "avgTime": "2h 30m", "pending": 3, "highPriority": 1, "trend": "down", "totalReports": 40, "completionRate": 87},
    {"rank": 3, "name": "Brgy. Mabuhay", "points": 180, "avgTime": "3h 10m", "pending": 4, "highPriority": 2, "trend": "up", "totalReports": 38, "completionRate": 90},
    {"rank": 4, "name": "Brgy. Pag-asa", "points": 150, "avgTime": "4h 05m", "pending": 5, "highPriority": 2, "trend": "down", "totalReports": 35, "completionRate": 80},
    {"rank": 5, "name": "Brgy. Bayanihan", "points": 130, "avgTime": "4h 25m", "pending": 6, "highPriority": 3, "trend": "down", "totalReports": 30, "completionRate": 78},
    {"rank": 6, "name": "Brgy. Mapayapa", "points": 120, "avgTime": "5h 10m", "pending": 7, "highPriority": 2, "trend": "up", "totalReports": 28, "completionRate": 75},
    {"rank": 7, "name": "Brgy. Bagong Silang", "points": 100, "avgTime": "5h 35m", "pending": 8, "highPriority": 3, "trend": "down", "totalReports": 25, "completionRate": 72},
    {"rank": 8, "name": "Brgy. Masagana", "points": 90, "avgTime": "6h 15m", "pending": 9, "highPriority": 4, "trend": "down", "totalReports": 22, "completionRate": 70},
    {"rank": 9, "name": "Brgy. Liwanag", "points": 75, "avgTime": "6h 40m", "pending": 10, "highPriority": 4, "trend": "up", "totalReports": 20, "completionRate": 68},
    {"rank": 10, "name": "Brgy. Maligaya", "points": 60, "avgTime": "7h 05m", "pending": 12, "highPriority": 5, "trend": "down", "totalReports": 18, "completionRate": 65},
  ],
  "Week": [
    {"rank": 1, "name": "Brgy. Malinis", "points": 1200, "avgTime": "2h 10m", "pending": 8, "highPriority": 3, "trend": "up", "totalReports": 200, "completionRate": 89},
    {"rank": 2, "name": "Brgy. San Juan", "points": 1150, "avgTime": "1h 55m", "pending": 10, "highPriority": 2, "trend": "down", "totalReports": 190, "completionRate": 91},
    {"rank": 3, "name": "Brgy. Pag-asa", "points": 980, "avgTime": "3h 05m", "pending": 12, "highPriority": 4, "trend": "up", "totalReports": 160, "completionRate": 85},
    {"rank": 4, "name": "Brgy. Mabuhay", "points": 920, "avgTime": "3h 15m", "pending": 14, "highPriority": 4, "trend": "down", "totalReports": 150, "completionRate": 83},
    {"rank": 5, "name": "Brgy. Bayanihan", "points": 870, "avgTime": "3h 40m", "pending": 15, "highPriority": 5, "trend": "down", "totalReports": 140, "completionRate": 82},
    {"rank": 6, "name": "Brgy. Mapayapa", "points": 820, "avgTime": "4h 00m", "pending": 16, "highPriority": 5, "trend": "up", "totalReports": 135, "completionRate": 80},
    {"rank": 7, "name": "Brgy. Bagong Silang", "points": 780, "avgTime": "4h 20m", "pending": 18, "highPriority": 6, "trend": "down", "totalReports": 125, "completionRate": 78},
    {"rank": 8, "name": "Brgy. Masagana", "points": 730, "avgTime": "4h 45m", "pending": 19, "highPriority": 6, "trend": "down", "totalReports": 120, "completionRate": 76},
    {"rank": 9, "name": "Brgy. Liwanag", "points": 690, "avgTime": "5h 00m", "pending": 20, "highPriority": 7, "trend": "up", "totalReports": 115, "completionRate": 74},
    {"rank": 10, "name": "Brgy. Maligaya", "points": 650, "avgTime": "5h 30m", "pending": 22, "highPriority": 8, "trend": "down", "totalReports": 110, "completionRate": 72},
  ],
  "Month": [
    {"rank": 1, "name": "Brgy. Mabuhay", "points": 4300, "avgTime": "2h 40m", "pending": 20, "highPriority": 6, "trend": "up", "totalReports": 700, "completionRate": 90},
    {"rank": 2, "name": "Brgy. San Juan", "points": 4000, "avgTime": "2h 20m", "pending": 18, "highPriority": 5, "trend": "down", "totalReports": 650, "completionRate": 88},
    {"rank": 3, "name": "Brgy. Malinis", "points": 3850, "avgTime": "2h 50m", "pending": 25, "highPriority": 7, "trend": "down", "totalReports": 600, "completionRate": 85},
    {"rank": 4, "name": "Brgy. Pag-asa", "points": 3600, "avgTime": "3h 05m", "pending": 28, "highPriority": 8, "trend": "up", "totalReports": 580, "completionRate": 84},
    {"rank": 5, "name": "Brgy. Bayanihan", "points": 3400, "avgTime": "3h 20m", "pending": 30, "highPriority": 9, "trend": "down", "totalReports": 560, "completionRate": 83},
    {"rank": 6, "name": "Brgy. Mapayapa", "points": 3200, "avgTime": "3h 40m", "pending": 32, "highPriority": 10, "trend": "down", "totalReports": 540, "completionRate": 81},
    {"rank": 7, "name": "Brgy. Bagong Silang", "points": 3000, "avgTime": "4h 00m", "pending": 35, "highPriority": 11, "trend": "up", "totalReports": 520, "completionRate": 79},
    {"rank": 8, "name": "Brgy. Masagana", "points": 2800, "avgTime": "4h 20m", "pending": 38, "highPriority": 12, "trend": "down", "totalReports": 500, "completionRate": 77},
    {"rank": 9, "name": "Brgy. Liwanag", "points": 2600, "avgTime": "4h 40m", "pending": 40, "highPriority": 13, "trend": "down", "totalReports": 480, "completionRate": 75},
    {"rank": 10, "name": "Brgy. Maligaya", "points": 2400, "avgTime": "5h 00m", "pending": 42, "highPriority": 14, "trend": "down", "totalReports": 460, "completionRate": 74},
  ],
};

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _animRank1 = Tween<double>(begin: 0, end: 150).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _animRank2 = Tween<double>(begin: 0, end: 120).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _animRank3 = Tween<double>(begin: 0, end: 100).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barangays = leaderboardData[_selectedFilter]!;
    final top3 = barangays.take(3).toList();
    final others = barangays.length > 3 ? barangays.skip(3).toList() : [];
    final maxPoints =
        barangays.map((e) => e["points"] as int).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + filter toggle
            Row(
              children: [
                const Expanded(
                  child: Text(
                    "Leaderboard",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ),
                ToggleButtons(
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: Colors.blueGrey[800],
                  color: Colors.blueGrey[600],
                  constraints:
                      const BoxConstraints(minHeight: 36, minWidth: 80),
                  isSelected: [
                    _selectedFilter == "Today",
                    _selectedFilter == "Week",
                    _selectedFilter == "Month"
                  ],
                  onPressed: (index) {
                    setState(() {
                      _selectedFilter = ["Today", "Week", "Month"][index];
                      _controller.reset();
                      _controller.forward();
                    });
                  },
                  children: const [
                    Text("Today"),
                    Text("Week"),
                    Text("Month"),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Ranking of barangays based on performance (resolution time, pending, and high-priority reports).",
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            // 🏆 Podium
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return _buildPodium(top3);
              },
            ),

            const SizedBox(height: 24),

            // 📋 Leaderboard others
            if (others.isNotEmpty)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: others.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[300]),
                  itemBuilder: (context, index) {
                    final b = others[index];
                    return _interactiveTile(b, maxPoints);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Hover/Click behavior
  Widget _interactiveTile(Map<String, dynamic> b, int maxPoints) {
    final tile = _buildListTile(b, maxPoints);

    if (kIsWeb) {
      return Tooltip(
        message:
            "Total Reports: ${b["totalReports"]}\nCompletion Rate: ${b["completionRate"]}%",
        child: tile,
      );
    } else {
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(b["name"]),
              content: Text(
                  "Total Reports: ${b["totalReports"]}\nCompletion Rate: ${b["completionRate"]}%"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                )
              ],
            ),
          );
        },
        child: tile,
      );
    }
  }

  /// Podium
  Widget _buildPodium(List<Map<String, dynamic>> top3) {
    top3.sort((a, b) => (a["rank"] as int).compareTo(b["rank"] as int));
    final podium = {
      1: top3.firstWhere((b) => b["rank"] == 1, orElse: () => {}),
      2: top3.firstWhere((b) => b["rank"] == 2, orElse: () => {}),
      3: top3.firstWhere((b) => b["rank"] == 3, orElse: () => {}),
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _podiumColumn(podium[2], Colors.grey[400], _animRank2.value),
        _podiumColumn(podium[1], Colors.amber[300], _animRank1.value),
        _podiumColumn(podium[3], Colors.brown[300], _animRank3.value),
      ],
    );
  }

Widget _podiumColumn(Map<String, dynamic>? b, Color? color, double height) {
  if (b == null || b.isEmpty) return const SizedBox.shrink();

  final columnContent = Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      CircleAvatar(
        radius: 28,
        backgroundColor: color,
        child: const Icon(Icons.emoji_events, color: Colors.white, size: 28),
      ),
      const SizedBox(height: 8),
      Text(
        b["name"],
        style: const TextStyle(fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${b["points"]} pts",
            style: const TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Icon(
            b["trend"] == "up" ? Icons.trending_up : Icons.trending_down,
            color: b["trend"] == "up" ? Colors.green : Colors.red,
            size: 18,
          ),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        width: 70,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        alignment: Alignment.center,
        child: Text(
          "#${b["rank"]}",
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    ],
  );

  // ✅ Make podium interactive (hover tooltip for web, tap dialog for mobile)
  if (kIsWeb) {
    return Tooltip(
      message:
          "Total Reports: ${b["totalReports"]}\nCompletion Rate: ${b["completionRate"]}%",
      child: columnContent,
    );
  } else {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(b["name"]),
            content: Text(
                "Total Reports: ${b["totalReports"]}\nCompletion Rate: ${b["completionRate"]}%"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              )
            ],
          ),
        );
      },
      child: columnContent,
    );
  }
}

  /// ListTile with trend arrow
  Widget _buildListTile(Map<String, dynamic> b, int maxPoints) {
    final rank = b["rank"];
    final percentage = (b["points"] / maxPoints);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blueGrey[100],
        child: Text(
          "$rank",
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      title: Text(
        b["name"],
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _metricChip("⏱ ${b["avgTime"]}"),
              _metricChip("📋 ${b["pending"]} pending"),
              _metricChip("⚠️ ${b["highPriority"]} high priority"),
            ],
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percentage),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.blueGrey[50],
              color: Colors.blueGrey[800],
              minHeight: 6,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${b["points"]} pts",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blueGrey[800],
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            b["trend"] == "up" ? Icons.trending_up : Icons.trending_down,
            color: b["trend"] == "up" ? Colors.green : Colors.red,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _metricChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.blueGrey[700],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
