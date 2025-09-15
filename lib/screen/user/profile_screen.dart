
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_application_1/screen/user/add_event_screen.dart';
import 'package:flutter_application_1/screen/user/login_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  String profilePic = 'assets/profile picture.png';
  String userName = 'Kristel Cruz';
  String address = 'Quezon City, Metro Manila';

  final List<String> badges = ['Top Reporter', 'Eco Warrior'];
  final List<Map<String, dynamic>> userReports = [
  {
    'username': 'Kristel Cruz',
    'userProfile': 'assets/profile picture.png',
    'images': ['assets/garbage.png', 'assets/garbage.png'],
    'postContent': 'Trash piling up near Caimito Street again. Please assist!',
    'statusLabel': 'Pending',
    'statusColor': Colors.orange,
    'timestamp': '2h ago',
    'upvoted': false,
    'downvoted': false,
    'upvotes': 10,
    'downvotes': 2,
  },
  {
    'username': 'Kristel Cruz',
    'userProfile': 'assets/profile picture.png',
    'images': ['assets/garbage.png'],
    'postContent': 'Garbage cleared! Thanks to the local unit.',
    'statusLabel': 'Resolved',
    'statusColor': Colors.green,
    'timestamp': '1d ago',
    'upvoted': false,
    'downvoted': false,
    'upvotes': 20,
    'downvotes': 0,
  },
  {
    'username': 'Kristel Cruz',
    'userProfile': 'assets/profile picture.png',
    'images': ['assets/garbage.png', 'assets/garbage.png'],
    'postContent': 'There’s suspicious dumping behind the basketball court.',
    'statusLabel': 'In Progress',
    'statusColor': Colors.blue,
    'timestamp': '3d ago',
    'upvoted': false,
    'downvoted': false,
    'upvotes': 5,
    'downvotes': 1,
  },
];

final List<Map<String, dynamic>> userEvents = [
  {
    'title': 'Barangay Cleanup Drive',
    'dateTime': 'July 28, 2025 • 9:00 AM',
    'volunteers': 24,
    'description': 'A cleanup event around the Barangay Hall and nearby streets.',
    'additionalInfo': 'Bring gloves and garbage bags.',
    'images': [
      'assets/event.jpg',
      'assets/event.jpg',
      'assets/event.jpg',
    ],
    'statusLabel': 'Approved',
    'statusColor': Colors.green,
    'adminComment': '',
  },
  {
    'title': 'Reschedule Required',
    'dateTime': 'July 30, 2025 • 3:00 PM',
    'volunteers': 8,
    'description': 'Clean up scheduled for local park.',
    'additionalInfo': 'Venue needs confirmation.',
    'images': [
      'assets/event.jpg',
      'assets/event.jpg',
      'assets/event.jpg',
    ],
    'statusLabel': 'For Revision',
    'statusColor': Colors.orange,
    'adminComment': 'Please revise the event location and clarify volunteer roles.',
  },
  {
    'title': 'Clean-Up Drive',
    'dateTime': 'August 2, 2025 • 10:00 AM',
    'volunteers': 0,
    'description': 'Attempted to organize a clean-up activity at the abandoned lot.',
    'additionalInfo': 'Security measures not included.',
    'images': [
      'assets/event.jpg',
      'assets/event.jpg',
      'assets/event.jpg',
    ],
    'statusLabel': 'Rejected',
    'statusColor': Colors.red,
    'adminComment': 'The event proposal lacks sufficient detail on safety measures.',
  },
];

// Simulated badge data (you can replace this with actual data logic later)
late List<Map<String, dynamic>> allBadges;

@override
void initState() {
  super.initState();
  allBadges = [
    {
      'name': 'Top Reporter',
      'earned': true,
      'description': 'Submit 10 valid reports.',
      'progress': 10,
      'goal': 10
    },
    {
      'name': 'Eco Warrior',
      'earned': true,
      'description': 'Create 3 cleanup events.',
      'progress': 3,
      'goal': 3
    },
    {
      'name': 'Event Initiator',
      'earned': false,
      'description': 'Organize your first event.',
      'progress': 0,
      'goal': 1
    },
    {
      'name': 'Report Master',
      'earned': false,
      'description': 'Get 50 upvotes on reports.',
      'progress': userReports.fold<int>(0, (sum, r) => sum + (r['upvotes'] ?? 0) as int),
      'goal': 50
    },
    {
      'name': 'Community Helper',
      'earned': false,
      'description': 'Join 5 events as a volunteer.',
      'progress': 1,
      'goal': 5
    },
  ];
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
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        profilePic = pickedFile.path; // Use local path instead of asset
      });
    }
  }

  void _editNameOrAddress() {
  final nameController = TextEditingController(text: userName);

  // Split address to populate fields if previously saved
  final streetController = TextEditingController();
  final floorUnitController = TextEditingController();
  final cityController = TextEditingController();

  // Attempt to extract existing address
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
            onPressed: () {
              setState(() {
                userName = nameController.text;

                // Combine address fields into one string
                String newAddress = streetController.text;
                if (floorUnitController.text.isNotEmpty) {
                  newAddress += ', ${floorUnitController.text}';
                }
                if (cityController.text.isNotEmpty) {
                  newAddress += ', ${cityController.text}';
                }

                address = newAddress;
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

  void _showImage(String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: PhotoView(imageProvider: AssetImage(path)),
      ),
    );
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
                backgroundImage: AssetImage(profilePic),
                radius: baseScale * 0.06,
              ),
              title: Text(
                userName,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(DateFormat('MMM dd, yyyy • h:mm a').format(DateTime.now())),
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
                          return GestureDetector(
                            onTap: () => _showImage(post['images'][imgIndex]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                post['images'][imgIndex],
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
                          setState(() {
                            post['upvoted'] = !(post['upvoted'] ?? false);
                            if (post['upvoted']) post['downvoted'] = false;
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
                      Text(post['upvotes'].toString()),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            post['downvoted'] = !(post['downvoted'] ?? false);
                            if (post['downvoted']) post['upvoted'] = false;
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
                      Text(post['downvotes'].toString()),
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
                                leading: const Icon(Icons.flag),
                                title: const Text('Report Post'),
                                onTap: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Post reported')),
                                  );
                                },
                              ),
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
                    backgroundImage: AssetImage(profilePic),
                    radius: baseScale * 0.06,
                  ),
                  title: Text(
                    userName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(DateFormat('MMM dd, yyyy • h:mm a').format(DateTime.now())),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${post['title']} — ${post['dateTime']}",
                        style: TextStyle(
                          fontSize: baseScale * 0.045,
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
                                  return GestureDetector(
                                    onTap: () => _showImage(post['images'][imgIndex]),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        post['images'][imgIndex],
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

  @override
Widget build(BuildContext context) {
  final screenSize = MediaQuery.of(context).size;
  final baseScale = screenSize.shortestSide.clamp(320.0, 480.0);

  return DefaultTabController(
    length: 2,
    child: RefreshIndicator(
      onRefresh: () async => setState(() {}),
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
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const LoginPage()),
                                  );
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
                  children: [
                    CircleAvatar(
                      radius: baseScale * 0.13,
                      backgroundImage: AssetImage(profilePic),
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
                Wrap(
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
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: userReports.length,
              itemBuilder: (context, index) => _buildReportCard(userReports[index]),
            ),
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: userEvents.length,
              itemBuilder: (context, index) => _buildEventCard(userEvents[index]),
            ),
          ],
        ),
      ),
    ),
  );
}
}