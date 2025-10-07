import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter_application_1/screen/admin/login_screen.dart';
import 'package:bcrypt/bcrypt.dart';


class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _totalBarangays = 0;
  int _activeBarangays = 0;
  int _inactiveBarangays = 0;
  List<Map<String, dynamic>> _barangays = [];

  final Color mainColor = const Color(0xFF2E7D32); // Luntian green

  @override
  void initState() {
    super.initState();
    _loadBarangayData();
    Timer.periodic(const Duration(seconds: 10), (_) => _loadBarangayData());
  }

  Future<void> _loadBarangayData() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('*')
          .eq('role', 'barangay')
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _barangays = List<Map<String, dynamic>>.from(response);
        _totalBarangays = _barangays.length;
        _activeBarangays = _barangays.where((b) => b['is_active'] == true).length;
        _inactiveBarangays = _totalBarangays - _activeBarangays;
      });
    } catch (e) {
      print("❌ Error fetching barangay data: $e");
    }
  }

 Future<void> _deleteBarangayAccount(String userId) async {
  try {
    await Supabase.instance.client
        .from('users')
        .delete()
        .eq('user_id', userId); // use user_id instead of id

    await _loadBarangayData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deleted successfully')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error deleting account: $e')),
    );
  }
}



  void _showDeleteConfirmation(Map<String, dynamic> user) {
    final userId = user['user_id']?.toString(); // ensure String
    final userName = user['name'] ?? 'Unknown User';

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User ID is missing')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Barangay Account'),
        content: Text(
          'Are you sure you want to delete $userName?\nThis action cannot be undone.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBarangayAccount(userId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }



  void _showAddBarangayDialog() {
    showDialog(
      context: context,
      builder: (context) => AddBarangayDialog(onBarangayAdded: _loadBarangayData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      // ✅ HEADER + CONTENT
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ HEADER with logo and LUNTIAN
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: mainColor, // Luntian green
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/logo only luntian.png',
                      height: 40,
                      width: 40,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "LUNTIAN",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Logout',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Confirm Logout"),
                            content: const Text("Are you sure you want to log out?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close the dialog
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AdminLoginPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Logout",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),




              const SizedBox(height: 20),

              // ✅ STATISTICS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statCard("Total", _totalBarangays, mainColor),
                  _statCard("Active", _activeBarangays, Colors.green),
                  _statCard("Inactive", _inactiveBarangays, Colors.redAccent),
                ],
              ),

              const SizedBox(height: 20),

              // ✅ LIST OF BARANGAYS
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Barangay Accounts (${_barangays.length})",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _barangays.isEmpty
                            ? const Center(
                                child: Text("No barangay accounts found."),
                              )
                            : ListView.builder(
                                itemCount: _barangays.length,
                                itemBuilder: (context, index) {
                                  final b = _barangays[index];
                                  final isActive = b['is_active'] == true;

                                  return Card(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 6),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isActive
                                            ? Colors.green
                                            : Colors.grey,
                                        child: Text(
                                          b['name']?.substring(0, 1)
                                                  .toUpperCase() ??
                                              '?',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                      title: Text(b['name'] ?? 'Unknown'),
                                      subtitle: Text(b['email'] ?? 'No email'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            _showDeleteConfirmation(b),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ✅ ADD BUTTON fixed at bottom
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showAddBarangayDialog,
            icon: const Icon(Icons.add),
            label: const Text("Add Barangay"),
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Helper widget for stats
  Widget _statCard(String label, int value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                "$value",
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(label, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- ADD BARANGAY DIALOG --------------------
class AddBarangayDialog extends StatefulWidget {
  final VoidCallback onBarangayAdded;
  const AddBarangayDialog({super.key, required this.onBarangayAdded});

  @override
  State<AddBarangayDialog> createState() => _AddBarangayDialogState();
}

class _AddBarangayDialogState extends State<AddBarangayDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addBarangay() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // ✅ Check if barangay name already exists
      final existing = await supabase
          .from('users')
          .select('name') // no need for 'id'
          .eq('name', name)
          .eq('role', 'barangay')
          .maybeSingle();

      if (existing != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Barangay name "$name" already exists')),
          );
        }
        return;
      }

      // ✅ Hash the password securely
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      // ✅ Insert new barangay record
      await supabase.from('users').insert({
        'name': name,
        'email': email,
        'password': hashedPassword,
        'role': 'barangay',
        'is_active': true,
        'is_approved': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      widget.onBarangayAdded();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barangay account created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding barangay: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    const mainColor = Color(0xFF2E7D32);

    return AlertDialog(
      title: const Text(
        "Add Barangay",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _inputField(_nameController, "Barangay Name", Icons.location_city),
                const SizedBox(height: 12),
                _inputField(_emailController, "Email Address", Icons.email),
                const SizedBox(height: 12),
                _passwordField(_passwordController, "Password"),
                const SizedBox(height: 12),
                _confirmPasswordField(_confirmPasswordController, "Confirm Password"),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addBarangay,
          style: ElevatedButton.styleFrom(
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Widget _inputField(TextEditingController c, String label, IconData icon,
      {bool obscure = false}) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Please enter $label" : null,
    );
  }

  Widget _passwordField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF2E7D32)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "Please enter a password";

        // ✅ Strong password check
        final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$');
        if (!regex.hasMatch(v)) {
          return "Password must be at least 8 chars, include\nuppercase, lowercase, number & special char.";
        }

        return null;
      },
    );
  }

  Widget _confirmPasswordField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2E7D32)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return "Please confirm your password";
        if (v != _passwordController.text) return "Passwords do not match";
        return null;
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}


