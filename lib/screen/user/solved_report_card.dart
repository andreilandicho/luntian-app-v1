import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart'; // For image gallery view of solution images
import '../../services/rating_service.dart';
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

  //fix view solution images
  void _showSolutionImages(BuildContext context, List<dynamic> images) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8), // optional margin around the dialog
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Solution Images",
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white54, height: 1),
              // Gallery
              Expanded(
                child: PhotoViewGallery.builder(
                  itemCount: images.length,
                  builder: (context, index) {
                    return PhotoViewGalleryPageOptions(
                      imageProvider: NetworkImage(images[index]),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 2,
                    );
                  },
                  scrollPhysics: const BouncingScrollPhysics(),
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                  loadingBuilder: (context, event) => const Center(
                    child: CircularProgressIndicator(),
                  ),
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
                  onPressed: satisfactionRating == 0 || responseTimeRating == 0
                      ? null // Disable button if ratings are not selected
                      : () async {
                          try {
                            // Show loading
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            // Call the API
                            print('Submitting rating for reportId: ${post['report_id']}');
                            await RatingService.submitRating(
                              reportId: post['report_id'],
                              satisfactionStars: satisfactionRating,
                              responseTimeStars: responseTimeRating,
                              comments: suggestion,
                            ).timeout(Duration(seconds: 10));

                            // Close loading and modal
                            Navigator.of(context).pop(); // Close loading
                            Navigator.of(context).pop(); // Close modal

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Rating submitted successfully!")),
                            );

                            // Refresh the card to show "View Rating" button
                            // You might want to trigger a state refresh here
                            // For example: widget.onRatingSubmitted?.call();
                            

                          } catch (e) {
                            Navigator.of(context).pop(); // Close loading if open
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to submit rating: $e")),
                            );
                          }
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
  void _showViewRatingModal(BuildContext context, Map<String, dynamic>? userRating) {
  if (userRating == null) return;
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Rating",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Text("Satisfaction: ${userRating['satisfaction_stars'] ?? '-'} / 5"),
          Text("Response Time: ${userRating['response_time_stars'] ?? '-'} / 5"),
          if (userRating['comments'] != null && userRating['comments'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text("Comments: ${userRating['comments']}"),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text("Delete Rating"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                // Call my delete rating API here
                try {
                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  await RatingService.deleteRating(userRating['rating_id']);

                  Navigator.pop(context); // Close loading
                  Navigator.pop(context); // Close modal

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Rating deleted successfully!")),
                  );

                  // Refresh the card to show "Rate Solution" button again
                  // You might want to trigger a state refresh here

                } catch (e) {
                  Navigator.pop(context); // Close loading if open
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to delete rating: $e")),
                  );
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    print('Report ${post['report_id']} has_user_rated: ${post['has_user_rated']} (${post['has_user_rated'].runtimeType})');
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;
    final clampedImageHeight = (MediaQuery.of(context).orientation == Orientation.portrait
            ? screenHeight * 0.25
            : screenWidth * 0.35)
        .clamp(150.0, 300.0);
    
    final averageRating = (post['overall_average_rating'] ?? 0.0).toDouble();

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
              //fix fetch profile picture in home screen
              backgroundImage: post['anonymous']
                  ? const AssetImage('assets/profile picture.png')
                  : (post['user_profile_url'] != null &&
                    post['user_profile_url'].toString().startsWith('http'))
                      ? NetworkImage(post['user_profile_url'])
                      : const AssetImage('assets/profile picture.png'),
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
                          color: index < (averageRating?.round() ?? 0) ? Colors.amber : Colors.grey,

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
                      if (post['has_user_rated'] == true || post['has_user_rated'] == 1 || post['has_user_rated'] == 'true')
                        ElevatedButton.icon(
                          onPressed: () => _showViewRatingModal(context, post['user_rating']),
                          icon: const Icon(Icons.star),
                          label: const Text("View Rating"),
                        )
                      else
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