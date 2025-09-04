import 'package:flutter/material.dart';

class OfficialsDashboardPage extends StatefulWidget {
  const OfficialsDashboardPage({Key? key}) : super(key: key);

  @override
  State<OfficialsDashboardPage> createState() => _OfficialsDashboardPageState();
}

class _OfficialsDashboardPageState extends State<OfficialsDashboardPage> {
  final List<Map<String, dynamic>> _officials = [
    {"name": "Juan Dela Cruz", "email": "juan@example.com", "password": "password123", "role": "official", "createdAt": DateTime.now().subtract(const Duration(days: 1))},
    {"name": "Maria Santos", "email": "maria@example.com", "password": "password123", "role": "official", "createdAt": DateTime.now()},
    {"name": "Pedro Reyes", "email": "pedro@example.com", "password": "password123", "role": "official", "createdAt": DateTime.now()},
    {"name": "Ana Dizon", "email": "ana@example.com", "password": "password123", "role": "official", "createdAt": DateTime.now().subtract(const Duration(days: 2))},
    {"name": "Jose Rizal", "email": "jose@example.com", "password": "password123", "role": "official", "createdAt": DateTime.now()},
    {"name": "Andres Bonifacio", "email": "andres@example.com", "password": "password123", "role": "official", "createdAt": DateTime.now().subtract(const Duration(days: 5))},
    {"name": "Emilio Aguinaldo", "email": "emilio@example.com", "password": "password123", "role": "official", "createdAt": DateTime.now()},
    {"name": "Melchora Aquino", "email": "melchora@example.com", "password": "password123", "role": "official", "createdAt": DateTime.now()},
    {"name": "Apolinario Mabini", "email": "apolinario@example.com", "password": "password123", "role": "official", "createdAt": DateTime.now().subtract(const Duration(days: 3))},
    {"name": "Gregoria De Jesus", "email": "gregoria@example.com", "password": "password123", "role": "official", "createdAt": DateTime.now()},
    {"name": "Marcelo H. Del Pilar", "email": "marcelo@example.com", "password": "password123", "role": "official", "createdAt": DateTime.now()},
    {"name": "Diego Silang", "email": "diego@example.com", "password": "password123", "role": "official", "createdAt": DateTime.now()},
    {"name": "Gabriela Silang", "email": "gabriela@example.com", "password": "password123", "role": "official", "createdAt": DateTime.now()},
    {"name": "Francisco Balagtas", "email": "francisco@example.com", "password": "password123", "role": "official", "createdAt": DateTime.now()},
    {"name": "Antonio Luna", "email": "antonio@example.com", "password": "password123", "role": "official", "createdAt": DateTime.now()},
  ];

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  int? _editingIndex;
  int _currentPage = 0;
  int _rowsPerPage = 5;

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

  int get _recentlyAddedCount {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _officials.where((o) => o["createdAt"].isAfter(cutoff)).length;
  }

  void _showOfficialDialog({bool isEdit = false, int? index}) {
    if (isEdit && index != null) {
      _nameController.text = _officials[index]["name"];
      _emailController.text = _officials[index]["email"];
      _passwordController.text = _officials[index]["password"];
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
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          if (_editingIndex != null) {
                            _officials[_editingIndex!] = {
                              "name": _nameController.text.trim(),
                              "email": _emailController.text.trim(),
                              "password": _passwordController.text.trim(),
                              "role": "official",
                              "createdAt": DateTime.now(),
                            };
                          } else {
                            _officials.add({
                              "name": _nameController.text.trim(),
                              "email": _emailController.text.trim(),
                              "password": _passwordController.text.trim(),
                              "role": "official",
                              "createdAt": DateTime.now(),
                            });
                          }
                        });
                        Navigator.pop(context);
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

  void _deleteOfficial(int index) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this official?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF328E6E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _officials.removeAt(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 🔹 Stats cards with flex stretching
              LayoutBuilder(
                builder: (context, constraints) {
                  double cardWidth;
                  if (constraints.maxWidth >= 1200) {
                    cardWidth = (constraints.maxWidth - 48) / 2; // 2 cards, spacing included
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
                          icon: Icons.group, // <-- add this
                        ),
                        _buildStatCard(
                          "Recently Added",
                          _recentlyAddedCount.toString(),
                          Colors.green,
                          width: cardWidth,
                          icon: Icons.add_circle, // <-- add this
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // 🔹 Officials list
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header + Add button
                      Flex(
                        direction: isWide ? Axis.horizontal : Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Maintenance Officials",
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
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

                      // Search bar
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

                      // List of officials
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _paginatedOfficials.length,
                        itemBuilder: (context, index) {
                          final official = _paginatedOfficials[index];
                          final globalIndex = index + (_currentPage * _rowsPerPage);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: InkWell(
                              onTap: () => _showOfficialDialog(isEdit: true, index: globalIndex),
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
                                  title: Text(official["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(official["email"]),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showOfficialDialog(isEdit: true, index: globalIndex),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => _deleteOfficial(globalIndex),
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

                      // Pagination
                      if (_rowsPerPage != -1)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                            ),
                            ...List.generate(_totalPages, (index) {
                              final selected = index == _currentPage;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: ChoiceChip(
                                  label: Text("${index + 1}"),
                                  selected: selected,
                                  selectedColor: Colors.indigo,
                                  backgroundColor: Colors.grey[300],
                                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.black),
                                  onSelected: (_) => setState(() => _currentPage = index),
                                ),
                              );
                            }),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _currentPage < _totalPages - 1 ? () => setState(() => _currentPage++) : null,
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

  // 🔹 Build Stat Card with icon
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
            // Metric text
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            // Floating icon
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
