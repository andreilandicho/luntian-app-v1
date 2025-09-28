import 'package:flutter/material.dart';
import 'dart:io' show File; 
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';

// ✅ Add these for the address suggestions
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ========================= AddressField (free API: OpenStreetMap Nominatim) =========================
class AddressField extends StatefulWidget {
  final TextEditingController controller;
  const AddressField({super.key, required this.controller});

  @override
  State<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  List<dynamic> _suggestions = [];
  bool _isLoading = false;
  Timer? _debounce;

  Future<void> _fetchSuggestions(String query) async {
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() => _suggestions = []);
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    final url = Uri.https(
      'nominatim.openstreetmap.org',
      '/search',
      {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': '5',
      },
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'FlutterApp/1.0 (contact@example.com)',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final results = json.decode(response.body) as List<dynamic>;
        setState(() => _suggestions = results);
      } else {
        setState(() => _suggestions = []);
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint("Error fetching address suggestions: $e");
      setState(() => _suggestions = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchSuggestions(query);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: TextInputType.streetAddress,
          decoration: const InputDecoration(
            labelText: "Address (Searchable)",
            hintText: "Enter or search location",
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: _onSearchChanged,
        ),
        if (_isLoading) const LinearProgressIndicator(),
        if (_suggestions.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final place = _suggestions[index];
                final displayName = place["display_name"] as String? ?? "";
                return ListTile(
                  dense: true,
                  title: Text(
                    displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    widget.controller.text = displayName;
                    setState(() => _suggestions = []);
                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

// ===================================== Profile Page =====================================
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _profileImage;
  final picker = ImagePicker();

  String _name = "";
  String _email = "";
  String _barangay = "";
  String _city = "";
  String? _profileUrl;

  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _approvedEvents = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileAndEvents();
  }

  Future<void> _fetchProfileAndEvents() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final barangayId = prefs.getInt('barangay_id');

      if (barangayId == null) {
        throw Exception("No barangay_id found in SharedPreferences");
      }

      // 🔹 Fetch barangay profile (name + city + contact email)
      final barangayRes = await Supabase.instance.client
          .from('barangays')
          .select('name, city, contact_email')
          .eq('barangay_id', barangayId)
          .maybeSingle();

      if (barangayRes != null) {
        setState(() {
          _name = barangayRes['name'] ?? "Unknown Barangay";
          _barangay = barangayRes['name'] ?? "";      // 🔹 set barangay name
          _city = barangayRes['city'] ?? "Unknown City";
          _email = barangayRes['contact_email'] ?? "N/A";
          _profileUrl = (barangayRes['photo_urls'] as List?)?.first; // 🔹 first photo if exists
        });
      }


      // 🔹 Fetch volunteer events for this barangay
      final eventsRes = await Supabase.instance.client
          .from('volunteer_events')
          .select('*')
          .eq('barangay_id', barangayId)
          .order('created_at', ascending: false);

      final data = eventsRes as List<dynamic>? ?? [];

      final pending = <Map<String, dynamic>>[];
      final approved = <Map<String, dynamic>>[];

      for (final e in data) {
        final map = Map<String, dynamic>.from(e);
        if (map['approval_status'] == 'approved') {
          approved.add(map);
        } else {
          pending.add(map);
        }
      }

      setState(() {
        _events = pending;
        _approvedEvents = approved;
      });
    } catch (e) {
      debugPrint("❌ Error fetching profile/events: $e");
    } finally {
      setState(() => _loading = false);
    }
  }




  Future<void> _updateEventStatus(int index, String status,
      {String? comment}) async {
    try {
      final event = _events[index];
      final id = event['event_id'];

      if (status == "rejected") {
        // Delete the event if rejected
        await Supabase.instance.client
          .from('volunteer_events')
          .delete()
          .eq('event_id', id);
        
        setState(() {
          _events.removeAt(index);
        });
      } else {
        // Update status for other cases (approved, pending, etc.)
        await Supabase.instance.client
          .from('volunteer_events')
          .update({
            'approval_status': status,
            if (comment != null) 'comment': comment,
          })
          .eq('event_id', id);

        setState(() {
          if (status == "approved") {
            final approved = {...event, "approval_status": "approved"};
            _approvedEvents.add(approved);
            _events.removeAt(index);
          } else {
            _events[index]["approval_status"] = status;
            if (comment != null) {
              _events[index]["comment"] = comment;
            }
          }
        });
      }
    } catch (e) {
      debugPrint("❌ Error updating event: $e");
    }
  }

  // 📌 Example: update user profile
  Future<void> _updateProfile(String newName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) return;

      await Supabase.instance.client
          .from('users')
          .update({'name': newName})
          .eq('user_id', userId);

      setState(() => _name = newName);
    } catch (e) {
      debugPrint("❌ Error updating profile: $e");
    }
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        // On web, we can only use the `path` or `bytes`
        setState(() => _profileUrl = picked.path); 
      } else {
        setState(() => _profileImage = File(picked.path));
      }
    }
  }

  //for selecting photos in events
  Future<List<String>> _uploadSelectedImagesToSupabase(List<XFile> images) async {
  final urls = <String>[];
  for (var img in images) {
    final bytes = await img.readAsBytes();
    final fileName = "event_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final res = await Supabase.instance.client.storage
        .from("event-photos")
        .uploadBinary(fileName, bytes,
            fileOptions: const FileOptions(contentType: "image/jpeg"));

    final publicUrl = Supabase.instance.client.storage
        .from("event-photos")
        .getPublicUrl(fileName);

    urls.add(publicUrl);
  }
  return urls;
}



  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Profile"),
          centerTitle: true,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildProfileCard(isWide),
                  ),
                  TabBar(
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).primaryColor,
                    tabs: [
                      Tab(text: "Pending (${_events.length})"),
                      Tab(text: "Approved (${_approvedEvents.length})"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildEventList(_events, true),
                        _buildEventList(_approvedEvents, false),
                      ],
                    ),
                  ),
                ],
              ),
              //added floating button as add event
              floatingActionButton: FloatingActionButton(
              onPressed: _openAddEventDialog,
              child: const Icon(Icons.add),
            ),
      ),
    );
  }

  Widget _buildEventList(
      List<Map<String, dynamic>> events, bool showActions) {
    return events.isEmpty
        ? const Center(child: Text("No events found"))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventCard(event, index, showActions: showActions);
            },
          );
  }

  Widget _buildEventCard(Map<String, dynamic> event, int? index,
    {required bool showActions}) {
    final List<dynamic> photos = event["photo_urls"] ?? [];
    final PageController pageController = PageController();
    int currentIndex = 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Left Column: Photos
            // Left Column: Photos with carousel arrows
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (photos.isEmpty) return;
                          showDialog(
                            context: context,
                            builder: (ctx) {
                              return Container(
                                color: Colors.black.withOpacity(0.95),
                                child: Stack(
                                  children: [
                                    PageView.builder(
                                      itemCount: photos.length,
                                      controller: PageController(initialPage: currentIndex),
                                      itemBuilder: (context, i) {
                                        return Center(
                                          child: InteractiveViewer(
                                            child: Image.network(
                                              photos[i],
                                              fit: BoxFit.contain,
                                              width: MediaQuery.of(context).size.width,
                                              height: MediaQuery.of(context).size.height,
                                              errorBuilder: (_, __, ___) => const Icon(
                                                  Icons.broken_image, color: Colors.white),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Positioned(
                                      top: 40,
                                      right: 20,
                                      child: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.white, size: 28),
                                        onPressed: () => Navigator.pop(ctx),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: SizedBox(
                          height: 250,
                          width: double.infinity,
                          child: PageView.builder(
                            controller: pageController,
                            onPageChanged: (i) => currentIndex = i,
                            itemCount: photos.length,
                            itemBuilder: (context, i) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  photos[i],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (photos.length > 1) ...[
                        Positioned(
                          left: 5,
                          top: 0,
                          bottom: 0,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                            onPressed: () {
                              if (currentIndex > 0) {
                                pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut);
                                currentIndex--;
                              }
                            },
                          ),
                        ),
                        Positioned(
                          right: 5,
                          top: 0,
                          bottom: 0,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                            onPressed: () {
                              if (currentIndex < photos.length - 1) {
                                pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut);
                                currentIndex++;
                              }
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (photos.length > 1)
                    const SizedBox(height: 8),
                  if (photos.length > 1)
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: photos.length,
                        itemBuilder: (context, i) {
                          return GestureDetector(
                            onTap: () {
                              pageController.jumpToPage(i);
                              currentIndex = i;
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  photos[i],
                                  width: 60,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image,
                                        size: 20, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),


            const SizedBox(width: 16),

            // 📝 Right Column: Event Info
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event["title"] ?? "Untitled",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (event["event_date"] != null)
                    Text(
                      "📅 Date: ${DateFormat.yMMMd().format(DateTime.parse(event["event_date"]))}",
                    ),
                  if (event["description"] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        event["description"],
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  if (event["volunteers_needed"] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "👥 Volunteers Needed: ${event["volunteers_needed"]}",
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                    ),
                  if (showActions) const Divider(height: 20),
                  if (showActions)
                    Wrap(
                      spacing: 10,
                      children: [
                        ElevatedButton(
                          onPressed: () => _updateEventStatus(index!, "approved"),
                          child: const Text("Approve"),
                        ),
                        OutlinedButton(
                          onPressed: () => _updateEventStatus(index!, "rejected"),
                          child: const Text("Reject"),
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






  // ================== PROFILE CARD ==================
  Widget _buildProfileCard(bool isWide) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 👤 Profile picture
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null && !kIsWeb
                    ? FileImage(_profileImage!)
                    : (_profileUrl != null
                        ? NetworkImage(_profileUrl!)
                        : const AssetImage("assets/profile picture.png"))
                        as ImageProvider,
              ),
            ),
            const SizedBox(height: 10),

            // 📛 Name
            Text(
              _name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            // 📧 Email
            Text(_email, style: const TextStyle(color: Colors.grey)),

            // 🏘️ Barangay + City
            Text("$_city",
                style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 20),

            // ✏️ Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _openEditProfile,
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text("Edit Profile"),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _openChangePassword,
                  icon: const Icon(Icons.lock, size: 18),
                  label: const Text("Change Password"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// ================== EDIT PROFILE ==================
  void _openEditProfile() {
    final nameCtrl = TextEditingController(text: _name);
    final emailCtrl = TextEditingController(text: _email);
    final cityCtrl = TextEditingController(text: _city);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Edit Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Barangay Name")),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: "City")),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final barangayId = prefs.getInt("barangay_id");
                if (barangayId == null) return;

                await Supabase.instance.client.from("barangays").update({
                  "name": nameCtrl.text,
                  "city": cityCtrl.text,
                  "contact_email": emailCtrl.text,
                }).eq("barangay_id", barangayId);

                // Re-fetch profile so everything stays in sync
                await _fetchProfileAndEvents();
                Navigator.pop(ctx);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // ================== CHANGE PASSWORD =================//
  // ================== CHANGE PASSWORD ==================
void _openChangePassword() {
  final oldCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final reCtrl = TextEditingController();

  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldCtrl,
              decoration: const InputDecoration(labelText: "Old Password"),
              obscureText: true,
            ),
            TextField(
              controller: newCtrl,
              decoration: const InputDecoration(labelText: "New Password"),
              obscureText: true,
            ),
            TextField(
              controller: reCtrl,
              decoration: const InputDecoration(labelText: "Re-enter New Password"),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (newCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a new password")),
                );
                return;
              }
              
              if (newCtrl.text != reCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Passwords do not match")),
                );
                return;
              }

              final prefs = await SharedPreferences.getInstance();
              final barangayId = prefs.getInt("barangay_id");
              if (barangayId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Barangay not found")),
                );
                return;
              }

              try {
                // Fetch the admin user for this barangay
                final userRes = await Supabase.instance.client
                    .from("users")
                    .select("user_id, password, email")
                    .eq("barangay_id", barangayId)
                    .eq("role", "barangay")
                    .maybeSingle();

                if (userRes == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Admin user not found")),
                  );
                  return;
                }

                final userId = userRes['user_id'] as int?;
                final currentPassword = userRes['password'] as String? ?? "";
                final userEmail = userRes['email'] as String? ?? "";

                if (userId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid user data")),
                  );
                  return;
                }

                bool oldPasswordMatches = false;

                if (currentPassword.startsWith(r"$2a$") || currentPassword.startsWith(r"$2b$")) {
                  // Password already hashed
                  try {
                    oldPasswordMatches = BCrypt.checkpw(oldCtrl.text, currentPassword);
                  } catch (e) {
                    oldPasswordMatches = false;
                  }
                } else {
                  // Plain text password (for existing users)
                  oldPasswordMatches = oldCtrl.text == currentPassword;
                }

                if (!oldPasswordMatches) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Old password is incorrect")),
                  );
                  return;
                }

                // Hash new password
                final hashed = BCrypt.hashpw(newCtrl.text, BCrypt.gensalt());

                // Update password in database - use try/catch to handle success
                try {
                  await Supabase.instance.client
                      .from("users")
                      .update({"password": hashed})
                      .eq("user_id", userId);

                  // If we get here without an exception, the update was successful
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Password updated successfully")),
                  );
                  Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to update password: $e")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      );
    },
  );
}

//for pop box to insert the information of event
void _openAddEventDialog() {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final volunteersController = TextEditingController();
  DateTime? dateTime;
  bool isPublic = true;
  List<XFile> selectedImages = [];

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.event_available, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  "Create New Event",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            content: SizedBox(
              width: 600,  // ✅ fixed width
              height: 500, // ✅ fixed height (prevents shrinking)
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: "Event Title *",
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Description",
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Volunteers
                      TextField(
                        controller: volunteersController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "Volunteers Needed",
                          prefixIcon: const Icon(Icons.group),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date Picker
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dateTime == null
                                  ? "📅 Select event date"
                                  : DateFormat.yMMMd().format(dateTime!),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: const Text("Pick"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setDialogState(() => dateTime = picked);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Public / Private
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(isPublic ? "🌍 Public" : "🔒 Private"),
                          Switch(
                            value: isPublic,
                            onChanged: (val) => setDialogState(() => isPublic = val),
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Image Upload
                      const Text("📷 Event Photos"),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...selectedImages.map((img) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: kIsWeb
                                    ? Image.network(img.path, width: 70, height: 70, fit: BoxFit.cover)
                                    : Image.file(File(img.path), width: 70, height: 70, fit: BoxFit.cover),
                              )),
                          InkWell(
                            onTap: () async {
                              final picker = ImagePicker();
                              final imgs = await picker.pickMultiImage();
                              if (imgs.isNotEmpty) {
                                setDialogState(() => selectedImages.addAll(imgs));
                              }
                            },
                            child: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.add_a_photo, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty || dateTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all required fields")),
                    );
                    return;
                  }

                  try {
                    final imageUrls = await _uploadSelectedImagesToSupabase(selectedImages);

                    final prefs = await SharedPreferences.getInstance();
                    final barangayId = prefs.getInt("barangay_id");
                    final userId = prefs.getInt("user_id");

                    if (barangayId == null || userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Missing barangay or user ID")),
                      );
                      return;
                    }

                    final eventData = {
                      "title": titleController.text,
                      "description": descriptionController.text,
                      "event_date": dateTime?.toIso8601String(),
                      "volunteers_needed": int.tryParse(volunteersController.text) ?? 0,
                      "isPublic": isPublic,
                      "approval_status": "approved",
                      "barangay_id": barangayId,
                      "created_by": userId,
                      "photo_urls": imageUrls,
                      "created_at": DateTime.now().toIso8601String(),
                    };

                    await Supabase.instance.client
                        .from("volunteer_events")
                        .insert(eventData);

                    Navigator.pop(ctx);
                    _fetchProfileAndEvents();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Event added successfully")),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error adding event: $e")),
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      );
    },
  );
}








}

