import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/theme/app_colors.dart';
import 'package:attendance/core/theme/app_dimensions.dart';
import 'package:attendance/core/widgets/app_button.dart';
import 'package:attendance/core/widgets/app_confirm_dialog.dart';
import 'package:attendance/core/widgets/app_text_field.dart';
import 'package:attendance/services/auth_service.dart';
import 'package:attendance/state/dashboard_provider.dart';
import 'package:attendance/state/profile_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  static final RegExp _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await AuthService().login(email: _emailController.text.trim(), password: _passwordController.text);

        if (!mounted) return;
        context.read<ProfileProvider>().resetSession();
        context.read<DashboardProvider>().reset();
        await context.read<ProfileProvider>().refresh();

        if (!mounted) return;
        AppFeedback.success(context, 'Signed in');
        Navigator.of(context).pushReplacementNamed('/main');
      } catch (e) {
        if (!mounted) return;
        AppFeedback.error(context, e);
      } finally {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleForgotPassword() {
    AppConfirmDialog.showInfo(
      context,
      title: 'Forgot password',
      message: 'Please contact your administrator to reset your password.',
      icon: Icons.lock_reset_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textTheme = theme.textTheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final gradientColors = isDark ? AppColors.loginGradientDark : AppColors.loginGradientLight;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: gradientColors.first,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
            stops: const [0.0, 1.0],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: -120,
              right: -60,
              child: _DecorativeOrb(size: 220, color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.08)),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: _DecorativeOrb(size: 200, color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.06)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final verticalPad = AppDimensions.spacing16 + AppDimensions.spacing24 + bottomInset;
                  return SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      AppDimensions.spacing24,
                      AppDimensions.spacing16,
                      AppDimensions.spacing24,
                      AppDimensions.spacing24 + bottomInset,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - verticalPad),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: AppDimensions.contentMaxWidth),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: AppDimensions.spacing8),
                                Align(
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? theme.colorScheme.surface.withValues(alpha: 0.9)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(AppDimensions.radius20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.person_pin_circle_rounded,
                                      size: 40,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Text(
                                  'Welcome back',
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                    color: isDark ? theme.colorScheme.onSurface : Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppDimensions.spacing8),
                                Text(
                                  'Sign in to continue',
                                  style: textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? theme.colorScheme.onSurfaceVariant
                                        : Colors.white.withValues(alpha: 0.88),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppDimensions.spacing32),
                                AppTextField(
                                  controller: _emailController,
                                  hint: 'Email or username',
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.username],
                                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.primary),
                                  validator: (value) {
                                    final v = (value ?? '').trim();
                                    if (v.isEmpty) {
                                      return 'Please enter your email or username';
                                    }
                                    if (v.contains('@') && !_emailRegex.hasMatch(v)) {
                                      return 'Enter valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppDimensions.spacing16),
                                AppTextField(
                                  controller: _passwordController,
                                  hint: 'Password',
                                  obscureText: !_isPasswordVisible,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) {
                                    if (!_isLoading) _handleLogin();
                                  },
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                                  suffixIcon: IconButton(
                                    tooltip: _isPasswordVisible ? 'Hide password' : 'Show password',
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: _togglePasswordVisibility,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppDimensions.spacing4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _handleForgotPassword,
                                    style: TextButton.styleFrom(
                                      minimumSize: const Size(
                                        AppDimensions.minTouchTarget,
                                        AppDimensions.minTouchTarget,
                                      ),
                                      foregroundColor: isDark ? AppColors.primaryLight : Colors.white,
                                    ),
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppDimensions.spacing8),
                                Theme(
                                  data: theme.copyWith(
                                    filledButtonTheme: FilledButtonThemeData(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: isDark ? AppColors.primary : Colors.white,
                                        foregroundColor: isDark ? Colors.white : AppColors.primary,
                                        disabledBackgroundColor: isDark
                                            ? AppColors.primary.withValues(alpha: 0.5)
                                            : Colors.white.withValues(alpha: 0.7),
                                        minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                  child: AppButton(
                                    label: 'Sign In',
                                    loading: _isLoading,
                                    loadingLabel: 'Signing in',
                                    onPressed: _handleLogin,
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Text(
                                  'Contact your administrator if you need help accessing your account.',
                                  style: textTheme.bodySmall?.copyWith(
                                    height: 1.45,
                                    color: isDark
                                        ? theme.colorScheme.onSurfaceVariant
                                        : Colors.white.withValues(alpha: 0.75),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppDimensions.spacing8),
                              ],
                            ),
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
    );
  }
}

class _DecorativeOrb extends StatelessWidget {
  const _DecorativeOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
