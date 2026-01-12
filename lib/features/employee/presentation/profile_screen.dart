import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:attendance/core/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mock profile data; in a real app this would come from a service/store
  String name = 'Aarav Sharma';
  String designation = 'Software Engineer';
  String phone = '+91 98765 43210';
  String email = 'aarav@example.com';
  String address = '123 MG Road, Dehradun';

  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  PlatformFile? _avatar;
  bool _editing = false;

  final _phoneC = TextEditingController();
  final _emailC = TextEditingController();
  final _addressC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _phoneC.text = phone;
    _emailC.text = email;
    _addressC.text = address;
  }

  @override
  void dispose() {
    _phoneC.dispose();
    _emailC.dispose();
    _addressC.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefix,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: const OutlineInputBorder(),
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
      );
      if (res != null && res.files.isNotEmpty) {
        setState(() => _avatar = res.files.first);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'Profile',
        showBack: true,
        showProfileAction: false,
        actions: [
          IconButton(
            tooltip: _editing ? 'Cancel' : 'Edit',
            icon: Icon(_editing ? Icons.close : Icons.edit_outlined, color: Colors.white),
            onPressed: () {
              setState(() {
                _editing = !_editing;
                if (!_editing) {
                  // reset controllers to current values on cancel
                  _phoneC.text = phone;
                  _emailC.text = email;
                  _addressC.text = address;
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: _editing
                          ? GestureDetector(
                              onTap: _pickAvatar,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.primaryBlueLight]),
                                      boxShadow: [
                                        BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 6)),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: _avatar?.path != null
                                          ? Image.file(
                                              File(_avatar!.path!),
                                              fit: BoxFit.cover,
                                            )
                                          : const Center(child: Icon(Icons.person, color: Colors.white, size: 48)),
                                    ),
                                  ),
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 3)),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(Icons.camera_alt_outlined, size: 16, color: AppTheme.primaryBlue),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: [AppTheme.primaryBlue, AppTheme.primaryBlueLight]),
                                boxShadow: [
                                  BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 6)),
                                ],
                              ),
                              child: ClipOval(
                                child: _avatar?.path != null
                                    ? Image.file(
                                        File(_avatar!.path!),
                                        fit: BoxFit.cover,
                                      )
                                    : const Center(child: Icon(Icons.person, color: Colors.white, size: 48)),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      designation,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Contact', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                if (!_editing) ...[
                  _InfoItem(label: 'E-Mail', value: email, leading: const Icon(Icons.email_outlined, color: Colors.grey)),
                  const SizedBox(height: 12),
                  _InfoItem(label: 'Mobile', value: phone, leading: const Icon(Icons.phone_outlined, color: Colors.grey)),
                  const SizedBox(height: 12),
                  _InfoItem(label: 'Address', value: address, leading: const Icon(Icons.home_outlined, color: Colors.grey)),
                  const SizedBox(height: 8),
                ] else ...[
                  TextField(
                    controller: _emailC,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec('E-Mail', prefix: Icon(Icons.email_outlined, color: AppTheme.primaryBlue)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneC,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: _dec('Mobile', prefix: Icon(Icons.phone_outlined, color: AppTheme.primaryBlue)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressC,
                    maxLines: 2,
                    decoration: _dec('Address', prefix: Icon(Icons.home_outlined, color: AppTheme.primaryBlue)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final nextEmail = _emailC.text.trim();
                        final nextPhone = _phoneC.text.trim();

                        if (nextEmail.isNotEmpty && !_emailRegex.hasMatch(nextEmail)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enter valid email')),
                          );
                          return;
                        }

                        if (nextPhone.isNotEmpty && nextPhone.length != 10) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Enter 10-digit phone number')),
                          );
                          return;
                        }

                        setState(() {
                          email = nextEmail;
                          phone = nextPhone;
                          address = _addressC.text.trim();
                          _editing = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Widget? leading;
  const _InfoItem({required this.label, required this.value, this.leading});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[
              Padding(padding: const EdgeInsets.only(top: 2), child: leading!),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(value.isEmpty ? '-' : value, style: TextStyle(fontSize: 15, color: Colors.grey.shade900, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


