import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/providers.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';

class OfficerProfilePage extends ConsumerWidget {
  const OfficerProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user      = authState is AuthAuthenticated ? authState.user : null;
    final theme     = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Avatar ──────────────────────────────────────────────
          Center(
            child: Column(children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  user?.fullName.isNotEmpty == true
                      ? user!.fullName[0].toUpperCase()
                      : 'O',
                  style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const Gap(12),
              Text(user?.fullName ?? '—',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const Gap(4),
              Text(user?.email ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const Gap(6),
              _RolePill(role: user?.role ?? ''),
            ]),
          ),
          const Gap(24),

          // ── Info ─────────────────────────────────────────────────
          Card(
            child: Column(children: [
              if (user?.municipalityId != null)
                ListTile(
                  leading: const Icon(Icons.location_city_rounded),
                  title: const Text('Municipality ID'),
                  subtitle: Text(user!.municipalityId!,
                      style: const TextStyle(fontFamily: 'monospace')),
                ),
              if (user?.departmentId != null)
                ListTile(
                  leading: const Icon(Icons.business_rounded),
                  title: const Text('Department ID'),
                  subtitle: Text(user!.departmentId!,
                      style: const TextStyle(fontFamily: 'monospace')),
                ),
            ]),
          ),
          const Gap(12),

          // ── Settings link ────────────────────────────────────────
          Card(
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(Routes.settings),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
            ]),
          ),
          const Gap(12),

          // ── Logout ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).logout();
                if (context.mounted) context.go(Routes.login);
              },
              icon:  const Icon(Icons.logout_rounded, color: Colors.red),
              label: const Text('Log Out',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color:        AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          role.replaceAll('_', ' '),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
      );
}
