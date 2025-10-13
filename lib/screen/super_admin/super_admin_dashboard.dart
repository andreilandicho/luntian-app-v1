import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter_application_1/screen/admin/login_screen.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
          .eq('user_id', userId);

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
    final userId = user['user_id']?.toString();
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: mainColor,
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
                                  Navigator.pop(context);
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

              // Statistics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statCard("Total", _totalBarangays, mainColor),
                  _statCard("Active", _activeBarangays, Colors.green),
                  _statCard("Inactive", _inactiveBarangays, Colors.redAccent),
                ],
              ),
              const SizedBox(height: 20),

              // List of Barangays
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
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isActive
                                            ? Colors.green
                                            : Colors.grey,
                                        child: Text(
                                          b['name']?.substring(0, 1).toUpperCase() ?? '?',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      title: Text(b['name'] ?? 'Unknown'),
                                      subtitle: Text(b['email'] ?? 'No email'),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _showDeleteConfirmation(b),
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
  final _searchController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingMasterlist = false;
  
  List<Map<String, dynamic>> _masterlist = [];
  List<Map<String, dynamic>> _filteredMasterlist = [];
  Map<String, dynamic>? _selectedBarangay;

  final String baseUrl = 'https://luntian-app-v1-production.up.railway.app';
  // final String baseUrl = 'http://localhost:3000';

  @override
  void initState() {
    super.initState();
    _loadMasterlist();
    _searchController.addListener(_filterMasterlist);
  }

  Future<void> _loadMasterlist() async {
    setState(() => _isLoadingMasterlist = true);
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/barangay_masterlist/masterlist'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _masterlist = List<Map<String, dynamic>>.from(data);
          _filteredMasterlist = _masterlist;
        });
      }
    } catch (e) {
      print('Error loading masterlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading barangay list: $e')),
        );
      }
    } finally {
      setState(() => _isLoadingMasterlist = false);
    }
  }

  void _filterMasterlist() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMasterlist = _masterlist;
      } else {
        _filteredMasterlist = _masterlist.where((item) {
          final address = item['full_address']?.toString().toLowerCase() ?? '';
          final barangay = item['barangay']?.toString().toLowerCase() ?? '';
          final municipality = item['municipality']?.toString().toLowerCase() ?? '';
          return address.contains(query) || 
                 barangay.contains(query) || 
                 municipality.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _addBarangay() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedBarangay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a barangay from the list')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final masterlistId = _selectedBarangay!['barangay_masterlist_id'];

      // Hash the password
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      // Insert into barangays table first
      final barangayInsert = await supabase
          .from('barangays')
          .insert({
            'name': name,
            'city': _selectedBarangay!['municipality'],
            'contact_email': email,
            'masterlist_id': masterlistId,
          })
          .select()
          .single();

      final barangayId = barangayInsert['barangay_id'];

      // Insert into users table
      await supabase.from('users').insert({
        'name': name,
        'email': email,
        'password': hashedPassword,
        'role': 'barangay',
        'barangay_id': barangayId,
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
        "Add Barangay Account",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barangay Selection Dropdown
                const Text(
                  'Select Barangay from Masterlist',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                
                _isLoadingMasterlist
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          // Search Field
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search barangay...',
                              prefixIcon: const Icon(Icons.search, color: mainColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Selected Barangay Display
                          if (_selectedBarangay != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: mainColor),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: mainColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _selectedBarangay!['full_address'],
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 20),
                                    onPressed: () {
                                      setState(() => _selectedBarangay = null);
                                    },
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _filteredMasterlist.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text('No barangays found'),
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _filteredMasterlist.length,
                                      itemBuilder: (context, index) {
                                        final item = _filteredMasterlist[index];
                                        final hasAccount = item['has_account'] == true;
                                        
                                        return ListTile(
                                          dense: true,
                                          enabled: !hasAccount,
                                          title: Text(
                                            item['full_address'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: hasAccount 
                                                  ? Colors.grey 
                                                  : Colors.black,
                                            ),
                                          ),
                                          trailing: hasAccount
                                              ? const Chip(
                                                  label: Text(
                                                    'Account Exists',
                                                    style: TextStyle(fontSize: 10),
                                                  ),
                                                  backgroundColor: Colors.orange,
                                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                                )
                                              : const Icon(Icons.arrow_forward_ios, size: 16),
                                          onTap: hasAccount
                                              ? null
                                              : () {
                                                  setState(() {
                                                    _selectedBarangay = item;
                                                    _searchController.clear();
                                                  });
                                                },
                                        );
                                      },
                                    ),
                            ),
                        ],
                      ),
                
                const SizedBox(height: 16),
                
                // Account Details
                const Text(
                  'Account Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                
                _inputField(_nameController, "Barangay Office Name", Icons.location_city),
                const SizedBox(height: 12),
                _inputField(_emailController, "Contact Email", Icons.email),
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
              : const Text('Create Account'),
        ),
      ],
    );
  }

  Widget _inputField(TextEditingController c, String label, IconData icon) {
    return TextFormField(
      controller: c,
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
    _searchController.dispose();
    super.dispose();
  }
}