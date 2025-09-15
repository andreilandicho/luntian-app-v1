import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_application_1/screen/user/add_event_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {}); // Dummy refresh
  }

@override
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final isPortrait = screenHeight > screenWidth;
  final isSmall = screenWidth < 400;

  final content = ListView(
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
    SizedBox(height: screenHeight * 0.015), // same spacing between add card and list
    ...List.generate(
      3,
      (index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: EventCard(),
      ),
    ),
      const SizedBox(height: 16),
      if (isPortrait)
        Center(
          child: Text(
            "Swipe down to refresh",
            style: TextStyle(fontSize: isSmall ? 12 : 14, color: Colors.grey),
          ),
        ),
    ],
  );

  return RefreshIndicator(
    onRefresh: _handleRefresh,
    child: Center(
      child: isPortrait
          ? ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: content,
            )
          : content,
    ),
  );
  }
}

class EventCard extends StatefulWidget {
  const EventCard({super.key});

  @override
  State<EventCard> createState() => _EventCardState();
}

class _EventCardState extends State<EventCard> {
  bool interested = false;
  int currentImage = 0;

  final PageController _pageController = PageController();
  final List<String> imagePaths = [
    'assets/garbage.png',
    'assets/garbage.png',
    'assets/garbage.png',
  ];

  final Map<String, dynamic> post = {
    'title': 'Barangay Cleanup Drive',
    'dateTime': 'July 28, 2025 • 9:00 AM',
    'volunteers': 24,
    'description': 'A cleanup event around the Barangay Hall and nearby streets.',
    'additionalInfo': 'Bring gloves and garbage bags.',
  };

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
                    "${post['title']} — ${post['dateTime']}",
                    style: TextStyle(
                      fontSize: isSmall ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text("Volunteers Needed: ${post['volunteers']}"),
                  const SizedBox(height: 6),
                  const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(post['description']),
                  const SizedBox(height: 6),
                  if (post['additionalInfo'] != null && post['additionalInfo'].isNotEmpty) ...[
                    const Text("Additional Info:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(post['additionalInfo']),
                  ],
                ],
              ),
            ),

            // Image Carousel
            if (imagePaths.isNotEmpty) ...[
              SizedBox(
                height: clampedImageHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: PageView.builder(
                    itemCount: imagePaths.length,
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => currentImage = index),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => _showFullScreenImage(context),
                      child: Image.asset(
                        imagePaths[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(imagePaths.length, (index) {
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
                    interested ? "Interested (25)" : "Interested (24)",
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

  void _showFullScreenImage(BuildContext context) {
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
            imageProvider: AssetImage(imagePaths[currentImage]),
            backgroundDecoration: const BoxDecoration(color: Colors.black),
          ),
        ),
      ),
    );
  }
}