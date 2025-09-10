import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';

class SolvedReportCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final PageController pageController;
  final double screenHeight;
  final int currentIndex;
  final void Function(BuildContext, String) onImageTap;
  final VoidCallback onViewSolution;
  final VoidCallback onRateSolution;
  final Map<int, int> currentPages;

  const SolvedReportCard({
    super.key,
    required this.post,
    required this.pageController,
    required this.screenHeight,
    required this.currentIndex,
    required this.onImageTap,
    required this.onViewSolution,
    required this.onRateSolution,
    required this.currentPages,
  });

  void _showSolutionImages(BuildContext context, List<dynamic> images) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Solution Images",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PhotoView(
                        imageProvider: NetworkImage(images[index]),
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 2,
                      ),
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Close",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRatingModal(BuildContext context) {
    int satisfactionRating = 0;
    int responseTimeRating = 0;
    String suggestion = "";
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Rate Solution",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text("Satisfaction:"),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        Icons.star,
                        color: index < satisfactionRating ? Colors.amber : Colors.grey,
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() {
                          satisfactionRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 20),
                const Text("Response Time:"),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        Icons.star,
                        color: index < responseTimeRating ? Colors.amber : Colors.grey,
                        size: 30,
                      ),
                      onPressed: () {
                        setState(() {
                          responseTimeRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 20),
                const Text("Suggestion:"),
                const SizedBox(height: 8),
                TextField(
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Enter your suggestions here...",
                  ),
                  onChanged: (value) {
                    suggestion = value;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Submit rating logic here
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Rating submitted successfully!")),
                      );
                    },
                    child: const Text("Submit Rating"),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    final clampedImageHeight = (MediaQuery.of(context).orientation == Orientation.portrait
            ? screenHeight * 0.25
            : screenWidth * 0.35)
        .clamp(150.0, 300.0);
    
    final averageRating = post['overall_average_rating'] ?? 0.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 10 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: post['anonymous']
                  ? const AssetImage('assets/default_profile.png')
                  : (post['user_profile_url'] != null && post['user_profile_url'] != ""
                      ? NetworkImage(post['user_profile_url'])
                      : const AssetImage('assets/default_profile.png')) as ImageProvider,
              ),
              title: Text(
                post['anonymous'] ? 'Anonymous Citizen' : post['username'] ?? 'Unknown User',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: isSmall ? 14 : 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                DateFormat('MMM dd, yyyy • h:mm a').format(DateTime.parse(post['created_at'])),
                style: TextStyle(fontSize: isSmall ? 11 : 13),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Solved",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post['description'] ?? '',
                    style: const TextStyle(fontFamily: 'Poppins'),
                    overflow: TextOverflow.visible,
                  ),
                  const SizedBox(height: 12),
                  if (post['photo_urls'] != null && post['photo_urls'].isNotEmpty)
                    SizedBox(
                      height: clampedImageHeight,
                      child: PageView.builder(
                        itemCount: post['photo_urls'].length,
                        controller: pageController,
                        onPageChanged: (imgIndex) {
                          currentPages[currentIndex] = imgIndex;
                        },
                        itemBuilder: (context, imgIndex) {
                          String imageUrl = post['photo_urls'][imgIndex];
                          return GestureDetector(
                            onTap: () => onImageTap(context, imageUrl),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[300],
                                  child: const Center(child: CircularProgressIndicator()),
                                ),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  if (post['photo_urls'] != null && post['photo_urls'].isNotEmpty)
                    const SizedBox(height: 10),
                  if (post['photo_urls'] != null && post['photo_urls'].isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(post['photo_urls'].length, (dotIndex) {
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
                  const SizedBox(height: 16),
                  // Solution details
                  if (post['cleanup_notes'] != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Solution:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          post['cleanup_notes'],
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  // Rating display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Rating: ",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(5, (index) {
                        return Icon(
                          Icons.star,
                          color: index < averageRating.round() ? Colors.amber : Colors.grey,
                          size: 24,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        "(${averageRating.toStringAsFixed(1)})",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Buttons for solved reports
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showSolutionImages(context, post['after_photo_urls'] ?? []),
                        icon: const Icon(Icons.visibility),
                        label: const Text("View Solution"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF328E6E),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showRatingModal(context),
                        icon: const Icon(Icons.star_rate),
                        label: const Text("Rate Solution"),
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