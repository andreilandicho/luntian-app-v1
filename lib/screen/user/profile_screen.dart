import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/models/report_model.dart';
import 'package:flutter_application_1/services/report_service.dart';
import 'package:flutter_application_1/services/profile_service.dart';  // Import your existing service
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/screen/user/add_event_screen.dart';
import 'package:flutter_application_1/screen/user/login_screen.dart';4
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_application_1/utils/image_helper.dart';

class ProfilePage extends StatefulWidget {
  final UserModel? user;
  
  const ProfilePage({super.key, this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  String profilePic = 'assets/profile picture.png';
  late String userName;
  late String address;
  bool isLoading = true;
  
  // Services
  final _reportService = ReportService();
  final _profileService = ProfileService();  // Use your existing ProfileService
  final _authService = AuthService();
  
  // Data containers
  List<ReportModel> userReports = [];
  List<Map<String, dynamic>> userEvents = [];
  List<Map<String, dynamic>> allBadges = [];
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (widget.user == null) {
      setState(() {
        userName = 'Guest User';
        address = 'Location not set';
        isLoading = false;
      });
      return;
    }
    
    setState(() {
      userName = widget.user!.name ?? 'User';
      // Generate address based on barangay ID if available
      address = widget.user!.barangayId != null 
          ? 'Barangay ${widget.user!.barangayId}'
          : 'Location not set';
    });
    
    try {
      // Load user reports
      final reports = await _reportService.getUserReports(widget.user!.id);
      
      // Load user events
      final events = await _reportService.getUserEvents(widget.user!.id);
      
      // Load badges
      final badges = await _profileService.getUserBadges(widget.user!.id);
      
      setState(() {
        userReports = reports;
        userEvents = events;
        allBadges = badges;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Helper method to convert ReportModel to the format needed by UI
  Map<String, dynamic> _reportModelToUiFormat(ReportModel report) {
    Color statusColor;
    switch (report.status?.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'in progress':
        statusColor = Colors.blue;
        break;
      case 'resolved':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return {
      'username': userName,
      'userProfile': profilePic,
      'images': report.photoUrls ?? ['assets/garbage.png'],
      'postContent': report.description ?? 'No description',
      'statusLabel': report.status ?? 'Unknown',
      'statusColor': statusColor,
      'timestamp': _formatTimestamp(report.createdAt),
      'upvoted': report.hasUserUpvoted,
      'downvoted': report.hasUserDownvoted,
      'upvotes': report.upvotes,
      'downvotes': report.downvotes,
    };
  }
  
  // Format timestamp to readable format
  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Only show up to 5 earned badges
  List<Map<String, dynamic>> get earnedBadges =>
      allBadges.where((b) => b['earned'] == true).take(5).toList();

  void _showEventOptions(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share functionality not implemented')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event deleted')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _changeProfilePicture() async {
  final picker = ImagePicker();
  
  try {
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Compress image for faster upload
    );

    if (pickedFile != null && widget.user != null) {
      // Show loading indicator
      setState(() {
        isLoading = true;
      });
      
      // Temporarily show the picked image while uploading
      setState(() {
        profilePic = pickedFile.path;
      });
      
      try {
        // Upload to Supabase storage through our API
        final imageUrl = await _profileService.uploadProfilePicture(
          widget.user!.id, 
          pickedFile.path
        );
        
        if (imageUrl != null) {
          // Update the user profile with the new image URL
          await _profileService.updateUserProfile(
            userId: widget.user!.id,
            profilePicUrl: imageUrl
          );
          
          // Cache the network image locally for faster loading
          final localPath = await ImageHelper.saveNetworkImageLocally(
            imageUrl,
            customName: 'profile_${widget.user!.id}${path.extension(imageUrl)}'
          );
          
          setState(() {
            profilePic = localPath ?? imageUrl;
            isLoading = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully'))
          );
        } else {
          // Keep using the local file if upload fails
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image to server. Using local copy.'))
          );
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        print('Error uploading profile picture: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image to server'))
        );
        setState(() {
          isLoading = false;
        });
      }
    }
  } catch (e) {
    print('Error picking image: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error selecting image'))
    );
    setState(() {
      isLoading = false;
    });
  }
}

  void _editNameOrAddress() {
    final nameController = TextEditingController(text: userName);
    final streetController = TextEditingController();
    final floorUnitController = TextEditingController();
    final cityController = TextEditingController();

    // Extract existing address components
    List<String> parts = address.split(', ');
    if (parts.isNotEmpty) streetController.text = parts[0];
    if (parts.length > 2) {
      floorUnitController.text = parts[1];
      cityController.text = parts.sublist(2).join(', ');
    } else if (parts.length > 1) {
      cityController.text = parts[1];
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: streetController,
                  decoration: const InputDecoration(labelText: 'Street Address'),
                ),
                TextField(
                  controller: floorUnitController,
                  decoration: const InputDecoration(labelText: 'Floor/Unit (Optional)'),
                ),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'City / Municipality'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Update local state immediately for responsiveness
                setState(() {
                  userName = nameController.text;
                  
                  // Combine address fields
                  String newAddress = streetController.text;
                  if (floorUnitController.text.isNotEmpty) {
                    newAddress += ', ${floorUnitController.text}';
                  }
                  if (cityController.text.isNotEmpty) {
                    newAddress += ', ${cityController.text}';
                  }
                  address = newAddress;
                });
                
                // Then update the backend if user is logged in
                if (widget.user != null) {
                  try {
                    await _profileService.updateUserProfile(
                      userId: widget.user!.id,
                      name: nameController.text,
                      address: address,
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update profile: $e')),
                    );
                  }
                }
                
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  void _showAllBadges() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Badges'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allBadges.length,
            itemBuilder: (context, index) {
              final badge = allBadges[index];
              return ListTile(
                leading: Icon(
                  badge['earned'] ? Icons.emoji_events : Icons.lock_outline,
                  color: badge['earned'] ? Colors.green : Colors.grey,
                ),
                title: Text(
                  badge['name'],
                  style: TextStyle(
                    color: badge['earned'] ? Colors.black : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                badge['goal'] != null
                    ? '${badge['progress']}/${badge['goal']} ${badge['description'].toLowerCase()}'
                    : badge['description'],
                style: TextStyle(
                  color: badge['earned'] ? Colors.black87 : Colors.grey[600],
                ),
              ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showImage(String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: PhotoView(
          imageProvider: path.startsWith('http')
            ? NetworkImage(path) as ImageProvider
            : path.startsWith('assets/')
              ? AssetImage(path)
              : FileImage(File(path)),
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> post) {
    int currentImageIndex = 0;
    PageController pageController = PageController();

    return StatefulBuilder(
      builder: (context, setLocalState) {
        final screenSize = MediaQuery.of(context).size;
        final baseScale = screenSize.shortestSide.clamp(320.0, 480.0);
        final imageHeight = baseScale * 0.6;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: _getImageProvider(profilePic),
                  radius: baseScale * 0.06,
                ),
                title: Text(
                  userName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(post['timestamp'] ?? DateFormat('MMM dd, yyyy • h:mm a').format(DateTime.now())),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: post['statusColor'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    post['statusLabel'],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post['postContent'],
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                    const SizedBox(height: 10),
                    if (post['images'] != null && post['images'].isNotEmpty) ...[
                      SizedBox(
                        height: imageHeight,
                        width: double.infinity,
                        child: PageView.builder(
                          controller: pageController,
                          itemCount: post['images'].length,
                          onPageChanged: (index) =>
                              setLocalState(() => currentImageIndex = index),
                          itemBuilder: (context, imgIndex) {
                            final imagePath = post['images'][imgIndex];
                            return GestureDetector(
                              onTap: () => _showImage(imagePath),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imagePath.startsWith('http')
                                  ? Image.network(
                                      imagePath,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      loadingBuilder: (ctx, child, progress) {
                                        if (progress == null) return child;
                                        return Center(child: CircularProgressIndicator(
                                          value: progress.expectedTotalBytes != null
                                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                            : null,
                                        ));
                                      },
                                    )
                                  : Image.asset(
                                      imagePath,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(post['images'].length, (index) {
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: currentImageIndex == index
                                    ? Colors.black
                                    : Colors.grey[300],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setLocalState(() {
                              post['upvoted'] = !(post['upvoted'] ?? false);
                              if (post['upvoted']) {
                                post['upvotes'] = (post['upvotes'] ?? 0) + 1;
                                if (post['downvoted'] ?? false) {
                                  post['downvoted'] = false;
                                  post['downvotes'] = (post['downvotes'] ?? 1) - 1;
                                }
                              } else {
                                post['upvotes'] = (post['upvotes'] ?? 1) - 1;
                              }
                            });
                          },
                          child: AnimatedScale(
                            scale: post['upvoted'] == true ? 1.4 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.elasticOut,
                            child: Icon(Icons.arrow_upward_rounded,
                                size: baseScale * 0.07,
                                color: post['upvoted'] == true
                                    ? Colors.green
                                    : Colors.grey[700]),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text((post['upvotes'] ?? 0).toString()),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            setLocalState(() {
                              post['downvoted'] = !(post['downvoted'] ?? false);
                              if (post['downvoted']) {
                                post['downvotes'] = (post['downvotes'] ?? 0) + 1;
                                if (post['upvoted'] ?? false) {
                                  post['upvoted'] = false;
                                  post['upvotes'] = (post['upvotes'] ?? 1) - 1;
                                }
                              } else {
                                post['downvotes'] = (post['downvotes'] ?? 1) - 1;
                              }
                            });
                          },
                          child: AnimatedScale(
                            scale: post['downvoted'] == true ? 1.4 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.elasticOut,
                            child: Icon(Icons.arrow_downward_rounded,
                                size: baseScale * 0.07,
                                color: post['downvoted'] == true
                                    ? Colors.red
                                    : Colors.grey[700]),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text((post['downvotes'] ?? 0).toString()),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (context) => SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.share),
                                  title: const Text('Share'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Share not implemented')),
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.delete, color: Colors.red),
                                  title: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Post deleted')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> post) {
    return LayoutBuilder(builder: (context, constraints) {
      final screenSize = MediaQuery.of(context).size;
      final baseScale = screenSize.shortestSide.clamp(320.0, 480.0);
      final imageHeight = baseScale * 0.6;

      return Stack(
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.only(top: 12, right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: _getImageProvider(profilePic),
                      radius: baseScale * 0.06,
                    ),
                    title: Text(
                      userName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(post['createdAt'] != null 
                      ? DateFormat('MMM dd, yyyy • h:mm a').format(DateTime.parse(post['createdAt']))
                      : DateFormat('MMM dd, yyyy • h:mm a').format(DateTime.now())),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: post['statusColor'] ?? Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        post['statusLabel'] ?? 'Unknown',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${post['title'] ?? 'Untitled Event'} — ${post['dateTime'] ?? 'Date TBD'}",
                          style: TextStyle(
                            fontSize: baseScale * 0.045,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text("Volunteers Needed: ${post['volunteers'] ?? 'Unknown'}"),
                        const SizedBox(height: 6),
                        const Text("Description:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(post['description'] ?? 'No description available'),
                        const SizedBox(height: 6),
                        if (post['additionalInfo'] != null && post['additionalInfo'].isNotEmpty) ...[
                          const Text("Additional Info:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(post['additionalInfo']),
                        ],
                      ],
                    ),
                  ),
                  if (post['images'] != null && post['images'].isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: StatefulBuilder(
                        builder: (context, setLocalState) {
                          int currentImageIndex = 0;
                          final pageController = PageController();

                          return Column(
                            children: [
                              SizedBox(
                                height: imageHeight,
                                child: PageView.builder(
                                  controller: pageController,
                                  itemCount: post['images'].length,
                                  onPageChanged: (index) =>
                                      setLocalState(() => currentImageIndex = index),
                                  itemBuilder: (context, imgIndex) {
                                    final imagePath = post['images'][imgIndex];
                                    return GestureDetector(
                                      onTap: () => _showImage(imagePath),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: imagePath.startsWith('http')
                                          ? Image.network(
                                              imagePath,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              loadingBuilder: (ctx, child, progress) {
                                                if (progress == null) return child;
                                                return Center(child: CircularProgressIndicator(
                                                  value: progress.expectedTotalBytes != null
                                                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                                    : null,
                                                ));
                                              },
                                            )
                                          : Image.asset(
                                              imagePath,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(post['images'].length, (index) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: currentImageIndex == index
                                          ? Colors.black
                                          : Colors.grey[300],
                                    ),
                                  );
                                }),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (post['adminComment'] != null && post['adminComment'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(
                        "Admin Comment: ${post['adminComment']}",
                        style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => _showEventOptions(post),
                        ),
                        if (post['statusLabel'] == 'Approved')
                          ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Event posted successfully')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF328E6E),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.publish),
                            label: const Text("Post"),
                          )
                        else if (post['statusLabel'] == 'For Revision')
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddEventScreen(existingEvent: post),
                                ),
                              );
                            },
                            child: const Text('Revise Details'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
  
  // Helper method for image providers
  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http')) {
      return NetworkImage(path);
    } else if (path.startsWith('assets/')) {
      return AssetImage(path);
    } else {
      return FileImage(File(path));
    }
  }
  
  // Helper for empty state display
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final baseScale = screenSize.shortestSide.clamp(320.0, 480.0);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final reportWidgets = userReports.isEmpty 
      ? [_buildEmptyState("You haven't posted any reports yet")] 
      : userReports.map((report) => _buildReportCard(_reportModelToUiFormat(report))).toList();
    
    final eventWidgets = userEvents.isEmpty
      ? [_buildEmptyState("You haven't participated in any events yet")]
      : userEvents.map((event) => _buildEventCard(event)).toList();

    return DefaultTabController(
      length: 2,
      child: RefreshIndicator(
        onRefresh: () async => _loadUserData(),
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Logout'),
                              content: const Text('Are you sure you want to log out of your account?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _logout();
                                  },
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: baseScale * 0.13,
                        backgroundImage: _getImageProvider(profilePic),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: _changeProfilePicture,
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.edit, size: 18, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _editNameOrAddress,
                    child: Column(
                      children: [
                        Text(
                          userName,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: baseScale * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                address,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: baseScale * 0.035,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit, size: 16, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Display badges section
                  earnedBadges.isEmpty 
                    ? Container()
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: earnedBadges.map((badge) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDBB727),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(Icons.emoji_events, size: 18, color: Colors.white),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    badge['name'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                      fontSize: baseScale * 0.032,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  TextButton(
                    onPressed: _showAllBadges,
                    child: const Text(
                      'View All Badges',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const TabBar(
                    indicatorColor: Color(0xFF328E6E),
                    labelColor: Color(0xFF328E6E),
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(text: 'Reports'),
                      Tab(text: 'Events'),
                    ],
                  ),
                ],
              ),
            )
          ],
          body: TabBarView(
            children: [
              // Reports tab
              ListView(
                padding: const EdgeInsets.all(16),
                children: reportWidgets,
              ),
              // Events tab
              ListView(
                padding: const EdgeInsets.all(16),
                children: eventWidgets,
              ),
            ],
          ),
        ),
      ),
    );
  }
}