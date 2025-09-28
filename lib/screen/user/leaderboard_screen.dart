import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  String _selectedFilter = 'today';
  bool _isLoading = true;
  double _loadingProgress = 0.0;

  // Data structures
  List<dynamic> _barangaysWithReports = [];
  List<dynamic> _peacefulBarangays = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _confettiController1 = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController2 = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController3 = ConfettiController(duration: const Duration(seconds: 2));
    
    _fetchLeaderboardData();
  }

  Future<void> _fetchLeaderboardData() async {
    if(!mounted) return;
    setState(() {
      _isLoading = true;
      _loadingProgress = 0.0;
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:3000/leaderboards?period=$_selectedFilter')
      );
      
      // Simulate progress updates
      if(!mounted) return;
      setState(() => _loadingProgress = 0.5);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if(!mounted) return;
        setState(() {
          _barangaysWithReports = data['with_reports'];
          _peacefulBarangays = data['no_reports'];
          _loadingProgress = 1.0;
          _isLoading = false;
        });
        
        // Show confetti for top performers
        if (_barangaysWithReports.isNotEmpty) {
          _confettiController1.play();
        }
      }
    } catch (error) {
      print('Error fetching data: $error');

      if(!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _handleFilterChange(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
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

    if (data['average_user_rate'] >= 4.5) {
      badges.add("⭐ 5-Star Feedback");
    }

    if (data['resolution_rate'] >= 80.0) {
      badges.add("⚡ Highly Efficient");
    }

    if (data['received_reports'] > 10) {
      badges.add("📈 Most Active");
    }

    return badges;
  }

  ImageProvider getProfileImage(Map<String, dynamic> data, {int fallbackIndex = 0}) {
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

  Widget _buildRankTab() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(value: _loadingProgress),
            const SizedBox(height: 16),
            Text('Loading data... ${(_loadingProgress * 100).toInt()}%'),
          ],
        ),
      );
    }

    final top3 = _barangaysWithReports.take(3).toList();
    final others = _barangaysWithReports.skip(3).toList();

    return Column(
      children: [
        _buildFilterRow(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 360;
              final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

              return GlowingOverscrollIndicator(
                axisDirection: AxisDirection.down,
                color: const Color(0xFFB9E4C9),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: GestureDetector(
                                onTap: () => _confettiController2.play(),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 24),
                                    _podiumTile(top3.length > 1 ? top3[1] : null, 2, constraints.maxWidth),
                                  ],
                                ),
                              ),
                            ),
                            Flexible(
                              child: GestureDetector(
                                onTap: () => _confettiController1.play(),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 0),
                                    _podiumTile(top3.isNotEmpty ? top3[0] : null, 1, constraints.maxWidth, crown: true),
                                  ],
                                ),
                              ),
                            ),
                            Flexible(
                              child: GestureDetector(
                                onTap: () => _confettiController3.play(),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 24),
                                    _podiumTile(top3.length > 2 ? top3[2] : null, 3, constraints.maxWidth),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        itemCount: others.length,
                        itemBuilder: (context, index) {
                          final rank = index + 4;
                          final item = others[index];
                          final avg = item['average_user_rate'] ?? 0.0;
                          return AnimatedListItem(
                            index: index,
                            child: Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              margin: const EdgeInsets.only(bottom: 10),
                              color: const Color(0xFFFBFBFA),
                              elevation: 2,
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: isSmallScreen ? 20 : 22,
                                  backgroundColor: const Color(0xFF90C67C),
                                  backgroundImage: getProfileImage(item),
                                ),
                                title: Text(
                                  '$rank. ${item['barangay_name']}',
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
                                    Text(
                                      avg.toStringAsFixed(1),
                                      style: TextStyle(fontFamily: 'Poppins', fontSize: isSmallScreen ? 12 : 14),
                                    ),
                                    Text(
                                      'Res: ${(item['resolution_rate']).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: isSmallScreen ? 10 : 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHonorsTab() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(value: _loadingProgress),
            const SizedBox(height: 16),
            Text('Loading data... ${(_loadingProgress * 100).toInt()}%'),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFilterRow(),
        Expanded(
          child: ListView.builder(
            itemCount: _peacefulBarangays.length,
            itemBuilder: (context, index) {
              final barangay = _peacefulBarangays[index];
              return AnimatedListItem(
                index: index,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  margin: const EdgeInsets.all(10),
                  color: const Color(0xFFFBFBFA),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF90C67C),
                      backgroundImage: getProfileImage(barangay),
                    ),
                    title: Text(
                      barangay['barangay_name'],
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      barangay['city'],
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.grey,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF67AE6E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'No reports received',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _podiumTile(Map<String, dynamic>? data, int rank, double width, {bool crown = false}) {
    final colorMap = {
      1: const Color(0xFF328E6E),
      2: const Color(0xFF67AE6E),
      3: const Color(0xFF90C67C),
    };
    final barangay = data?['barangay_name'] ?? '---';
    final avg = data != null ? data['average_user_rate'] ?? 0.0 : 0.0;
    final resolutionRate = data != null ? data['resolution_rate'] ?? 0.0 : 0.0;
    final badges = data != null ? _generateBadges(data) : [];
    final isSmall = width < 360;
    final avatarSize = rank == 1 ? (isSmall ? 44.0 : 50.0) : (isSmall ? 38.0 : 44.0);
    final profileImage = getProfileImage(data ?? {}, fallbackIndex: rank + 2);
    final confettiController = {
      1: _confettiController1,
      2: _confettiController2,
      3: _confettiController3,
    }[rank]!;

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
                        BoxShadow(
                          color: colorMap[rank]!.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: CircleAvatar(
                      radius: avatarSize,
                      backgroundColor: colorMap[rank],
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: avatarSize - 4,
                            backgroundImage: profileImage,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.military_tech,
                                size: 14,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ),
                          if (rank == 1)
                            Positioned(
                              top: -6,
                              right: -6,
                              child: Icon(
                                Icons.auto_awesome,
                                color: Colors.amberAccent.withOpacity(0.8),
                                size: 22,
                              ),
                            ),
                        ],
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
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (crown)
                            const Icon(Icons.emoji_events, color: Colors.amber, size: 14),
                          if (crown) const SizedBox(width: 3),
                          Text(
                            '#$rank',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              barangay,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            Text(
              _getGamifiedTitle(rank),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 14),
                const SizedBox(width: 2),
                Text(avg.toStringAsFixed(1), style: const TextStyle(fontSize: 10)),
                const SizedBox(width: 6),
                const Icon(Icons.check_circle, color: Colors.green, size: 14),
                Text('${resolutionRate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10)),
              ],
            ),
            if (badges.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: badges.map((badge) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F6E0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          overflow: TextOverflow.ellipsis,
                        ),
                        softWrap: true,
                      ),
                    );
                  }).toList(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFB9E4C9), Color(0xFFE0F7EC)],
            ),
          ),
          child: AppBar(
            title: const Text(
              'LEADERBOARD',
              style: TextStyle(
                fontFamily: 'MaryKate',
                fontSize: 28,
                color: Color(0xFF4D4D4D),
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            bottom: TabBar(
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
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F7EC), Colors.white],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildRankTab(),
            _buildHonorsTab(),
          ],
        ),
      ),
    );
  }
}