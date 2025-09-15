import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class LeaderboardWidget extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final double width;

  const LeaderboardWidget({super.key, required this.data, this.width = double.infinity});

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  late ConfettiController _confettiController1;
  late ConfettiController _confettiController2;
  late ConfettiController _confettiController3;

  @override
  void initState() {
    super.initState();
    _confettiController1 = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController2 = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController3 = ConfettiController(duration: const Duration(seconds: 2));

    // Auto-play confetti for top 3
    _confettiController1.play();
    _confettiController2.play();
    _confettiController3.play();
  }

  @override
  void dispose() {
    _confettiController1.dispose();
    _confettiController2.dispose();
    _confettiController3.dispose();
    super.dispose();
  }

  double _average(List<int> ratings) {
    if (ratings.isEmpty) return 0.0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  List<Map<String, dynamic>> _getSortedData(List<Map<String, dynamic>> data) {
    const ratingWeight = 0.7;
    const activityWeight = 0.3;

    final sortedData = List<Map<String, dynamic>>.from(data)
      ..sort((a, b) {
        final aScore = (_average(a['ratings']) * ratingWeight) +
            (a['activityScore'] * activityWeight);
        final bScore = (_average(b['ratings']) * ratingWeight) +
            (b['activityScore'] * activityWeight);
        return bScore.compareTo(aScore);
      });

    return sortedData;
  }

  String _getGamifiedTitle(int rank) {
    switch (rank) {
      case 1:
        return '🏆 Champion Streak!';
      case 2:
        return '🔥 Rising Star';
      case 3:
        return '🌟 Consistent Topper';
      default:
        return '';
    }
  }

  List<String> _generateBadges(Map<String, dynamic> data) {
    final badges = <String>[];

    if (_average(data['ratings']) >= 4.5) badges.add("⭐ 5-Star Feedback");
    if (data['activityScore'] > 8) badges.add("⚡ Highly Active");
    if (_average(data['ratings']) < 3) badges.add("📈 Most Improved");

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final sortedData = _getSortedData(widget.data);
    final top3 = sortedData.take(3).toList();
    final others = sortedData.skip(3).toList();
    final isSmallScreen = widget.width < 360;

    return Column(
      children: [
        // Top 3 Podium
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _podiumTile(top3.length > 1 ? top3[1] : null, 2),
            _podiumTile(top3.isNotEmpty ? top3[0] : null, 1, crown: true),
            _podiumTile(top3.length > 2 ? top3[2] : null, 3),
          ],
        ),
        const SizedBox(height: 20),
        // Other rankings
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: others.length,
          itemBuilder: (context, index) {
            final rank = index + 4;
            final item = others[index];
            final avg = _average(item['ratings']);
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.only(bottom: 10),
              color: const Color(0xFFFBFBFA),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  radius: isSmallScreen ? 20 : 22,
                  backgroundColor: const Color(0xFF90C67C),
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=${rank + 2}'),
                ),
                title: Text(
                  '$rank. ${item['barangay']}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
                subtitle: Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < avg.round() ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: isSmallScreen ? 14 : 16,
                    );
                  }),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(avg.toStringAsFixed(1), style: TextStyle(fontSize: isSmallScreen ? 12 : 14)),
                    Text('Act: ${item['activityScore']}',
                        style: TextStyle(fontSize: isSmallScreen ? 10 : 11, color: Colors.grey)),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _podiumTile(Map<String, dynamic>? data, int rank, {bool crown = false}) {
    final colorMap = {
      1: const Color(0xFF328E6E),
      2: const Color(0xFF67AE6E),
      3: const Color(0xFF90C67C),
    };
    final barangay = data?['barangay'] ?? '---';
    final avg = data != null ? _average(data['ratings']) : 0.0;
    final badges = _generateBadges(data ?? {});
    final avatarSize = rank == 1 ? 50.0 : 44.0;

    final confettiController = {1: _confettiController1, 2: _confettiController2, 3: _confettiController3}[rank]!;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Column(
          children: [
            AnimatedScale(
              scale: 1.0,
              duration: Duration(milliseconds: 600 + rank * 100),
              curve: Curves.elasticOut,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(color: colorMap[rank]!.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)
                      ],
                    ),
                    child: CircleAvatar(
                      radius: avatarSize,
                      backgroundColor: colorMap[rank],
                      child: CircleAvatar(
                        radius: avatarSize - 4,
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=${rank + 2}'),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorMap[rank],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), offset: const Offset(0, 2), blurRadius: 4)
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (crown) const Icon(Icons.emoji_events, color: Colors.amber, size: 14),
                          if (crown) const SizedBox(width: 3),
                          Text('#$rank', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(barangay, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 12)),
            Text(_getGamifiedTitle(rank), style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color.fromARGB(255, 0, 0, 0))),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 2),
                Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 10)),
                const SizedBox(width: 6),
                const Icon(Icons.flash_on, color: Colors.orange, size: 14),
                Text('${data?['activityScore'] ?? 0}', style: const TextStyle(fontSize: 10)),
              ],
            ),
            if (badges.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: badges
                      .map((badge) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFE5F6E0), borderRadius: BorderRadius.circular(10)),
                            child: Text(badge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
        Positioned(
          top: -30,
          child: ConfettiWidget(
            confettiController: confettiController,
            blastDirection: -3.14 / 2,
            maxBlastForce: 20,
            minBlastForce: 5,
            emissionFrequency: 0.03,
            numberOfParticles: 10,
            gravity: 0.1,
            shouldLoop: false,
          ),
        ),
      ],
    );
  }
}
