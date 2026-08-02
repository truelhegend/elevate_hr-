import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/data/models/user.dart';
import '../../../core/data/providers.dart';
import '../../../main.dart';
import '../../../shared/widgets/custom_card.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = await ref.read(employeeRepositoryProvider).getProfile();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _user = ref.read(authRepositoryProvider).currentUser;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SafeArea(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _user;

    if (user == null) {
      return const SafeArea(
        child: Center(child: Text('Failed to load profile')),
      );
    }

    final themeProvider = ref.watch(themeProviderOverride);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          children: [
            CustomCard(
              padding: AppSizes.p24,
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primarySurface,
                        child: Text(
                          user.initials,
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.s22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.position,
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.s14,
                      color: AppColors.grey500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.s13,
                      color: AppColors.grey400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ProfileStat(label: 'Department', value: user.department),
                      Container(
                        width: 1,
                        height: 32,
                        color: AppColors.grey200,
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      _ProfileStat(label: 'Employee ID', value: user.employeeId),
                    ],
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.05, end: 0),

            const SizedBox(height: 16),

            _SettingsSection(
              title: AppStrings.settings,
              children: [
                _SettingsTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Edit Profile',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notification Settings',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Privacy & Security',
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.language_rounded,
                  title: AppStrings.language,
                  trailing: Text(
                    'English',
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.s14,
                      color: AppColors.grey500,
                    ),
                  ),
                  onTap: () {},
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 600.ms),

            const SizedBox(height: 16),

            _SettingsSection(
              title: 'Preferences',
              children: [
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: AppStrings.darkMode,
                  trailing: Switch(
                    value: themeProvider.isDark,
                    onChanged: (_) {
                      ref.read(themeProviderOverride.notifier).toggleTheme();
                    },
                    activeThumbColor: AppColors.primary,
                  ),
                  onTap: () {
                    ref.read(themeProviderOverride.notifier).toggleTheme();
                  },
                ),
                _SettingsTile(
                  icon: Icons.help_outline_rounded,
                  title: AppStrings.helpSupport,
                  onTap: () {},
                ),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: AppStrings.about,
                  trailing: Text(
                    AppStrings.version,
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.s14,
                      color: AppColors.grey500,
                    ),
                  ),
                  onTap: () {},
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms),

            const SizedBox(height: 16),

            CustomCard(
              padding: AppSizes.p16,
              onTap: () => _showLogoutDialog(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    AppStrings.logout,
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.s16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 600.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(color: AppColors.grey600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.cancel, style: GoogleFonts.inter(color: AppColors.grey500)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Text(
              AppStrings.logout,
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: AppSizes.s16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: AppSizes.s12,
            color: AppColors.grey500,
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: AppSizes.p8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: AppSizes.s13,
                fontWeight: FontWeight.w600,
                color: AppColors.grey500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.grey600),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: AppSizes.s15,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            if (trailing != null)
              trailing!
            else
              const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }
}
