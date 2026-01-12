import 'package:flutter/material.dart';

class EmployeeDetailsScreen extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String fatherName;
  final String title;
  final String phone;
  final String email;
  final String officialEmail;
  final String aadhaar;
  final String pan;
  final String presentAddress;
  final String permanentAddress;

  final void Function(Map<String, String>)? onEdit;
  final VoidCallback? onDelete;

  const EmployeeDetailsScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.fatherName,
    required this.title,
    required this.phone,
    required this.email,
    required this.officialEmail,
    required this.aadhaar,
    required this.pan,
    required this.presentAddress,
    required this.permanentAddress,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String name = (firstName + ' ' + lastName).trim();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Details'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              if (onEdit == null) return;
              final updated = await _openEditDialog(context);
              if (updated != null) {
                onEdit!(updated);
                Navigator.of(context).pop();
              }
            },
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (onDelete == null) return;
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
                onDelete!();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with gradient and avatar
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      child: Text(
                        name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.work_outline, color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(color: Colors.white70),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal
                      Row(
                        children: [
                          Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Personal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _KV(label: 'First name', value: firstName),
                      const Divider(height: 16),
                      _KV(label: 'Last name', value: lastName),
                      const Divider(height: 16),
                      _KV(label: 'Father name', value: fatherName),

                      const SizedBox(height: 16),
                      // Contact
                      Row(
                        children: [
                          Icon(Icons.call_outlined, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _KV(label: 'Phone', value: phone, icon: Icons.phone_outlined),
                      const Divider(height: 16),
                      _KV(label: 'Email', value: email, icon: Icons.email_outlined),
                      const Divider(height: 16),
                      _KV(label: 'Official email', value: officialEmail, icon: Icons.alternate_email_outlined),

                      const SizedBox(height: 16),
                      // IDs
                      Row(
                        children: [
                          Icon(Icons.verified_user_outlined, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('IDs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _KV(label: 'Aadhaar', value: aadhaar, icon: Icons.credit_card_outlined),
                      const Divider(height: 16),
                      _KV(label: 'PAN', value: pan, icon: Icons.badge_outlined),

                      const SizedBox(height: 16),
                      // Address
                      Row(
                        children: [
                          Icon(Icons.place_outlined, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text('Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _KV(label: 'Present address', value: presentAddress, icon: Icons.home_outlined),
                      const Divider(height: 16),
                      _KV(label: 'Permanent address', value: permanentAddress, icon: Icons.location_city_outlined),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<Map<String, String>?> _openEditDialog(BuildContext context) async {
    final firstNameC = TextEditingController(text: firstName);
    final lastNameC = TextEditingController(text: lastName);
    final fatherNameC = TextEditingController(text: fatherName);
    final titleC = TextEditingController(text: title);
    final phoneC = TextEditingController(text: phone);
    final emailC = TextEditingController(text: email);
    final officialEmailC = TextEditingController(text: officialEmail);
    final aadhaarC = TextEditingController(text: aadhaar);
    final panC = TextEditingController(text: pan);
    final presentAddressC = TextEditingController(text: presentAddress);
    final permanentAddressC = TextEditingController(text: permanentAddress);

    return showDialog<Map<String, String>>(
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
                        Navigator.pop<Map<String, String>>(context, <String, String>{
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
                        });
                      },
                      child: const Text('Save'),
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

class _KV extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;

  const _KV({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    final onVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: onVariant),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 110),
            child: Text(label, style: TextStyle(color: onVariant)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}


