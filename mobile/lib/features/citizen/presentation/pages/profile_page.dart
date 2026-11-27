import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/providers.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Avatar + name ──────────────────────────────────────
            Center(
              child: Column(children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? Text(
                          _initials(user?.fullName ?? 'U'),
                          style: theme.textTheme.headlineMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const Gap(12),
                Text(
                  user?.fullName ?? '—',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Gap(4),
                Text(user?.email ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const Gap(6),
                _RolePill(role: user?.role ?? 'CITIZEN'),
              ]),
            ),
            const Gap(24),

            // ── Stats ──────────────────────────────────────────────
            _StatsRow(ref: ref),
            const Gap(24),

            // ── Menu items ─────────────────────────────────────────
            _Section(children: [
              _MenuItem(
                icon:    Icons.list_alt_rounded,
                label:   'My Reports',
                onTap:   () => context.push(Routes.myIssues),
              ),
              _MenuItem(
                icon:    Icons.bookmark_outline_rounded,
                label:   'Bookmarks',
                onTap:   () => context.push(Routes.bookmarks),
              ),
              _MenuItem(
                icon:    Icons.receipt_long_outlined,
                label:   'Track Complaint',
                onTap:   () => context.push(Routes.trackIssue),
              ),
            ]),
            const Gap(12),

            _Section(children: [
              _MenuItem(
                icon:    Icons.settings_outlined,
                label:   'Settings',
                onTap:   () => context.push(Routes.settings),
              ),
              _MenuItem(
                icon:    Icons.help_outline_rounded,
                label:   'Help & FAQ',
                onTap:   () {},
              ),
              _MenuItem(
                icon:    Icons.info_outline_rounded,
                label:   'About CivicConnect',
                onTap:   () {},
              ),
            ]),
            const Gap(12),

            // ── Logout ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref
                      .read(authNotifierProvider.notifier)
                      .logout();
                  if (context.mounted) context.go(Routes.login);
                },
                icon:  const Icon(Icons.logout_rounded,
                    color: Colors.red),
                label: const Text('Log Out',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red)),
              ),
            ),
            const Gap(24),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          role.replaceAll('_', ' '),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
      );
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myCount =
        ref.watch(myIssuesNotifierProvider).valueOrNull?.length ?? 0;
    final bookmarks = ref.watch(bookmarkNotifierProvider).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Stat(value: '$myCount', label: 'Reports'),
        _Stat(value: '$bookmarks', label: 'Bookmarks'),
        const _Stat(value: '—', label: 'Resolved'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Text(value,
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700)),
      Text(label,
          style: theme.textTheme.labelSmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    ]);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        child: Column(children: children),
      );
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData  icon;
  final String    label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading:  Icon(icon),
        title:    Text(label),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap:    onTap,
      );
}
