import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_application_1/screen/user/add_event_screen.dart';
import 'package:flutter_application_1/services/event_service.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/models/homepage_event_model.dart';
import 'package:flutter_application_1/models/user_model.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final EventService _eventService = EventService();
  final AuthService _authService = AuthService();
  List<HomepageEventModel> _publicEvents = [];
  List<HomepageEventModel> _barangayEvents = [];
  bool _isLoadingPublic = true;
  bool _isLoadingBarangay = true;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserAndEvents();
  }

  Future<void> _loadUserAndEvents() async {
    try {
      final user = await _authService.getCurrentUser();
      setState(() {
        _currentUser = user;
      });
      await _fetchPublicEvents();
      await _fetchBarangayEvents();
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _fetchPublicEvents() async {
    setState(() => _isLoadingPublic = true);
    try {
      final events = await _eventService.getPublicEvents();
      setState(() => _publicEvents = events);
    } catch (e) {
      print('Error fetching public events: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load public events: $e')),
      );
    } finally {
      setState(() => _isLoadingPublic = false);
    }
  }

  Future<void> _fetchBarangayEvents() async {
    if (_currentUser?.barangayId == null) {
      setState(() => _isLoadingBarangay = false);
      return;
    }
    
    setState(() => _isLoadingBarangay = true);
    try {
      final events = await _eventService.getBarangayEvents(_currentUser!.barangayId!);
      setState(() => _barangayEvents = events);
    } catch (e) {
      print('Error fetching barangay events: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load barangay events: $e')),
      );
    } finally {
      setState(() => _isLoadingBarangay = false);
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchPublicEvents();
    await _fetchBarangayEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait = screenHeight > screenWidth;
    final isSmall = screenWidth < 400;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF328E6E),
            labelColor: const Color(0xFF328E6E),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Public Events'),
              Tab(text: 'Barangay Events'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Public Events Tab
            _buildEventsTab(
              events: _publicEvents,
              isLoading: _isLoadingPublic,
              onRefresh: _fetchPublicEvents,
              screenWidth: screenWidth,
              screenHeight: screenHeight,
              isPortrait: isPortrait,
              isSmall: isSmall,
            ),
            
            // Barangay Events Tab
            _currentUser?.barangayId != null
                ? _buildEventsTab(
                    events: _barangayEvents,
                    isLoading: _isLoadingBarangay,
                    onRefresh: _fetchBarangayEvents,
                    screenWidth: screenWidth,
                    screenHeight: screenHeight,
                    isPortrait: isPortrait,
                    isSmall: isSmall,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_outline, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          "Please log in to view barangay events",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadUserAndEvents,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab({
    required List<HomepageEventModel> events,
    required bool isLoading,
    required Future<void> Function() onRefresh,
    required double screenWidth,
    required double screenHeight,
    required bool isPortrait,
    required bool isSmall,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final content = RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEventScreen()),
              );
            },
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.03),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: Color(0xFF328E6E)),
                    SizedBox(width: screenWidth * 0.025),
                    const Text(
                      "Add a new event...",
                      style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          if (events.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.event_busy, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "No events available",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: onRefresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else
            ...events.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: EventCard(event: event),
                )),
          const SizedBox(height: 16),
          if (isPortrait)
            Center(
              child: Text(
                "Swipe down to refresh",
                style: TextStyle(fontSize: isSmall ? 12 : 14, color: Colors.grey),
              ),
            ),
        ],
      ),
    );

    return isPortrait
        ? ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: content,
          )
        : content;
  }
}

class EventCard extends StatefulWidget {
  final HomepageEventModel event;

  const EventCard({super.key, required this.event});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool interested = false;
  int currentImage = 0;

  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
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
            // Header
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: isSmall ? 16 : 20,
                backgroundImage: const AssetImage('assets/profile picture.png'),
              ),
              title: Row(
                children: [
                  Text(
                    "Kristel Cruz",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isSmall ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Top Volunteer",
                      style: TextStyle(
                        fontSize: isSmall ? 9 : 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                DateFormat('MMM dd, yyyy • h:mm a').format(DateTime.now()),
                style: TextStyle(fontSize: isSmall ? 11 : 13),
              ),
            ),

            // Event Details
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.event.title} — ${widget.event.date != null ? DateFormat('MMM dd, yyyy • h:mm a').format(widget.event.date!) : 'No date'}",
                    style: TextStyle(
                      fontSize: isSmall ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text("Location: ${widget.event.location}"),
                  const SizedBox(height: 6),
                  const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(widget.event.description ?? ''),
                  const SizedBox(height: 6),
                ],
              ),
            ),

            // Image Carousel
            if (widget.event.imageUrls != null && widget.event.imageUrls!.isNotEmpty) ...[
              SizedBox(
                height: clampedImageHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: PageView.builder(
                    itemCount: widget.event.imageUrls!.length,
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => currentImage = index),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => _showFullScreenImage(context, widget.event.imageUrls![index]),
                      child: Image.network(
                        widget.event.imageUrls![index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.error_outline, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.event.imageUrls!.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: currentImage == index ? Colors.black : Colors.grey[400],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
            ],

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() => interested = !interested),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: interested ? Colors.green : Colors.grey[300],
                    foregroundColor: interested ? Colors.white : Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(interested ? Icons.favorite : Icons.favorite_border),
                  label: Text(
                    interested ? "Interested" : "Interested",
                    style: TextStyle(fontSize: isSmall ? 12 : 14),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
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
                              title: const Text('Report Event'),
                              onTap: () => Navigator.pop(context),
                            ),
                            ListTile(
                              leading: const Icon(Icons.share),
                              title: const Text('Share'),
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
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: PhotoView(
            imageProvider: NetworkImage(imageUrl),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
            loadingBuilder: (context, event) => Center(
              child: CircularProgressIndicator(
                value: event == null
                    ? 0
                    : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              ),
            ),
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Icon(Icons.error_outline, color: Colors.white, size: 50),
            ),
          ),
        ),
      ),
    );
  }
}