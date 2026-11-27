import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/di/providers.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/date_utils.dart';
import '../../../../../shared/widgets/loading_indicator.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/issue_card.dart';

class CitizenHomePage extends ConsumerWidget {
  const CitizenHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState  = ref.watch(authNotifierProvider);
    final user       = authState is AuthAuthenticated ? authState.user : null;
    final feedState  = ref.watch(feedNotifierProvider);
    final myState    = ref.watch(myIssuesNotifierProvider);
    final theme      = Theme.of(context);
    final now        = DateTime.now();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ─────────────────────────────────────────────
          SliverAppBar(
            floating:    true,
            snap:        true,
            title:       const Text('CivicConnect'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () => context.push(Routes.feed),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push(Routes.notifications),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Welcome card ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary,
                               Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end:   Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good ${_greeting(now)},',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          const Gap(2),
                          Text(
                            user?.fullName.split(' ').first ?? 'Citizen',
                            style: theme.textTheme.titleLarge?.copyWith(
                                color:      Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                          const Gap(8),
                          Text(
                            AppDateUtils.formatDate(now),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: Colors.white60),
                          ),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius:          28,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        _initials(user?.fullName ?? 'U'),
                        style: const TextStyle(
                            color:      Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize:   20),
                      ),
                    ),
                  ]),
                ),
                const Gap(20),

                // ── Quick actions ──────────────────────────────────
                Row(children: [
                  _QuickAction(
                    icon:    Icons.add_circle_rounded,
                    label:   'Report',
                    color:   AppColors.primary,
                    onTap:   () => context.push(Routes.reportIssue),
                  ),
                  _QuickAction(
                    icon:    Icons.map_rounded,
                    label:   'Map',
                    color:   AppColors.secondary,
                    onTap:   () => context.push(Routes.mapsRoute),
                  ),
                  _QuickAction(
                    icon:    Icons.receipt_long_rounded,
                    label:   'Track',
                    color:   AppColors.tertiary,
                    onTap:   () => context.push(Routes.trackIssue),
                  ),
                  _QuickAction(
                    icon:    Icons.bookmark_rounded,
                    label:   'Saved',
                    color:   AppColors.statusAssigned,
                    onTap:   () => context.push(Routes.bookmarks),
                  ),
                ]),
                const Gap(20),

                // ── My recent reports ──────────────────────────────
                Row(children: [
                  Text('My Recent Reports',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push(Routes.myIssues),
                    child: const Text('See all'),
                  ),
                ]),
                const Gap(8),

                myState.when(
                  loading: () => const LoadingIndicator(size: 32),
                  error:   (_, __) => const SizedBox.shrink(),
                  data: (items) {
                    if (items.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:        theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(children: [
                          Icon(Icons.inbox_outlined,
                              color: theme.colorScheme.onSurfaceVariant),
                          const Gap(12),
                          Text('No reports yet — tap Report to get started',
                              style: theme.textTheme.bodySmall),
                        ]),
                      );
                    }
                    return Column(
                      children: items.take(3).map((i) => IssueCard(
                            issue:   i,
                            onTap:   () => context.push(
                                Routes.issueDetailPath(i.id)),
                            compact: true,
                          )).toList(),
                    );
                  },
                ),
                const Gap(20),

                // ── Community feed preview ─────────────────────────
                Row(children: [
                  Text('Community Feed',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push(Routes.feed),
                    child:     const Text('See all'),
                  ),
                ]),
                const Gap(8),

                feedState.when(
                  loading: () => const LoadingIndicator(size: 32),
                  error:   (_, __) => const SizedBox.shrink(),
                  data: (items) => Column(
                    children: items.take(3).map((i) => IssueCard(
                          issue:       i,
                          onTap:       () => context.push(
                              Routes.issueDetailPath(i.id)),
                          compact:     true,
                          isBookmarked: ref
                              .watch(bookmarkNotifierProvider)
                              .contains(i.id),
                          onBookmark:  () => ref
                              .read(bookmarkNotifierProvider.notifier)
                              .toggle(i.id),
                        )).toList(),
                  ),
                ),
                const Gap(16),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.reportIssue),
        icon:       const Icon(Icons.add_rounded),
        label:      const Text('Report Issue'),
      ),
    );
  }

  String _greeting(DateTime t) {
    if (t.hour < 12) return 'morning';
    if (t.hour < 17) return 'afternoon';
    return 'evening';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 26),
              const Gap(6),
              Text(label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
