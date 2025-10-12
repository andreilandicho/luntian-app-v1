// review_submission_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/maintenance/submitted_solutions.dart';
import 'package:url_launcher/url_launcher.dart';

class ReviewSubmissionPage extends StatefulWidget {
  final SubmittedSolution solution;

  const ReviewSubmissionPage({super.key, required this.solution});

  @override
  State<ReviewSubmissionPage> createState() => _ReviewSubmissionPageState();
}

class _ReviewSubmissionPageState extends State<ReviewSubmissionPage> {
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(221, 221, 221, 1),
      appBar: AppBar(
        title: const Text('Review Submission'),
        backgroundColor: const Color(0xFF328E6E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Submitted Images Carousel with full-screen tap
if (widget.solution.solutionImages.isNotEmpty)
  Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            SizedBox(
              height: 300,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.solution.solutionImages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final img = widget.solution.solutionImages[index];
                  return Hero(
                    tag: img,
                    child: Image.network(
                      img,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 48),
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
                        builder: (_) => FullScreenSolutionImageView(
                          images: widget.solution.solutionImages,
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
      if (widget.solution.solutionImages.length > 1)
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.solution.solutionImages.asMap().entries.map((entry) {
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
      const SizedBox(height: 20),
    ],
  ),
            // Cleanup Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cleanup Notes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.solution.cleanupNotes),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Report Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Reporter info
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: AssetImage(widget.solution.profileImage),
                          radius: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.solution.reporterName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Description
                    Text(widget.solution.description),
                    const SizedBox(height: 12),
                    // Location
                    if (widget.solution.lat != null && widget.solution.lon != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.red),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              final url = 'https://www.google.com/maps/place/'
                                  '${widget.solution.lat},${widget.solution.lon}/'
                                  '@${widget.solution.lat},${widget.solution.lon},20z/data=!3m1!1e3';
                              launchUrl(Uri.parse(url));
                            },
                            child: Text(
                              'View on Map',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.blue, // No underline
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/// Full-screen image view with carousel for Solution Images
class FullScreenSolutionImageView extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenSolutionImageView({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenSolutionImageView> createState() => _FullScreenSolutionImageViewState();
}

class _FullScreenSolutionImageViewState extends State<FullScreenSolutionImageView> {
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
                    child: Image.network(
                      img,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image, size: 48, color: Colors.white),
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