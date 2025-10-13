import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/user/add_screen.dart';
import 'package:flutter_application_1/screen/user/event_screen.dart';
import 'package:flutter_application_1/screen/user/leaderboard_screen.dart';
import 'package:flutter_application_1/screen/user/notification_screen.dart';
import 'package:flutter_application_1/screen/user/profile_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_application_1/models/report_model.dart';
import 'package:flutter_application_1/services/report_service.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/screen/user/report_card.dart';
import 'package:flutter_application_1/screen/user/solved_report_card.dart';
import 'package:flutter_application_1/models/solved_report_model.dart';
import 'package:flutter_application_1/services/report_deletion.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int selectedIndex = 0;
  bool isNavVisible = true;
  String _currentAddress = 'Locating...';
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ReportPageState> reportPageKey = GlobalKey<ReportPageState>();

  List<Map<String, dynamic>> _formattedReports = [];
  List<Map<String, dynamic>> _formattedSolvedReports = [];

  bool _isLoading = true;
  bool _isLoadingSolved = true;

  final _reportService = ReportService();
  final _authService = AuthService();

  UserModel? _currentUser;
  List<ReportModel> _reports = [];
  List<SolvedReportModel> _solvedReports = [];

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _loadUserAndReports();
  }

  Future<void> _loadUserAndReports() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) {
        setState(() {
          _currentUser = null;
          _isLoading = false;
          _reports = [];
          _solvedReports = [];
          _formattedReports = [];
          _formattedSolvedReports = [];
        });
        return;
      }
      _currentUser = user;
      await _fetchOngoingReports();
      await _fetchSolvedReports();
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e')),
      );
      setState(() {
        _currentUser = null;
        _isLoading = false;
        _isLoadingSolved = false;
        _formattedReports = [];
        _formattedSolvedReports = [];
      });
    }
  }

  Future<void> _fetchOngoingReports() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (_currentUser == null) {
        setState(() {
          _isLoading = false;
          _reports = [];
          _formattedReports = [];
        });
        return;
      }
      final reports = await _reportService.getReportsByBarangay(
        _currentUser!.barangayId ?? 0, 
        _currentUser!.id
      );
      // Map API data directly for UI
      final formattedReports = reports.map((report) {
        return {
          'report_id': report.reportId,
          'user_id': report.userId,
          'username': report.username ?? 'Anonymous Citizen',
          'user_profile_url': report.userProfileUrl,
          'description': report.description ?? '',
          'photo_urls': report.photoUrls ?? [],
          'status': report.status ?? '',
          'created_at': report.createdAt.toIso8601String(),
          'upvotes': report.upvotes ?? 0,
          'downvotes': report.downvotes ?? 0,
          'has_user_upvoted': report.hasUserUpvoted ?? false,
          'has_user_downvoted': report.hasUserDownvoted ?? false,
          'anonymous': report.anonymous ?? false,
          'barangay_id': report.barangayId,
          'priority': report.priority ?? 'Low',
        };
      }).toList();
      setState(() {
        _reports = reports;
        _formattedReports = formattedReports;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching ongoing reports: $e');
      setState(() {
        _isLoading = false;
        _formattedReports = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reports: $e')),
      );
    }
  }

  Future<void> _fetchSolvedReports() async {
    setState(() {
      _isLoadingSolved = true;
    });
    try {
      if (_currentUser == null) {
        setState(() {
          _isLoadingSolved = false;
          _solvedReports = [];
          _formattedSolvedReports = [];
        });
        return;
      }
      final solvedReports = await _reportService.getSolvedReportsByBarangay(
        _currentUser!.barangayId ?? 0,
        _currentUser!.id
      );
      final formattedSolvedReports = solvedReports.map((report) {
        return {
          'report_id': report.reportId,
          'user_id': report.userId,
          'username': report.username ?? 'Anonymous Citizen',
          'user_profile_url': report.userProfileUrl,
          'barangay_id': report.barangayId,
          'description': report.description ?? '',
          'photo_urls': report.photoUrls ?? [],
          // 'report_video_url': report.reportVideoUrl,
          'anonymous': report.anonymous ?? false,
          'status': report.status ?? '',
          'created_at': report.createdAt.toIso8601String(),
          // 'report_deadline': report.reportDeadline?.toIso8601String(),
          // 'lat': report.lat,
          // 'lon': report.lon,
          // 'category': report.category,
          // 'priority': report.priority,
          // 'hazardous': report.hazardous,
          'cleanup_notes': report.cleanupNotes,
          'solution_updated': report.solutionUpdated?.toIso8601String(),
          'after_photo_urls': report.afterPhotoUrls ?? [],
          'assigned_officials': report.assignedOfficials ?? [],
          'overall_average_rating': report.overallAverageRating ?? 0.0,
          'has_user_rated': report.hasUserRated,
          'user_rating': report.userRating ?? []
        };
      }).toList();
      setState(() {
        _solvedReports = solvedReports;
        _formattedSolvedReports = formattedSolvedReports;
        _isLoadingSolved = false;
      });
    } catch (e) {
      print('Error fetching solved reports: $e');
      setState(() {
        _isLoadingSolved = false;
        _formattedSolvedReports = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load solved reports: $e')),
      );
    }
  }

  Future<void> _refreshAllReports() async {
    await _fetchOngoingReports();
    await _fetchSolvedReports();
  }

  void _handleUpvote(int index) async {
    final report = _reports[index];
    final wasUpvoted = report.hasUserUpvoted;
    final wasDownvoted = report.hasUserDownvoted;

    // 1. Optimistically update UI
    setState(() {
      report.hasUserUpvoted = !wasUpvoted;
      report.upvotes += wasUpvoted ? -1 : 1;
      if (!wasUpvoted && wasDownvoted) {
        report.hasUserDownvoted = false;
        report.downvotes -= 1;
      }
      // update formattedReports for UI
      _formattedReports[index]['has_user_upvoted'] = report.hasUserUpvoted;
      _formattedReports[index]['upvotes'] = report.upvotes;
      _formattedReports[index]['has_user_downvoted'] = report.hasUserDownvoted;
      _formattedReports[index]['downvotes'] = report.downvotes;
    });

    try {
      await _reportService.voteReport(
        report.reportId, 
        _currentUser!.id,
        wasUpvoted ? 'remove' : 'upvote'
      );
      // no further action needed
    } catch (e) {
      // 2. Revert UI on error
      setState(() {
        report.hasUserUpvoted = wasUpvoted;
        report.upvotes += wasUpvoted ? 1 : -1;
        report.hasUserDownvoted = wasDownvoted;
        report.downvotes += wasDownvoted ? 1 : 0;

        _formattedReports[index]['has_user_upvoted'] = report.hasUserUpvoted;
        _formattedReports[index]['upvotes'] = report.upvotes;
        _formattedReports[index]['has_user_downvoted'] = report.hasUserDownvoted;
        _formattedReports[index]['downvotes'] = report.downvotes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update vote: $e'))
      );
    }
  }

  // Optimistic UI update for downvote
  void _handleDownvote(int index) async {
    final report = _reports[index];
    final wasDownvoted = report.hasUserDownvoted;
    final wasUpvoted = report.hasUserUpvoted;

    setState(() {
      report.hasUserDownvoted = !wasDownvoted;
      report.downvotes += wasDownvoted ? -1 : 1;
      if (!wasDownvoted && wasUpvoted) {
        report.hasUserUpvoted = false;
        report.upvotes -= 1;
      }
      _formattedReports[index]['has_user_downvoted'] = report.hasUserDownvoted;
      _formattedReports[index]['downvotes'] = report.downvotes;
      _formattedReports[index]['has_user_upvoted'] = report.hasUserUpvoted;
      _formattedReports[index]['upvotes'] = report.upvotes;
    });

    try {
      await _reportService.voteReport(
        report.reportId, 
        _currentUser!.id,
        wasDownvoted ? 'remove' : 'downvote'
      );
    } catch (e) {
      setState(() {
        report.hasUserDownvoted = wasDownvoted;
        report.downvotes += wasDownvoted ? 1 : -1;
        report.hasUserUpvoted = wasUpvoted;
        report.upvotes += wasUpvoted ? 1 : 0;

        _formattedReports[index]['has_user_downvoted'] = report.hasUserDownvoted;
        _formattedReports[index]['downvotes'] = report.downvotes;
        _formattedReports[index]['has_user_upvoted'] = report.hasUserUpvoted;
        _formattedReports[index]['upvotes'] = report.upvotes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update vote: $e'))
      );
    }
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _currentAddress = 'Location services are disabled.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _currentAddress = 'Location permissions are denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _currentAddress = 'Location permissions are permanently denied.');
        return;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.first;
      setState(() {
        _currentAddress = "${place.locality}, ${place.administrativeArea}";
      });
    } catch (e) {
      setState(() {
        _currentAddress = 'Failed to get location';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    final pages = [
      ReportPage(
        key: reportPageKey,
        posts: _formattedReports,
        solvedPosts: _formattedSolvedReports,
        scrollController: _scrollController,
        onUpvote: _handleUpvote,
        onDownvote: _handleDownvote,
        isLoading: _isLoading,
        onRefresh: _refreshAllReports,
        currentUserId: _currentUser?.id ?? 0,
      ),
      const EventsScreen(),
      const LeaderboardPage(),
      NotificationPage(),
      _currentUser != null 
          ? ProfilePage(user: _currentUser!)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Please log in to view profile"),
                  ElevatedButton(
                    onPressed: () {
                      _loadUserAndReports();
                    },
                    child: const Text("Refresh"),
                  ),
                ],
              ),
            ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEFF5F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF328E6E),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Image.asset(
                  'assets/logo only luntian.png',
                  width: isSmallScreen ? 24 : 30,
                  height: isSmallScreen ? 24 : 30,
                ),
                const SizedBox(width: 8),
                Text(
                  'LUNTIAN',
                  style: TextStyle(
                    fontFamily: 'MaryKate',
                    fontSize: isSmallScreen ? 20 : 24,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 18),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _currentAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isSmallScreen ? 12 : 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: isNavVisible ? 70 : 0,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: isNavVisible
            ? Container(
                padding: EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: isSmallScreen ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavIcon(Icons.home_rounded, 0, isSmallScreen),
                    _buildNavIcon(Icons.newspaper_rounded, 1, isSmallScreen),
                    _buildNavIcon(Icons.emoji_events_rounded, 2, isSmallScreen),
                    _buildNavIcon(Icons.notifications_rounded, 3, isSmallScreen),
                    _buildNavIcon(Icons.person_rounded, 4, isSmallScreen),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index, bool isSmallScreen) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 0 && selectedIndex == 0) {
          reportPageKey.currentState?.refreshPage();
        } else {
          setState(() {
            selectedIndex = index;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF328E6E) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black26, blurRadius: 6)] : [],
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[600],
          size: isSelected ? (isSmallScreen ? 26 : 30) : (isSmallScreen ? 20 : 24),
        ),
      ),
    );
  }
}

