import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfficialsDashboardPage extends StatefulWidget {
  const OfficialsDashboardPage({Key? key}) : super(key: key);

  @override
  State<OfficialsDashboardPage> createState() => _OfficialsDashboardPageState();
}

class _OfficialsDashboardPageState extends State<OfficialsDashboardPage> {
  List<Map<String, dynamic>> _officials = [];
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  int? _editingIndex;
  int _currentPage = 0;
  int _rowsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _fetchOfficials();
    _loadBarangayId();
  }

  Future<void> _fetchOfficials() async {
    final prefs = await SharedPreferences.getInstance();
    final barangayId = prefs.getInt('barangay_id'); // the logged-in user's barangay

    if (barangayId == null) {
      throw Exception("No barangay_id found for logged in user");
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // fetch officials and their linked user row
      final response = await Supabase.instance.client
          .from('officials')
          .select('official_id, barangay_id, users(user_id, name, email, created_at)')
          .eq('barangay_id', barangayId)
          .order('official_id', ascending: false);

      final data = response as List<dynamic>? ?? [];

      final List<Map<String, dynamic>> items = data.map<Map<String, dynamic>>((e) {
        final user = (e['users'] ?? {}) as Map<String, dynamic>;
        return {
          'official_id': e['official_id'],
          'user_id': user['user_id'], // keep for updates
          'name': user['name'] ?? 'Unknown',
          'email': user['email'] ?? 'N/A',
          'createdAt': user['created_at'] != null
              ? DateTime.tryParse(user['created_at'].toString()) ?? DateTime.now()
              : DateTime.now(),
          'barangay_id': e['barangay_id'],
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _officials = items;
      });
    } catch (err) {
      debugPrint('❌ Error fetching officials: $err');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }




  List<Map<String, dynamic>> get _filteredOfficials {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) return _officials;
    return _officials
        .where((official) =>
            official["name"].toLowerCase().contains(query) ||
            official["email"].toLowerCase().contains(query))
        .toList();
  }

  List<Map<String, dynamic>> get _paginatedOfficials {
    if (_rowsPerPage == -1) return _filteredOfficials;
    final start = _currentPage * _rowsPerPage;
    final end = start + _rowsPerPage;
    return _filteredOfficials.sublist(
      start,
      end > _filteredOfficials.length ? _filteredOfficials.length : end,
    );
  }

  int get _totalPages {
    if (_rowsPerPage == -1) return 1;
    return (_filteredOfficials.length / _rowsPerPage).ceil();
  }

  int? _loggedInBarangayId;

  Future<void> _loadBarangayId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loggedInBarangayId = prefs.getInt('barangay_id');
    });
  }


  int get _recentlyAddedCount {
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  final barangayId = _loggedInBarangayId;

  if (barangayId == null) return 0;

  return _officials.where((o) {
    final createdAt = o["createdAt"] as DateTime?;
    final officialBarangayId = o["barangay_id"] as int?;
    return createdAt != null &&
           officialBarangayId == barangayId &&
           createdAt.isAfter(cutoff);
  }).length;
}

  

  Future<void> _deleteOfficial(int officialId, int index) async {
    try {
      // fetch linked user_id
      final fetch = await Supabase.instance.client
          .from('officials')
          .select('user_id')
          .eq('official_id', officialId)
          .maybeSingle();

      final userId = fetch?['user_id'];

      // delete the official row
      await Supabase.instance.client
          .from('officials')
          .delete()
          .eq('official_id', officialId);

      // also delete linked user if found
      if (userId != null) {
        await Supabase.instance.client
            .from('users')
            .delete()
            .eq('user_id', userId);
      }

      if (!mounted) return;
      setState(() => _officials.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Official deleted")),
      );
    } catch (e) {
      debugPrint("❌ Error deleting official: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to delete official"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  void _showOfficialDialog({bool isEdit = false, int? index}) {
    if (isEdit && index != null) {
      _nameController.text = _officials[index]["name"];
      _emailController.text = _officials[index]["email"];
      _passwordController.clear(); // no password from db
      _editingIndex = index;
    } else {
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _editingIndex = null;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEdit ? "Edit Official" : "Add Official",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          labelText: "Name", border: OutlineInputBorder()),
                      validator: (value) =>
                          value == null || value.isEmpty ? "Enter name" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                          labelText: "Email", border: OutlineInputBorder()),
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Enter email";
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                            .hasMatch(value)) return "Enter valid email";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (!isEdit)
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                            labelText: "Password", border: OutlineInputBorder()),
                        validator: (value) =>
                            value == null || value.isEmpty ? "Enter password" : null,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel")),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF328E6E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Save"),
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;

                      final name = _nameController.text.trim();
                      final email = _emailController.text.trim();
                      final password = _passwordController.text.trim();

                      // --- EDIT existing official ---
                      if (isEdit && _editingIndex != null) {
                        final editing = _officials[_editingIndex!];
                        final int? userId = editing['user_id'] as int?;

                        if (userId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cannot determine user id for this official.')),
                          );
                          return;
                        }

                        try {
                          // Check if email belongs to another user
                          final existing = await Supabase.instance.client
                              .from('users')
                              .select('user_id')
                              .eq('email', email)
                              .maybeSingle();

                          if (existing != null && existing['user_id'] != userId) {
                            // email used by a different user
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('❌ Email already used by another account.'),
                                backgroundColor: Colors.black87,
                              ),
                            );
                            return;
                          }

                          // Perform update and return the updated row
                          final updated = await Supabase.instance.client
                              .from('users')
                              .update({'name': name, 'email': email})
                              .eq('user_id', userId)
                              .select()
                              .maybeSingle();

                          await _fetchOfficials();

                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✅ Official updated successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          debugPrint("❌ Error updating official: $e");
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to update official"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }

                        return;
                      }

                      // --- CREATE new official ---
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final barangayId = prefs.getInt('barangay_id');

                        if (barangayId == null) {
                          throw Exception("❌ No barangay_id found for logged in user");
                        }

                        // 1️⃣ Check if email exists
                        final existing = await Supabase.instance.client
                            .from('users')
                            .select('user_id')
                            .eq('email', email)
                            .maybeSingle();

                        if (existing != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("❌ Email already exists. Please use another email."),
                              backgroundColor: Colors.black87,
                            ),
                          );
                          return;
                        }

                        // 2️⃣ Insert into users table
                        final userRes = await Supabase.instance.client
                            .from('users')
                            .insert({
                              "name": name,
                              "email": email,
                              "password": password,
                              "role": "official",
                              "barangay_id": barangayId,
                            })
                            .select()
                            .single();

                        final userId = userRes['user_id'];

                        // 3️⃣ Insert into officials table and get official_id
                        final officialRes = await Supabase.instance.client
                          .from('officials')
                          .insert({
                            "user_id": userId,
                            "barangay_id": barangayId,
                          })
                          .select('official_id') // ✅ only select official_id
                          .single();

                        final officialId = officialRes['official_id'] as int?;
                        if (officialId == null) {
                          throw Exception("Failed to get official_id from Supabase");
                        }


                        // 4️⃣ Update local officials list immediately
                        await _fetchOfficials();

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("✅ Official added"),
                            backgroundColor: Colors.green,
                          ),
                        );

                        Navigator.pop(context);

                      } catch (e) {
                        debugPrint("❌ Error adding official: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Something went wrong while adding the official."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Stats cards
                    LayoutBuilder(
                      builder: (context, constraints) {
                        double cardWidth;
                        if (constraints.maxWidth >= 1200) {
                          cardWidth = (constraints.maxWidth - 48) / 2;
                        } else if (constraints.maxWidth >= 800) {
                          cardWidth = constraints.maxWidth * 0.45;
                        } else {
                          cardWidth = double.infinity;
                        }

                        return Center(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildStatCard(
                                "Total Officials",
                                _officials.length.toString(),
                                Colors.indigo,
                                width: cardWidth,
                                icon: Icons.group,
                              ),
                              _buildStatCard(
                                "Recently Added",
                                _recentlyAddedCount.toString(),
                                Colors.green,
                                width: cardWidth,
                                icon: Icons.add_circle,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Officials list
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Flex(
                              direction: isWide ? Axis.horizontal : Axis.vertical,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Maintenance Officials",
                                    style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12, width: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    elevation: 3,
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text("Add"),
                                  onPressed: () => _showOfficialDialog(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: "Search by name or email...",
                                prefixIcon: const Icon(Icons.search),
                                filled: true,
                                fillColor: Colors.grey[200],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 16),

                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _paginatedOfficials.length,
                              itemBuilder: (context, index) {
                                final official = _paginatedOfficials[index];
                                final globalIndex =
                                    index + (_currentPage * _rowsPerPage);

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: InkWell(
                                    onTap: () => _showOfficialDialog(
                                        isEdit: true, index: globalIndex),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Ink(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          )
                                        ],
                                      ),
                                      child: ListTile(
                                        title: Text(official["name"],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        subtitle: Text(official["email"]),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  color: Colors.blue),
                                              onPressed: () =>
                                                  _showOfficialDialog(
                                                      isEdit: true,
                                                      index: globalIndex),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () =>
                                                  _deleteOfficial(
                                                      official["official_id"],
                                                      globalIndex),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 12),

                            if (_rowsPerPage != -1)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: _currentPage > 0
                                        ? () =>
                                            setState(() => _currentPage--)
                                        : null,
                                  ),
                                  ...List.generate(_totalPages, (index) {
                                    final selected = index == _currentPage;
                                    return AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      child: ChoiceChip(
                                        label: Text("${index + 1}"),
                                        selected: selected,
                                        selectedColor: Colors.indigo,
                                        backgroundColor: Colors.grey[300],
                                        labelStyle: TextStyle(
                                            color: selected
                                                ? Colors.white
                                                : Colors.black),
                                        onSelected: (_) =>
                                            setState(() => _currentPage = index),
                                      ),
                                    );
                                  }),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: _currentPage < _totalPages - 1
                                        ? () =>
                                            setState(() => _currentPage++)
                                        : null,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color,
      {double? width, IconData? icon}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          height: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(4, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              if (icon != null)
                Positioned(
                  top: -12,
                  right: -12,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(2, 4),
                        )
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 48,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
