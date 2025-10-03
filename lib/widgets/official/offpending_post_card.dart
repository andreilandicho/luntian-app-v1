import 'package:flutter/material.dart';
import 'package:flutter_application_1/screen/official_mobile/action.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PendingPostCard extends StatefulWidget {
  final int reportId;
  final String reporterName;
  final String profileImage;
  final String reportDate;
  final String priority;
  final List<String> postImages;
  final String description;
  final String? descriptiveLocation;
  final bool isHazardous;
  final String reportCategory;
  final List<String> assignedOfficials;
  final String status;
  final DateTime? reportDeadline;
  final double? lat;
  final double? lon;

  const PendingPostCard({
    super.key,
    required this.reportId,
    required this.reporterName,
    required this.profileImage,
    required this.reportDate,
    required this.priority,
    required this.postImages,
    required this.description,
    this.descriptiveLocation,
    this.isHazardous = false,
    required this.reportCategory,
    required this.assignedOfficials,
    required this.status,
    required this.reportDeadline,
    this.lat,
    this.lon,
  });

  @override
  State<PendingPostCard> createState() => _PendingPostCardState();
}

class _PendingPostCardState extends State<PendingPostCard> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  Color _priorityColor(String p) {
    switch (p.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Widget _pill({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(1),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(widget.profileImage),
                  radius: 25,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.reporterName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(widget.reportDate,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Only show priority badge
                _pill(label: widget.priority, color: _priorityColor(widget.priority)),
              ],
            ),

            const SizedBox(height: 12),

            // Image Carousel with swipe navigation
            if (widget.postImages.isNotEmpty)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 200,
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: widget.postImages.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              final img = widget.postImages[index];
                              return Hero(
                                tag: img,
                                child: img.startsWith('http')
                                  ? Image.network(
                                      img,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.broken_image, size: 48),
                                    )
                                  : Image.asset(
                                      img,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                              );
                            },
                          ),
                        ),
                        // Tap to fullscreen
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenImageView(
                                      images: widget.postImages,
                                      initialIndex: _currentImageIndex,
                                    ),
                                  ),
                                );
                              },
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.postImages.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: widget.postImages.asMap().entries.map((entry) {
                          return Container(
                            width: 8.0,
                            height: 8.0,
                            margin: const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == entry.key
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 12),

            // Location Row
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.red),
                const SizedBox(width: 4),
                (widget.lat != null && widget.lon != null)
                    ? GestureDetector(
                        onTap: () {
                          final url =
                              'https://www.google.com/maps/place/${widget.lat},${widget.lon}/@${widget.lat},${widget.lon},20z/data=!3m1!1e3';
                          launchUrl(Uri.parse(url));
                        },
                        child: const Text(
                          'View on Map',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.blue,
                            
                          ),
                        ),
                      )
                    : const Text(
                        'Map data not available',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
              ],
            ),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(widget.description),
            ),

            // Report Details Button - Size-matched to Take a Photo
const SizedBox(height: 8),
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    OutlinedButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (context) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Bar with Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Report Details",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text("Descriptive Location: ${widget.descriptiveLocation != null && widget.descriptiveLocation!.isNotEmpty ? widget.descriptiveLocation : "No location provided"}"),
                  Text("Category: ${widget.reportCategory}"),
                  Text("Hazardous: ${widget.isHazardous ? "Yes" : "No"}"),
                  Text("Priority: ${widget.priority}"),
                  Text("Assigned to: ${widget.assignedOfficials.isNotEmpty ? widget.assignedOfficials.join(', ') : 'None'}"),
                  Text("Date & Time: ${widget.reportDate}"),
                  Text("Status: ${widget.status}"),
                  Text(
                    "Deadline: ${widget.reportDeadline != null ? DateFormat('yyyy-MM-dd').format(widget.reportDeadline!) : 'No deadline'}",
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          },
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.green,
        side: const BorderSide(color: Colors.green),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline),
          SizedBox(width: 8),
          Text(
            "Report Details",
            style: TextStyle(
              color: Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  ],
),

// Action Button - Remains unchanged, for reference
const SizedBox(height: 8),
Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProofAction(reportId: widget.reportId),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 5, 102, 181),
        padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        "Take a Photo",
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ],
),
          ],
        ),
      ),
    );
  }
}

/// Full-screen image view with carousel
class FullScreenImageView extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageView({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenImageView> createState() => _FullScreenImageViewState();
}

class _FullScreenImageViewState extends State<FullScreenImageView> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // PageView for images with swipe navigation
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final img = widget.images[index];
              return GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Hero(
                  tag: img,
                  child: Center(
                    child: img.startsWith('http')
                        ? Image.network(
                            img,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 48, color: Colors.white),
                          )
                        : Image.asset(
                            img,
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
              );
            },
          ),

          // Close button
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Image indicators (if multiple images)
          if (widget.images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.images.asMap().entries.map((entry) {
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == entry.key
                          ? Colors.white
                          : Colors.grey,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// Dummy usage example (for testing in another widget)
/*
PendingPostCard(
  reporterName: "Juan Dela Cruz",
  profileImage: "assets/profile.png",
  reportTime: "10:30 AM",
  reportDate: "2025-09-22",
  priority: "High",
  postImages: ["assets/sample1.jpg", "assets/sample2.jpg"],
  description: "Overflowing garbage at the corner of the street.",
  location: "Purok 3, Barangay Malinis",
  isHazardous: true,
  reportCategory: "Garbage",
  assignedOfficials: ["Brgy. Captain Reyes", "Kagawad Santos"],
  status: "Pending",
  reportDeadline: "2025-09-25",
  lat: 13.9401,
  lon: 121.1631,
)
*/