// =================== REPORT PAGE ======================

class ReportPage extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final List<Map<String, dynamic>> solvedPosts;
  final Function(int) onUpvote;
  final Function(int) onDownvote;
  final ScrollController scrollController;
  final void Function()? onScrollUp;
  final void Function()? onScrollDown;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final int currentUserId;

  const ReportPage({
    super.key,
    required this.posts,
    required this.solvedPosts,
    required this.onUpvote,
    required this.onDownvote,
    required this.scrollController,
    this.onScrollUp,
    this.onScrollDown,
    this.isLoading = false,
    required this.onRefresh,
    required this.currentUserId,
  });

  @override
  State<ReportPage> createState() => ReportPageState();
}

enum ReportSortType { relevant, latest }

class ReportPageState extends State<ReportPage> with TickerProviderStateMixin {
  Map<int, int> currentPages = {};
  bool showFab = false;

  ReportSortType _sortType = ReportSortType.relevant;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final offset = widget.scrollController.offset;
    if (offset > 300 && !showFab) {
      if (mounted) setState(() => showFab = true);
    } else if (offset <= 300 && showFab) {
      if (mounted) setState(() => showFab = false);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  void refreshPage() {
    if (!mounted) return;
    setState(() {});
  }

  void _showImage(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: PhotoView(imageProvider: NetworkImage(imagePath)),
      ),
    );
  }

  List<Map<String, dynamic>> get _sortedPosts {
    final posts = List<Map<String, dynamic>>.from(widget.posts);
    if (_sortType == ReportSortType.relevant) {
      posts.sort((a, b) {
        final netA = (a['upvotes'] ?? 0) - (a['downvotes'] ?? 0);
        final netB = (b['upvotes'] ?? 0) - (b['downvotes'] ?? 0);
        return netB.compareTo(netA);
      });
    } else {
      posts.sort((a, b) {
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });
    }
    return posts;
  }
