import 'package:flutter/material.dart';
import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/attendance/presentation/app_drawer.dart';
import 'package:attendance/features/employee/presentation/employee_details_screen.dart';
import 'package:attendance/features/employee/presentation/employee_form_screen.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  AnimationController? _pageAnimController;
  Animation<double>? _pageFade;
  Animation<Offset>? _pageSlide;

  final List<Map<String, String>> _employees = [
    {
      'firstName': 'Aarav', 'lastName': 'Sharma', 'fatherName': 'Mahesh Sharma',
      'title': 'Software Engineer', 'phone': '+91 98765 43210', 'email': 'aarav@example.com',
      'officialEmail': 'aarav@company.com', 'aadhaar': 'XXXX-XXXX-1234', 'pan': 'ABCDE1234F',
      'presentAddress': '123 MG Road, Dehradun', 'permanentAddress': 'Village Rampur, Dehradun'
    },
    {
      'firstName': 'Isha', 'lastName': 'Verma', 'fatherName': 'Rakesh Verma',
      'title': 'Product Manager', 'phone': '+91 99887 66554', 'email': 'isha@example.com',
      'officialEmail': 'isha@company.com', 'aadhaar': 'XXXX-XXXX-5678', 'pan': 'PQRSX6789Z',
      'presentAddress': 'Sector 18, Noida', 'permanentAddress': 'Lucknow, UP'
    },
    {
      'firstName': 'Rahul', 'lastName': 'Gupta', 'fatherName': 'Vijay Gupta',
      'title': 'QA Analyst', 'phone': '+91 99001 22334', 'email': 'rahul@example.com',
      'officialEmail': 'rahul@company.com', 'aadhaar': 'XXXX-XXXX-9012', 'pan': 'LMNOP9012Q',
      'presentAddress': 'DLF Phase 1, Gurugram', 'permanentAddress': 'Kanpur, UP'
    },
    {
      'firstName': 'Neha', 'lastName': 'Singh', 'fatherName': 'Suraj Singh',
      'title': 'HR Executive', 'phone': '+91 91234 56789', 'email': 'neha@example.com',
      'officialEmail': 'neha@company.com', 'aadhaar': 'XXXX-XXXX-3456', 'pan': 'QRSTU3456V',
      'presentAddress': 'Andheri West, Mumbai', 'permanentAddress': 'Prayagraj, UP'
    },
    {
      'firstName': 'Vikram', 'lastName': 'Mehta', 'fatherName': 'Anil Mehta',
      'title': 'DevOps Engineer', 'phone': '+91 90123 45678', 'email': 'vikram@example.com',
      'officialEmail': 'vikram@company.com', 'aadhaar': 'XXXX-XXXX-7890', 'pan': 'UVWXY7890A',
      'presentAddress': 'Kondapur, Hyderabad', 'permanentAddress': 'Ahmedabad, Gujarat'
    },
  ];

  String get _query => _searchController.text.trim().toLowerCase();

  List<Map<String, String>> get _filteredEmployees {
    if (_query.isEmpty) return _employees;
    return _employees.where((e) {
      final first = (e['firstName'] ?? '').toLowerCase();
      final last = (e['lastName'] ?? '').toLowerCase();
      final fullName = (first + ' ' + last).trim();
      final title = (e['title'] ?? '').toLowerCase();
      final phone = (e['phone'] ?? '').toLowerCase();
      final email = (e['email'] ?? '').toLowerCase();
      return fullName.contains(_query) || title.contains(_query) || phone.contains(_query) || email.contains(_query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _pageAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _pageFade = CurvedAnimation(parent: _pageAnimController!, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageAnimController!, curve: Curves.easeOutCubic));
    // Start the page entrance animation
    _pageAnimController!.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageAnimController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEmployees;
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: const GradientAppBar(title: 'Employees'),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FadeTransition(
            opacity: _pageFade ?? const AlwaysStoppedAnimation(1.0),
            child: SlideTransition(
              position: _pageSlide ?? const AlwaysStoppedAnimation(Offset.zero),
              child: Column(
                children: [
              // Search Section
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search employees...',
                    prefixIcon: Icon(Icons.search, color: AppTheme.primaryBlue),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Header
              Row(
                children: [
                  Icon(Icons.people_outline, color: AppTheme.primaryBlue, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Team Members',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filtered.length} employees',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Employee List
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final emp = filtered[index];
                          final firstName = emp['firstName']!;
                          final lastName = emp['lastName']!;
                          final name = (firstName + ' ' + lastName).trim();
                          final title = emp['title']!;
                          final phone = emp['phone']!;
                          final email = emp['email']!;
                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: Duration(milliseconds: 250 + (index % 12) * 30),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 12),
                                  child: child,
                                ),
                              );
                            },
                            child: _EmployeeCard(
                              employee: emp,
                              name: name,
                              title: title,
                              phone: phone,
                              email: email,
                              onTap: () => _navigateToDetails(context, emp, index),
                              onEdit: () => _openEditDialog(context, emp, index),
                              onDelete: () => _confirmDelete(context, index),
                            ),
                          );
                        },
                      ),
              ),
            ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'New Employee',
        onPressed: () async {
          final created = await Navigator.of(context).push<Map<String, String>>(
            MaterialPageRoute(builder: (_) => const EmployeeFormScreen()),
          );
          if (created != null) {
            setState(() {
              _employees.insert(0, created);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToDetails(BuildContext context, Map<String, String> emp, int index) {
    final firstName = emp['firstName']!;
    final lastName = emp['lastName']!;
    final title = emp['title']!;
    final phone = emp['phone']!;
    final email = emp['email']!;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmployeeDetailsScreen(
          firstName: firstName,
          lastName: lastName,
          fatherName: emp['fatherName'] ?? '',
          title: title,
          phone: phone,
          email: email,
          officialEmail: emp['officialEmail'] ?? '',
          aadhaar: emp['aadhaar'] ?? '',
          pan: emp['pan'] ?? '',
          presentAddress: emp['presentAddress'] ?? '',
          permanentAddress: emp['permanentAddress'] ?? '',
          onEdit: (updated) {
            setState(() {
              _employees[index] = updated;
            });
          },
          onDelete: () {
            setState(() {
              _employees.removeAt(index);
            });
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete employee'),
        content: const Text('Are you sure you want to delete this employee?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _employees.removeAt(index);
      });
    }
  }

  Future<void> _openEditDialog(BuildContext context, Map<String, String> emp, int index) async {
    final firstNameC = TextEditingController(text: emp['firstName'] ?? '');
    final lastNameC = TextEditingController(text: emp['lastName'] ?? '');
    final fatherNameC = TextEditingController(text: emp['fatherName'] ?? '');
    final titleC = TextEditingController(text: emp['title'] ?? '');
    final phoneC = TextEditingController(text: emp['phone'] ?? '');
    final emailC = TextEditingController(text: emp['email'] ?? '');
    final officialEmailC = TextEditingController(text: emp['officialEmail'] ?? '');
    final aadhaarC = TextEditingController(text: emp['aadhaar'] ?? '');
    final panC = TextEditingController(text: emp['pan'] ?? '');
    final presentAddressC = TextEditingController(text: emp['presentAddress'] ?? '');
    final permanentAddressC = TextEditingController(text: emp['permanentAddress'] ?? '');

    await showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Edit Employee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _tf(firstNameC, 'First name'),
                        const SizedBox(height: 8),
                        _tf(lastNameC, 'Last name'),
                        const SizedBox(height: 8),
                        _tf(fatherNameC, 'Father name'),
                        const SizedBox(height: 8),
                        _tf(titleC, 'Title'),
                        const SizedBox(height: 8),
                        _tf(phoneC, 'Phone'),
                        const SizedBox(height: 8),
                        _tf(emailC, 'Email'),
                        const SizedBox(height: 8),
                        _tf(officialEmailC, 'Official email'),
                        const SizedBox(height: 8),
                        _tf(aadhaarC, 'Aadhaar'),
                        const SizedBox(height: 8),
                        _tf(panC, 'PAN'),
                        const SizedBox(height: 8),
                        _tf(presentAddressC, 'Present address'),
                        const SizedBox(height: 8),
                        _tf(permanentAddressC, 'Permanent address'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final updated = <String, String>{
                          'firstName': firstNameC.text.trim(),
                          'lastName': lastNameC.text.trim(),
                          'fatherName': fatherNameC.text.trim(),
                          'title': titleC.text.trim(),
                          'phone': phoneC.text.trim(),
                          'email': emailC.text.trim(),
                          'officialEmail': officialEmailC.text.trim(),
                          'aadhaar': aadhaarC.text.trim(),
                          'pan': panC.text.trim(),
                          'presentAddress': presentAddressC.text.trim(),
                          'permanentAddress': permanentAddressC.text.trim(),
                        };
                        setState(() {
                          _employees[index] = updated;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  

  Widget _tf(TextEditingController c, String label) {
    return TextField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final Map<String, String> employee;
  final String name;
  final String title;
  final String phone;
  final String email;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeCard({
    required this.employee,
    required this.name,
    required this.title,
    required this.phone,
    required this.email,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.primaryBlueLight,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Employee Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              phone,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        tooltip: 'Edit',
                        icon: Icon(Icons.edit_outlined, color: AppTheme.primaryBlue, size: 20),
                        onPressed: onEdit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.accentRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        tooltip: 'Delete',
                        icon: Icon(Icons.delete_outline, color: AppTheme.accentRed, size: 20),
                        onPressed: onDelete,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.primaryBlue.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Employees Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


