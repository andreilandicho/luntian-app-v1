import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter_application_1/widgets/official/offluntian_header.dart';
import 'package:flutter_application_1/widgets/official/offluntian_footer.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class AnimatedListItem extends StatefulWidget {
  final Widget child;
  final int index;

  const AnimatedListItem({required this.child, required this.index, super.key});

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _offsetAnimation,
        child: widget.child,
      ),
    );
  }
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ConfettiController _confettiController1;
  late ConfettiController _confettiController2;
  late ConfettiController _confettiController3;

  int selectedIndex = 1;
  bool isNavVisible = true;

  String _selectedFilter = 'today';
  bool _isLoading = true;

  List<dynamic> _barangaysWithReports = [];
  List<dynamic> _peacefulBarangays = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _confettiController1 =
        ConfettiController(duration: const Duration(seconds: 2));
    _confettiController2 =
        ConfettiController(duration: const Duration(seconds: 2));
    _confettiController3 =
        ConfettiController(duration: const Duration(seconds: 2));

    _fetchLeaderboardData();
  }

  Future<void> _fetchLeaderboardData() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/leaderboards?period=$_selectedFilter'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _barangaysWithReports = data['with_reports'];
          _peacefulBarangays = data['no_reports'];
          _isLoading = false;
        });

        if (_barangaysWithReports.isNotEmpty) {
          _confettiController1.play();
        }
      }
    } catch (error) {
      print('Error fetching data: $error');
      setState(() => _isLoading = false);
    }
  }

  void _handleFilterChange(String filter) {
    setState(() => _selectedFilter = filter);
    _fetchLeaderboardData();
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
    if (data['average_user_rate'] >= 4.5) badges.add("⭐ 5-Star Feedback");
    if (data['resolution_rate'] >= 80.0) badges.add("⚡ Highly Efficient");
    if (data['received_reports'] > 10) badges.add("📈 Most Active");
    return badges;
  }

  ImageProvider getProfileImage(Map<String, dynamic> data) {
    final url = data['user_profile_url'];
    if (url != null && url.toString().isNotEmpty) {
      return NetworkImage(url);
    } else {
      return const AssetImage('assets/profile picture.png');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _confettiController1.dispose();
    _confettiController2.dispose();
    _confettiController3.dispose();
    super.dispose();
  }

  // Leaderboard Tabs
  Widget _buildRankTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_barangaysWithReports.isEmpty) {
      return const Center(child: Text("No reports available."));
    }

    return ListView.builder(
      itemCount: _barangaysWithReports.length,
      itemBuilder: (context, index) {
        final barangay = _barangaysWithReports[index];
        final rank = index + 1;
        final badges = _generateBadges(barangay);

        return AnimatedListItem(
          index: index,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: getProfileImage(barangay),
              ),
              title: Text(
                "${rank}. ${barangay['barangay_name']}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getGamifiedTitle(rank)),
                  Wrap(
                    spacing: 6,
                    children: badges
                        .map((badge) => Chip(
                              label: Text(badge, style: const TextStyle(fontSize: 10)),
                              backgroundColor: Colors.green.shade50,
                            ))
                        .toList(),
                  )
                ],
              ),
              trailing: Text(
                "${barangay['received_reports']} reports",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHonorsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_peacefulBarangays.isEmpty) {
      return const Center(child: Text("No peaceful barangays this time."));
    }

    return ListView.builder(
      itemCount: _peacefulBarangays.length,
      itemBuilder: (context, index) {
        final barangay = _peacefulBarangays[index];
        return AnimatedListItem(
          index: index,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.green),
              title: Text(
                barangay['barangay_name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              subtitle: const Text("Peaceful Barangay 🌿"),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilterChip(
            label: const Text('Today'),
            selected: _selectedFilter == 'today',
            onSelected: (selected) => _handleFilterChange('today'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Week'),
            selected: _selectedFilter == 'week',
            onSelected: (selected) => _handleFilterChange('week'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Month'),
            selected: _selectedFilter == 'month',
            onSelected: (selected) => _handleFilterChange('month'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ Header
      appBar: LuntianHeader(isSmallScreen: isSmallScreen),

      // ✅ Body
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFB9E4C9), Color(0xFFE0F7EC)],
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF67AE6E),
              labelColor: const Color(0xFF328E6E),
              unselectedLabelColor: const Color(0xFF4D4D4D),
              tabs: const [
                Tab(text: 'RANKINGS'),
                Tab(text: 'NO REPORTS'),
              ],
            ),
          ),

          _buildFilterRow(),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRankTab(),
                _buildHonorsTab(),
              ],
            ),
          ),
        ],
      ),

      // ✅ Footer
      bottomNavigationBar: LuntianFooter(
        selectedIndex: selectedIndex,
        isNavVisible: isNavVisible,
        isSmallScreen: isSmallScreen,
        onItemTapped: (int index) {
          setState(() => selectedIndex = index);
          if (index == 0) {
            Future.microtask(() {
              // Navigate to Dashboard
            });
          } else if (index == 1) {
            Future.microtask(() {
              // Stay on Leaderboard
            });
          } else if (index == 2) {
            Future.microtask(() {
              // Navigate to Notifications
            });
          }
        },
      ),
    );
  }
}
