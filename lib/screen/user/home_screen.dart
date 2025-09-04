import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/user/add_screen.dart';
import 'package:flutter_application_1/screen/user/event_screen.dart';
import 'package:flutter_application_1/screen/user/leaderboard_screen.dart';
import 'package:flutter_application_1/screen/user/notification_screen.dart';
import 'package:flutter_application_1/screen/user/profile_screen.dart';
import 'package:flutter_application_1/screen/user/search_screen.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_application_1/models/report_model.dart';
import 'package:flutter_application_1/services/report_service.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/models/user_model.dart';

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

  // New variables
  List<ReportModel> _reports = [];
  bool _isLoading = true;
  final _reportService = ReportService();
  final _authService = AuthService();
  UserModel? _currentUser;

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
        // Handle case where user is not logged in
        return;
      }
      
      _currentUser = user;
      await _fetchReports();
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  //functions to fetch reports based on barangay id of the signed-in user, handle upvotes and downvotes
  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final reports = await _reportService.getReportsByBarangay(
        _currentUser!.barangayId ?? 0, 
        _currentUser!.id
      );
      
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching reports: $e');
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reports: $e')),
      );
    }
  }

  void _handleUpvote(int index) async {
    final report = _reports[index];
    final wasUpvoted = report.hasUserUpvoted;
    
    setState(() {
      if (wasUpvoted) {
        report.hasUserUpvoted = false;
        report.upvotes -= 1;
      } else {
        report.hasUserUpvoted = true;
        report.upvotes += 1;
        if (report.hasUserDownvoted) {
          report.hasUserDownvoted = false;
          report.downvotes -= 1;
        }
      }
    });
    
    try {
      await _reportService.voteReport(
        report.reportId, 
        _currentUser!.id,
        wasUpvoted ? 'remove' : 'upvote'
      );
    } catch (e) {
      // Revert on error
      setState(() {
        if (wasUpvoted) {
          report.hasUserUpvoted = true;
          report.upvotes += 1;
        } else {
          report.hasUserUpvoted = false;
          report.upvotes -= 1;
          if (report.hasUserDownvoted) {
            report.hasUserDownvoted = true;
            report.downvotes += 1;
          }
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update vote: $e'))
      );
    }
  }
  
  void _handleDownvote(int index) async {
    final report = _reports[index];
    final wasDownvoted = report.hasUserDownvoted;
    
    setState(() {
      if (wasDownvoted) {
        report.hasUserDownvoted = false;
        report.downvotes -= 1;
      } else {
        report.hasUserDownvoted = true;
        report.downvotes += 1;
        if (report.hasUserUpvoted) {
          report.hasUserUpvoted = false;
          report.upvotes -= 1;
        }
      }
    });
    
    try {
      await _reportService.voteReport(
        report.reportId, 
        _currentUser!.id,
        wasDownvoted ? 'remove' : 'downvote'
      );
    } catch (e) {
      // Revert on error
      setState(() {
        if (wasDownvoted) {
          report.hasUserDownvoted = true;
          report.downvotes += 1;
        } else {
          report.hasUserDownvoted = false;
          report.downvotes -= 1;
          if (report.hasUserUpvoted) {
            report.hasUserUpvoted = true;
            report.upvotes += 1;
          }
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update vote: $e'))
      );
    }
  }
  
  // Convert ReportModels to the format expected by ReportPage
  List<Map<String, dynamic>> _getFormattedReports() {
    return _reports.map((report) => report.toMap()).toList();
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
        posts: _getFormattedReports(),
        scrollController: _scrollController,
        onUpvote: _handleUpvote,
        onDownvote: _handleDownvote,
        isLoading: _isLoading,
        onRefresh: _fetchReports,
      ),
      const SearchPage(),
      const LeaderboardPage(),
      NotificationPage(),
      ProfilePage(user: _currentUser),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEFF5F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF328E6E),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo and Title
            Row(
              children: [
                Image.asset(
                  'assets/logoonlyluntian.png',
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

            // Location Icon and Text
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
                    _buildNavIcon(Icons.search_rounded, 1, isSmallScreen),
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
  final Function(int) onUpvote;
  final Function(int) onDownvote;
  final ScrollController scrollController;
  final void Function()? onScrollUp;
  final void Function()? onScrollDown;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const ReportPage({
    super.key,
    required this.posts,
    required this.onUpvote,
    required this.onDownvote,
    required this.scrollController,
    this.onScrollUp,
    this.onScrollDown,
    this.isLoading = false,
    required this.onRefresh,
  });

  @override
  State<ReportPage> createState() => ReportPageState();
}

class ReportPageState extends State<ReportPage> with TickerProviderStateMixin {
  Map<int, int> currentPages = {};
  bool showFab = false;

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
        child: PhotoView(imageProvider: AssetImage(imagePath)),
      ),
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
                  Tab(text: 'Events'),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            Expanded(
              child: TabBarView(
                children: [
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
                              padding: EdgeInsets.all(screenWidth * 0.04),
                              itemCount: widget.posts.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Column(
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
                                    ],
                                  );
                                }

                                final post = widget.posts[index - 1];
                                final pageController = PageController(initialPage: currentPages[index - 1] ?? 0);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: EventCard(
                                    post: post,
                                    pageController: pageController,
                                    screenHeight: screenHeight,
                                    currentIndex: index - 1,
                                    onUpvote: widget.onUpvote,
                                    onDownvote: widget.onDownvote,
                                    onImageTap: _showImage,
                                    currentPages: currentPages,
                                  ),
                                );
                              },
                            ),
                  ),
                  const EventsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final PageController pageController;
  final double screenHeight;
  final int currentIndex;
  final Function(int) onUpvote;
  final Function(int) onDownvote;
  final void Function(BuildContext, String) onImageTap;
  final Map<int, int> currentPages;

  const EventCard({
    super.key,
    required this.post,
    required this.pageController,
    required this.screenHeight,
    required this.currentIndex,
    required this.onUpvote,
    required this.onDownvote,
    required this.onImageTap,
    required this.currentPages,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    final clampedImageHeight = (MediaQuery.of(context).orientation == Orientation.portrait
            ? screenHeight * 0.25
            : screenWidth * 0.35)
        .clamp(150.0, 300.0);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 10 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(backgroundImage: AssetImage(post['userProfile'])),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      post['username'],
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: isSmall ? 14 : 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "Top Reporter",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                post['timestamp'] ?? DateFormat('MMM dd, yyyy • h:mm a').format(DateTime.now()),
                style: TextStyle(fontSize: isSmall ? 11 : 13),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: post['priorityColor'], borderRadius: BorderRadius.circular(12)),
                child: Text(post['priorityLabel'], style: const TextStyle(color: Colors.white)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['postContent'],
                    style: const TextStyle(fontFamily: 'Poppins'),
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: clampedImageHeight,
                    child: PageView.builder(
                      itemCount: post['images'].length,
                      controller: pageController,
                      onPageChanged: (imgIndex) {
                        currentPages[currentIndex] = imgIndex;
                      },
                      itemBuilder: (context, imgIndex) {
                        String imagePath = post['images'][imgIndex];
                        return GestureDetector(
                          onTap: () => onImageTap(context, imagePath),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(imagePath, fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(post['images'].length, (dotIndex) {
                      final currentPage = currentPages[currentIndex] ?? 0;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentPage == dotIndex ? Colors.black : Colors.grey[400],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => onUpvote(currentIndex),
                        child: Column(
                          children: [
                            AnimatedScale(
                              scale: post['upvoted'] ? 1.2 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: Icon(
                                Icons.arrow_upward_rounded,
                                size: 28,
                                color: post['upvoted'] ? Colors.green : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${post['upvotes']}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 30),
                      GestureDetector(
                        onTap: () => onDownvote(currentIndex),
                        child: Column(
                          children: [
                            AnimatedScale(
                              scale: post['downvoted'] ? 1.2 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              child: Icon(
                                Icons.arrow_downward_rounded,
                                size: 28,
                                color: post['downvoted'] ? Colors.red : Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${post['downvotes']}",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        onPressed: () {
                          final isOwner = post['username'] == 'Kristel Cruz';
                          showModalBottomSheet(
                            context: context,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (context) => SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.flag),
                                    title: const Text('Report Post'),
                                    onTap: () => Navigator.pop(context),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.share),
                                    title: const Text('Share'),
                                    onTap: () => Navigator.pop(context),
                                  ),
                                  if (isOwner)
                                    ListTile(
                                      leading: const Icon(Icons.delete, color: Colors.red),
                                      title: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      onTap: () => Navigator.pop(context),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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