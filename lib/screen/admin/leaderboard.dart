import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = "today"; // ✅ default filter
  late AnimationController _controller;
  late Animation<double> _animRank1;
  late Animation<double> _animRank2;
  late Animation<double> _animRank3;

  List<Map<String, dynamic>> withReports = [];
  List<Map<String, dynamic>> noReports = [];
  bool isLoading = true;
  bool hasError = false;

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

    fetchLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
  setState(() {
    isLoading = true;
    hasError = false;
  });
  try {
    final period = _selectedFilter.toLowerCase();
    //request url
    final uri = Uri.parse('http://luntian-app-v1-production.up.railway.app/leaderboards?period=$period');
    print("[DEBUG] Fetching leaderboard from $uri");
    final res = await http.get(uri);
    print("[DEBUG] Response status: ${res.statusCode}");
    print("[DEBUG] Response body: ${res.body}");
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      setState(() {
        withReports = List<Map<String, dynamic>>.from(json['with_reports']);
        for (int i = 0; i < withReports.length; i++) {
          withReports[i]["rank"] = i + 1;
        }
        noReports = List<Map<String, dynamic>>.from(json['no_reports']);
        isLoading = false;
        _controller.reset();
        _controller.forward();
      });
      print("[DEBUG] Loaded withReports: $withReports");
      print("[DEBUG] Loaded noReports: $noReports");
    } else {
      print("[ERROR] Server returned ${res.statusCode}: ${res.body}");
      setState(() { hasError = true; isLoading = false; });
    }
  } catch (e, st) {
    print("[ERROR] Exception loading leaderboard: $e");
    print(st);
    setState(() { hasError = true; isLoading = false; });
  }
}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onFilterChanged(String newFilter) {
    setState(() {
      _selectedFilter = newFilter;
    });
    fetchLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    final top3 = withReports.length > 3 ? withReports.sublist(0, 3) : List<Map<String, dynamic>>.from(withReports);
    final others = withReports.length > 3 ? withReports.sublist(3) : [];
    final maxScore = withReports.isNotEmpty
        ? withReports.map((e) => e["leaderboard_score"] as num).reduce((a, b) => a > b ? a : b)
        : 1;

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
                    _selectedFilter == "today",
                    _selectedFilter == "week",
                    _selectedFilter == "month"
                  ],
                  onPressed: (index) {
                    final newFilter = ["today", "week", "month"][index];
                    _onFilterChanged(newFilter);
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
              "Ranking of barangays based on performance.",
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            if (isLoading)
              const Center(child: CircularProgressIndicator()),
            if (hasError)
              const Center(child: Text("Failed to load leaderboard data.")),

            if (!isLoading && !hasError) ...[
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
                      return _interactiveTile(b, maxScore);
                    },
                  ),
                ),
              const SizedBox(height: 32),

              // 🎖️ Honorable Mention for barangays with no reports
              if (noReports.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Honorable Mention",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[700],
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: noReports.map((barangay) {
                        return Chip(
                          label: Text(
                            barangay["barangay_name"],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
                            ),
                          ),
                          backgroundColor: Colors.green[50],
                          avatar: const Icon(Icons.emoji_events, color: Colors.green, size: 18),
                          side: BorderSide(color: Colors.green.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Hover/Click behavior
  Widget _interactiveTile(Map<String, dynamic> b, num maxScore) {
    final tile = _buildListTile(b, maxScore);

    if (kIsWeb) {
      return Tooltip(
        message:
          "Total Reports: ${b["received_reports"]}\nResolution Rate: ${(b["resolution_rate"]).toStringAsFixed(1)}%",
        child: tile,
      );
    } else {
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(b["barangay_name"]),
              content: Text(
                  "Total Reports: ${b["received_reports"]}\nResolution Rate: ${(b["resolution_rate"]).toStringAsFixed(1)}%"),
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
    // Sort using leaderboard_score from the API
    final sorted = List<Map<String, dynamic>>.from(top3)
          ..sort((a, b) => (b["leaderboard_score"] as num).compareTo(a["leaderboard_score"] as num));
        final podium = <int, Map<String, dynamic>>{
      1: top3.cast<Map<String, dynamic>>().firstWhere(
            (b) => b["rank"] == 1,
            orElse: () => <String, dynamic>{},
          ),
      2: top3.cast<Map<String, dynamic>>().firstWhere(
            (b) => b["rank"] == 2,
            orElse: () => <String, dynamic>{},
          ),
      3: top3.cast<Map<String, dynamic>>().firstWhere(
            (b) => b["rank"] == 3,
            orElse: () => <String, dynamic>{},
          ),
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
          b["barangay_name"],
          style: const TextStyle(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${(b["leaderboard_score"]).toStringAsFixed(1)}%",
              style: const TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            // You may add trend icons if you calculate trend from your backend
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
            "#${withReports.indexOf(b) + 1}",
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
            "Total Reports: ${b["received_reports"]}\nResolution Rate: ${(b["resolution_rate"]).toStringAsFixed(1)}%",
        child: columnContent,
      );
    } else {
      return InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(b["barangay_name"]),
              content: Text(
                  "Total Reports: ${b["received_reports"]}\nResolution Rate: ${(b["resolution_rate"]).toStringAsFixed(1)}%"),
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

  /// ListTile with metric chips
  Widget _buildListTile(Map<String, dynamic> b, num maxScore) {
    final rank = withReports.indexOf(b) + 1;
    final percentage = (b["leaderboard_score"] as num) / maxScore;

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
        b["barangay_name"],
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _metricChip("✅ ${b["resolved_reports"]} resolved"),
              _metricChip("📋 ${b["active_reports"]} active"),
              _metricChip("🥰 ${(b["average_user_rate"] as num).toStringAsFixed(2)} avg. rating"),
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
      trailing: Text(
        "${(b["leaderboard_score"]).toStringAsFixed(1)}%",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.blueGrey[800],
        ),
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