import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReportCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final PageController pageController;
  final double screenHeight;
  final int currentIndex;
  final Function(int) onUpvote;
  final Function(int) onDownvote;
  final void Function(BuildContext, String) onImageTap;
  final Map<int, int> currentPages;
  final int currentUserId; 

  const ReportCard({
    super.key,
    required this.post,
    required this.pageController,
    required this.screenHeight,
    required this.currentIndex,
    required this.onUpvote,
    required this.onDownvote,
    required this.onImageTap,
    required this.currentPages,
    required this.currentUserId, 
  });

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

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
              leading: CircleAvatar(
                backgroundImage: post['anonymous'] 
                  ? const AssetImage('assets/default_profile.png') 
                  : (post['user_profile_url'] != null 
                      ? NetworkImage(post['user_profile_url']) 
                      : const AssetImage('assets/default_profile.png')) as ImageProvider,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      post['anonymous'] ? 'Anonymous Citizen' : post['username'] ?? 'Unknown User',
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
                    child: Text(
                      post['status'] ?? 'Pending',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                DateFormat('MMM dd, yyyy • h:mm a').format(DateTime.parse(post['created_at'])),
                style: TextStyle(fontSize: isSmall ? 11 : 13),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(post['priority']),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  post['priority'] ?? 'Unknown',
                  style: const TextStyle(color: Colors.white),
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
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => onUpvote(currentIndex),
                        child: Column(
                          children: [
                            Icon(
                              Icons.arrow_upward_rounded,
                              size: 28,
                              color: post['has_user_upvoted'] ? Colors.green : Colors.grey[700],
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
                            Icon(
                              Icons.arrow_downward_rounded,
                              size: 28,
                              color: post['has_user_downvoted'] ? Colors.red : Colors.grey[700],
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
                          final isOwner = post['user_id'] == currentUserId; // You'll need to pass currentUserId
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