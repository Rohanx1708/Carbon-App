import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:attendance/core/widgets/app_loader.dart';
import 'package:attendance/core/widgets/app_skeleton.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/theme/app_theme.dart';
import 'package:attendance/core/theme/theme_context.dart';
import 'package:attendance/core/widgets/app_confirm_dialog.dart';
import 'package:attendance/core/widgets/app_form_decoration.dart';
import 'package:attendance/core/widgets/app_topbar.dart';
import 'package:attendance/features/auth/presentation/login_screen.dart';
import 'package:attendance/features/profile/data/profile_models.dart';
import 'package:attendance/state/main_nav_provider.dart';
import 'package:attendance/state/profile_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  final _nameC = TextEditingController();
  final _emailC = TextEditingController();
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadIfNeeded();
    });
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    super.dispose();
  }

  static String _formatEmploymentType(String raw) {
    if (raw.trim().isEmpty) return '-';
    return raw.replaceAll('_', ' ');
  }

  void _syncControllers(UserProfile profile) {
    if (_editing) return;
    _nameC.text = profile.name;
    _emailC.text = profile.email;
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false,
        withData: false,
      );
      if (res == null || res.files.isEmpty) return;
      final file = res.files.first;
      final path = file.path;
      if (path == null) return;

      final size = file.size;
      if (size > 5 * 1024 * 1024) {
        if (!mounted) return;
        AppFeedback.info(context, 'Image must be 5 MB or smaller');
        return;
      }

      final ok = await context.read<ProfileProvider>().uploadAvatar(filePath: path, filename: file.name);
      if (!mounted) return;
      if (ok) {
        AppFeedback.success(context, 'Avatar updated');
      } else {
        AppFeedback.error(context, context.read<ProfileProvider>().error ?? Exception('Upload failed'));
      }
    } catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e);
    }
  }

  Future<void> _saveProfile() async {
    final name = _nameC.text.trim();
    final email = _emailC.text.trim();
    if (name.isEmpty) {
      AppFeedback.info(context, 'Name is required');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      AppFeedback.info(context, 'Enter a valid email');
      return;
    }

    final ok = await context.read<ProfileProvider>().updateProfile(name: name, email: email);
    if (!mounted) return;
    if (ok) {
      setState(() => _editing = false);
      AppFeedback.success(context, 'Profile updated');
    } else {
      AppFeedback.error(context, context.read<ProfileProvider>().error ?? Exception('Update failed'));
    }
  }

  Future<void> _showChangePassword() async {
    final currentC = TextEditingController();
    final passwordC = TextEditingController();
    final confirmC = TextEditingController();

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Change password', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: currentC,
                obscureText: true,
                decoration: AppFormDecoration.field(label: 'Current password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordC,
                obscureText: true,
                decoration: AppFormDecoration.field(label: 'New password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmC,
                obscureText: true,
                decoration: AppFormDecoration.field(label: 'Confirm new password'),
              ),
              const SizedBox(height: 20),
              FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Update password')),
            ],
          ),
        );
      },
    );

    if (submitted != true || !mounted) {
      currentC.dispose();
      passwordC.dispose();
      confirmC.dispose();
      return;
    }

    final currentPassword = currentC.text;
    final password = passwordC.text;
    final confirm = confirmC.text;
    currentC.dispose();
    passwordC.dispose();
    confirmC.dispose();

    if (password.length < 8) {
      AppFeedback.info(context, 'Password must be at least 8 characters');
      return;
    }
    if (password != confirm) {
      AppFeedback.info(context, 'Passwords do not match');
      return;
    }

    final ok = await context.read<ProfileProvider>().changePassword(
      currentPassword: currentPassword,
      password: password,
      passwordConfirmation: confirm,
    );
    if (!mounted) return;
    if (ok) {
      AppFeedback.success(context, 'Password updated');
    } else {
      AppFeedback.error(context, context.read<ProfileProvider>().error ?? Exception('Failed'));
    }
  }

  Future<void> _logout() async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Log out',
      message: 'Sign out and return to the login screen?',
      confirmLabel: 'Log out',
      destructive: true,
      icon: Icons.logout_rounded,
    );
    if (ok != true || !mounted) return;

    await context.read<ProfileProvider>().logout();
    context.read<MainNavProvider>().setIndex(0);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  Widget _avatar(UserProfile profile) {
    final url = profile.avatarUrl;
    Widget image;
    if (url != null) {
      image = Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 48),
      );
    } else {
      image = const Icon(Icons.person, color: Colors.white, size: 48);
    }

    return GestureDetector(
      onTap: context.watch<ProfileProvider>().saving ? null : _pickAndUploadAvatar,
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
            child: ClipOval(child: image),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    if (profile != null) {
      _syncControllers(profile);
    }

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Profile',
        showBack: true,
        showProfileAction: false,
        actions: [
          if (profile != null)
            IconButton(
              tooltip: _editing ? 'Cancel' : 'Edit',
              icon: Icon(_editing ? Icons.close : Icons.edit_outlined, color: Colors.white),
              onPressed: provider.saving
                  ? null
                  : () {
                      setState(() {
                        _editing = !_editing;
                        if (!_editing) {
                          final p = context.read<ProfileProvider>().profile;
                          if (p != null) {
                            _nameC.text = p.name;
                            _emailC.text = p.email;
                          }
                        }
                      });
                    },
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (provider.loading && profile == null) {
            return const AppSkeletonDetail();
          }
          if (profile == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Could not load profile', style: TextStyle(color: context.textSecondary)),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: provider.refresh, child: const Text('Retry')),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 8)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      children: [
                        Center(child: _avatar(profile)),
                        const SizedBox(height: 12),
                        if (!_editing)
                          Text(
                            profile.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: context.textPrimary),
                          )
                        else
                          TextField(
                            controller: _nameC,
                            textInputAction: TextInputAction.next,
                            decoration: AppFormDecoration.field(
                              label: 'Name',
                              prefixIcon: Icon(Icons.person_outline, color: AppTheme.primaryBlue),
                            ),
                          ),
                        if (!_editing) ...[
                          if (profile.email.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _ContactLine(icon: Icons.email_outlined, text: profile.email),
                          ],
                          if ((profile.employee?.phone ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            _ContactLine(icon: Icons.phone_outlined, text: profile.employee!.phone),
                          ],
                        ] else ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailC,
                            keyboardType: TextInputType.emailAddress,
                            decoration: AppFormDecoration.field(
                              label: 'E-Mail',
                              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.primaryBlue),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (_editing) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: provider.saving ? null : _saveProfile,
                          icon: provider.saving
                              ? const AppProgress(size: AppLoaderSize.small)
                              : const Icon(Icons.save_outlined),
                          label: Text(provider.saving ? 'Saving…' : 'Save'),
                        ),
                      ),
                    ],
                    if (profile.employee != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Employment',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      _InfoItem(
                        label: 'Designation',
                        value: profile.employee!.designation,
                        leading: const Icon(Icons.work_outline, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      _InfoItem(
                        label: 'Department',
                        value: profile.employee!.department,
                        leading: const Icon(Icons.apartment_outlined, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      _InfoItem(
                        label: 'Reporting manager',
                        value: profile.employee!.reportingManager?.name ?? 'None',
                        leading: const Icon(Icons.supervisor_account_outlined, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      _InfoItem(
                        label: 'Employment type',
                        value: _formatEmploymentType(profile.employee!.employmentType),
                        leading: const Icon(Icons.schedule_outlined, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      _InfoItem(
                        label: 'Status',
                        value: profile.employee!.status,
                        leading: const Icon(Icons.info_outline, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: provider.saving ? null : _showChangePassword,
                      icon: const Icon(Icons.lock_outline),
                      label: const Text('Change password'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: provider.saving ? null : _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Log out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(color: Theme.of(context).colorScheme.error.withOpacity(0.5)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: context.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: context.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.label, required this.value, this.leading});

  final String label;
  final String value;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.subtleBorder),
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
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value.isEmpty ? '-' : value,
                    style: TextStyle(fontSize: 15, color: context.textPrimary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