Widget _buildFilterButtons() {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const Padding(
        padding: EdgeInsets.only(right: 8.0),
        child: Text(
          'Sort by:',
          style: TextStyle(
            color: Color(0xFF328E6E),
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
      Expanded(
        child: FilterChip(
          label: const Text('Relevance'),
          labelStyle: TextStyle(
            color: _sortType == ReportSortType.relevant ? Colors.white : const Color(0xFF328E6E),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
          selected: _sortType == ReportSortType.relevant,
          selectedColor: const Color(0xFF328E6E),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _sortType == ReportSortType.relevant ? const Color(0xFF328E6E) : Colors.grey.shade300,
            ),
          ),
          onSelected: (_) {
            setState(() => _sortType = ReportSortType.relevant);
          },
          showCheckmark: true,
          checkmarkColor: Colors.white,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: FilterChip(
          label: const Text('Latest'),
          labelStyle: TextStyle(
            color: _sortType == ReportSortType.latest ? Colors.white : const Color(0xFF328E6E),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w500,
          ),
          selected: _sortType == ReportSortType.latest,
          selectedColor: const Color(0xFF328E6E),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _sortType == ReportSortType.latest ? const Color(0xFF328E6E) : Colors.grey.shade300,
            ),
          ),
          onSelected: (_) {
            setState(() => _sortType = ReportSortType.latest);
          },
          showCheckmark: true,
          checkmarkColor: Colors.white,
        ),
      ),
    ],
  );
}
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification && notification.scrollDelta != null) {
          if (notification.scrollDelta! > 0) {
            widget.onScrollDown?.call();
          } else if (notification.scrollDelta! < 0) {
            widget.onScrollUp?.call();
          }
        }
        return false;
      },
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const Material(
              type: MaterialType.transparency,
              child: TabBar(
                isScrollable: false,
                labelColor: Color(0xFF328E6E),
                unselectedLabelColor: Colors.grey,
                indicator: BoxDecoration(
                  color: Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.all(Radius.circular(0)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                tabs: [
                  Tab(text: 'Reports'),
                  Tab(text: 'Solved Reports'),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            Expanded(
              child: TabBarView(
                children: [
                  // Reports Tab
                  RefreshIndicator(
                    onRefresh: widget.onRefresh,
                    child: widget.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : widget.posts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "No reports available",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const AddPage()),
                                      );
                                    },
                                    child: const Text('Create a Report'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: widget.scrollController,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04 > 20 ? 20 : screenWidth * 0.04,
                              ),
                              itemCount: _sortedPosts.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const AddPage()),
                                          );
                                        },
                                        child: Card(
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          child: Padding(
                                            padding: EdgeInsets.all(screenWidth * 0.03),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.add_a_photo, color: Color(0xFF328E6E)),
                                                SizedBox(width: screenWidth * 0.025),
                                                const Text(
                                                  "Capture a report...",
                                                  style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.015),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                                        child: _buildFilterButtons(),
                                      ),
                                    ],
                                  );
                                }
                                final post = _sortedPosts[index - 1];
                                final pageController = PageController(initialPage: currentPages[index - 1] ?? 0);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: ReportCard(
                                    post: post,
                                    pageController: pageController,
                                    screenHeight: screenHeight,
                                    currentIndex: index - 1,
                                    onUpvote: widget.onUpvote,
                                    onDownvote: widget.onDownvote,
                                    onImageTap: _showImage,
                                    currentPages: currentPages,
                                    currentUserId: widget.currentUserId,
                                    onDeleted: () async {
                                      await widget.onRefresh();
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                  // Solved Reports Tab
                  RefreshIndicator(
                    onRefresh: widget.onRefresh,
                    child: widget.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : widget.solvedPosts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 48, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  const Text(
                                    "No solved reports available",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: widget.scrollController,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.04 > 20 ? 20 : screenWidth * 0.04,
                              ),
                              itemCount: widget.solvedPosts.length,
                              itemBuilder: (context, index) {
                                final post = widget.solvedPosts[index];
                                final pageController = PageController(initialPage: currentPages[index] ?? 0);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: SolvedReportCard(
                                    post: post,
                                    pageController: pageController,
                                    screenHeight: screenHeight,
                                    currentIndex: index,
                                    onImageTap: _showImage,
                                    onViewSolution: () {},
                                    onRateSolution: () {},
                                    currentPages: currentPages,
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}