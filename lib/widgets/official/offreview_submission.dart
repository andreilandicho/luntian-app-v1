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
        backgroundColor: const Color.fromARGB(255, 5, 102, 181),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Submitted Images Carousel
            if (widget.solution.solutionImages.isNotEmpty)
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
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
                          return Image.network(
                            img,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 48),
                          );
                        },
                      ),
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