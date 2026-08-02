import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/data/providers.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _biometricsAvailable = false;

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: AppConfig.googleWebClientId.isNotEmpty ? AppConfig.googleWebClientId : null,
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await ref.read(biometricServiceProvider).isAvailable();
    if (mounted) {
      setState(() => _biometricsAvailable = available);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authNotifier = ref.read(authStateProvider.notifier);
      final success = await authNotifier.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          context.go('/dashboard');
        } else {
          final error = ref.read(authStateProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Login failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _isLoading = true);

    final authenticated = await ref.read(biometricServiceProvider).authenticate();
    if (authenticated && mounted) {
      try {
        final authNotifier = ref.read(authStateProvider.notifier);
        await authNotifier.checkAuthStatus();
        if (mounted) {
          setState(() => _isLoading = false);
          context.go('/dashboard');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Biometric login failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      final authNotifier = ref.read(authStateProvider.notifier);
      final success = await authNotifier.googleLogin(idToken);

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          context.go('/dashboard');
        } else {
          final error = ref.read(authStateProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Google login failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google login failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.p24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSizes.r20),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 32),

                // Title
                Center(
                  child: Text(
                    AppStrings.loginTitle,
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.s28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                const SizedBox(height: 8),

                // Subtitle
                Center(
                  child: Text(
                    AppStrings.loginSubtitle,
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.s16,
                      color: AppColors.grey500,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

                const SizedBox(height: 48),

                // Email field
                CustomTextField(
                  controller: _emailController,
                  labelText: AppStrings.emailLabel,
                  hintText: 'Enter your email or employee ID',
                  prefixIcon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  textInputAction: TextInputAction.next,
                ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                const SizedBox(height: 16),

                // Password field
                CustomTextField(
                  controller: _passwordController,
                  labelText: AppStrings.passwordLabel,
                  hintText: 'Enter your password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  validator: Validators.required,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.grey400,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

                const SizedBox(height: 12),

                // Remember me & Forgot password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() => _rememberMe = value ?? false);
                            },
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.rememberMe,
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.s14,
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to forgot password
                      },
                      child: Text(
                        AppStrings.forgotPassword,
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.s14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

                const SizedBox(height: 24),

                // Login button
                PrimaryButton(
                  text: AppStrings.loginButton,
                  onPressed: _handleLogin,
                  isLoading: _isLoading,
                  width: double.infinity,
                ).animate().fadeIn(delay: 700.ms, duration: 600.ms),

                const SizedBox(height: 16),

                // Biometric login
                if (_biometricsAvailable)
                  PrimaryButton(
                    text: AppStrings.loginWithBiometrics,
                    onPressed: _handleBiometricLogin,
                    isOutlined: true,
                    icon: Icons.fingerprint_rounded,
                    width: double.infinity,
                  ).animate().fadeIn(delay: 800.ms, duration: 600.ms),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.grey200)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        AppStrings.orContinueWith,
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.s12,
                          color: AppColors.grey400,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.grey200)),
                  ],
                ).animate().fadeIn(delay: 900.ms, duration: 600.ms),

                const SizedBox(height: 24),

                // Social login buttons
                Row(
                  children: [
                    Expanded(
                      child: _SocialButton(
                        icon: Icons.g_mobiledata_rounded,
                        label: 'Google',
                        onTap: _handleGoogleLogin,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SocialButton(
                        icon: Icons.apple_rounded,
                        label: 'Apple',
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SocialButton(
                        icon: Icons.business_rounded,
                        label: 'SSO',
                        onTap: () {},
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),

                const SizedBox(height: 32),

                // Contact admin
                Center(
                  child: TextButton(
                    onPressed: () async {
                      final uri = Uri(
                        scheme: 'mailto',
                        path: 'admin@elevatehr.com',
                        query: Uri.encodeFull('subject=Account Request - Elevate HR&body=Hello Admin,\n\nI would like to request an account for the Elevate HR system.\n\nName:\nDepartment:\nPosition:\n\nThank you.'),
                      );
                      try {
                        await launchUrl(uri);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Could not open email client'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    child: RichText(
                      text: TextSpan(
                        text: '${AppStrings.noAccount} ',
                        style: GoogleFonts.inter(
                          fontSize: AppSizes.s14,
                          color: AppColors.grey500,
                        ),
                        children: [
                          TextSpan(
                            text: AppStrings.contactAdmin,
                            style: GoogleFonts.inter(
                              fontSize: AppSizes.s14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 1100.ms, duration: 600.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.r12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.p14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grey200),
          borderRadius: BorderRadius.circular(AppSizes.r12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: AppColors.grey600),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: AppSizes.s14,
                fontWeight: FontWeight.w500,
                color: AppColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
