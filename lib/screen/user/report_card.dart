import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/report_model.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/services/report_deletion.dart';

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
  final VoidCallback? onDeleted;

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
    this.onDeleted,
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
  Future<void> _confirmDeleteReport(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text(
          'Are you sure you want to delete this report? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && context.mounted) {
      await _deleteReport(context);
    }
  }

  Future<void> _deleteReport(BuildContext context) async {
    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Deleting report...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final deleteService = DeleteService();
      await deleteService.deleteReport(post['report_id'], currentUserId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        if (onDeleted != null) {
          onDeleted!();
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
                    if (post['priority'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(post['priority']),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            post['priority'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ReportModel.getStatusColor(post['status'] ?? 'pending'),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post['status'] ?? 'Pending',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded),
                      onPressed: () {
                        final isOwner = post['user_id'] == currentUserId;
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
                                      title: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _confirmDeleteReport(context);
                                      },
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