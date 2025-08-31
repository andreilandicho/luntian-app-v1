import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

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
      setState(() => _suggestions = []);
      return;
    }

    setState(() => _isLoading = true);

    // Use Uri.https so the query is properly URL-encoded.
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
          // Nominatim requires a valid User-Agent
          'User-Agent': 'FlutterApp/1.0 (contact@example.com)',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _suggestions = json.decode(response.body) as List<dynamic>;
        });
      } else {
        setState(() => _suggestions = []);
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint("Error fetching address suggestions: $e");
      setState(() => _suggestions = []);
    }

    if (mounted) setState(() => _isLoading = false);
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

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  File? _profileImage;
  final picker = ImagePicker();

  String _name = "Barangay 360";
  String _address = "Sta. Mesa, Manila";

  final List<Map<String, dynamic>> _proposals = [
    {
      "title": "Clean-up Drive",
      "date": DateTime.now().add(const Duration(days: 2)),
      "volunteers": 15,
      "description": "Community clean-up drive in the riverbanks.",
      "details": "Location: Riverbanks\nWho's Needed: Youth volunteers",
      "status": "pending",
    },
    {
      "title": "Feeding Program",
      "date": DateTime.now().add(const Duration(days: 5)),
      "volunteers": 8,
      "description": "Feeding program for street children.",
      "details": "Location: Barangay Hall\nWho's Needed: Cooks, Servers",
      "status": "pending",
    },
  ];

  final List<Map<String, dynamic>> _approvedProposals = [];

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _editProfileAndAddress() {
    final nameController = TextEditingController(text: _name);
    final addressController = TextEditingController(text: _address);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Edit Profile",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AddressField(controller: addressController),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _name = nameController.text.trim();
                              _address = addressController.text.trim();
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("Save"),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _updateProposalStatus(int index, String status) {
    if (status == "accepted") {
      setState(() {
        final approved = {..._proposals[index]};
        approved["status"] = "accepted";
        _approvedProposals.add(approved);
        _proposals.removeAt(index);
      });
    } else {
      _showCommentDialog(index, status: status);
    }
  }

  void _showCommentDialog(int index, {String? status}) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Comment for ${status!.toUpperCase()}"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Write a comment...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please enter a comment before submitting."),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                _proposals[index]["status"] = status;
                _proposals[index]["comment"] = controller.text.trim();
              });

              Navigator.pop(context);
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Admin Profile",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              fontFamily: 'Marykate',
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
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
                Tab(text: "Pending (${_proposals.length})"),
                Tab(text: "Approved (${_approvedProposals.length})"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPendingList(),
                  _buildApprovedList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingList() {
    return _proposals.isEmpty
        ? const Center(
            child: Text("No pending proposals 🎉",
                style: TextStyle(color: Colors.grey)),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _proposals.length,
            itemBuilder: (context, index) {
              final proposal = _proposals[index];
              return _buildProposalCard(proposal, index, showActions: true);
            },
          );
  }

  Widget _buildApprovedList() {
    return _approvedProposals.isEmpty
        ? const Center(
            child: Text("No approved proposals yet ✅",
                style: TextStyle(color: Colors.grey)),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _approvedProposals.length,
            itemBuilder: (context, index) {
              final proposal = _approvedProposals[index];
              return _buildProposalCard(proposal, null, showActions: false);
            },
          );
  }

  Widget _buildProposalCard(Map<String, dynamic> proposal, int? index,
      {required bool showActions}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(proposal["title"],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                  decoration: BoxDecoration(
                    color: proposal["status"] == "accepted"
                        ? Colors.green[100]
                        : proposal["status"] == "rejected"
                            ? Colors.red[100]
                            : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    proposal["status"].toUpperCase(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: proposal["status"] == "accepted"
                            ? Colors.green[800]
                            : proposal["status"] == "rejected"
                                ? Colors.red[800]
                                : Colors.orange[800]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text("Date: ${DateFormat.yMMMd().add_jm().format(proposal["date"])}"),
            Text("Volunteers: ${proposal["volunteers"]}"),
            const SizedBox(height: 6),
            Text(proposal["description"]),
            const SizedBox(height: 6),
            Text(proposal["details"],
                style: const TextStyle(color: Colors.grey)),
            if (proposal.containsKey("comment"))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "💬 Comment: ${proposal["comment"]}",
                  style: const TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.black87),
                ),
              ),
            if (showActions) const Divider(height: 30),
            if (showActions)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _updateProposalStatus(index!, "accepted"),
                    icon: const Icon(Icons.check),
                    label: const Text("Accept"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _updateProposalStatus(index!, "rejected"),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text("Reject",
                        style: TextStyle(color: Colors.red)),
                  ),
                  TextButton.icon(
                    onPressed: () => _updateProposalStatus(index!, "revise"),
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    label: const Text("Revise",
                        style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isWide) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile picture (tap to change)
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : const AssetImage("assets/profile picture.png")
                        as ImageProvider,
              ),
            ),

            const SizedBox(height: 12),

            // Name
            Text(
              _name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            // Address
            Text(
              _address,
              style: const TextStyle(color: Colors.grey),
            ),

            const Divider(thickness: 1, height: 30),

            // ✅ Responsive layout for buttons
            isWide
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDashboardButton(
                        icon: Icons.lock_reset,
                        label: "Change Password",
                        color: Colors.blue,
                        onTap: _showChangePasswordDialog,
                      ),
                      const SizedBox(width: 20),
                      _buildDashboardButton(
                        icon: Icons.settings,
                        label: "Edit Profile",
                        color: Colors.green,
                        onTap: _editProfileAndAddress,
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildDashboardButton(
                        icon: Icons.lock_reset,
                        label: "Change Password",
                        color: Colors.blue,
                        onTap: _showChangePasswordDialog,
                      ),
                      const SizedBox(height: 12),
                      _buildDashboardButton(
                        icon: Icons.settings,
                        label: "Edit Profile",
                        color: Colors.green,
                        onTap: _editProfileAndAddress,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDashboardButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
  final oldPassController = TextEditingController();
  final newPassController = TextEditingController();
  final confirmPassController = TextEditingController();

  bool obscureOld = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  String? passwordError;
  String? confirmError;

  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text("Change Password"),
        content: SizedBox(
          // ✅ Just right: not too wide, not too narrow
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current password
              TextField(
                controller: oldPassController,
                obscureText: obscureOld,
                decoration: InputDecoration(
                  labelText: "Current Password",
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureOld ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => obscureOld = !obscureOld),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // New password
              TextField(
                controller: newPassController,
                obscureText: obscureNew,
                onChanged: (value) {
                  final regex = RegExp(
                      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$');
                  if (value.isEmpty) {
                    passwordError = "Please enter a password";
                  } else if (!regex.hasMatch(value)) {
                    passwordError =
                        "Password must be at least 8 characters and include uppercase, lowercase, number, and special character.";
                  } else {
                    passwordError = null;
                  }
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: "New Password",
                  border: const OutlineInputBorder(),
                  errorText: passwordError,
                  errorMaxLines: 3, // ✅ wrap properly
                ),
              ),
              const SizedBox(height: 16),

              // Confirm new password
              TextField(
                controller: confirmPassController,
                obscureText: obscureConfirm,
                onChanged: (value) {
                  if (value != newPassController.text) {
                    confirmError = "Passwords do not match";
                  } else {
                    confirmError = null;
                  }
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: "Confirm New Password",
                  border: const OutlineInputBorder(),
                  errorText: confirmError,
                  errorMaxLines: 2,
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final newPass = newPassController.text;
              final confirmPass = confirmPassController.text;

              final regex = RegExp(
                  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$');

              if (!regex.hasMatch(newPass)) {
                setState(() {
                  passwordError =
                      "Password must be at least 8 characters and include uppercase, lowercase, number, and special character.";
                });
                return;
              }
              if (newPass != confirmPass) {
                setState(() {
                  confirmError = "Passwords do not match";
                });
                return;
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Password updated successfully ✅"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Update"),
          ),
        ],
      ),
    ),
  );
}
}
