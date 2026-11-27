import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/admin_entities.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  void _loadAll() {
    final auth = ref.read(authNotifierProvider);
    if (auth is! AuthAuthenticated) return;
    final mid = auth.user.municipalityId;
    if (mid == null) return;
    ref.read(adminDepartmentsProvider.notifier).load(mid);
    ref.read(adminUsersProvider.notifier).load(mid);
    ref.read(adminAlertsProvider.notifier).load(mid, activeOnly: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final auth   = ref.watch(authNotifierProvider);
    final user   = auth is AuthAuthenticated ? auth.user : null;
    final depts  = ref.watch(adminDepartmentsProvider);
    final users  = ref.watch(adminUsersProvider);
    final alerts = ref.watch(adminAlertsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () => context.go(Routes.adminSlaRules),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadAll(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Welcome ──────────────────────────────────────────────
            _WelcomeCard(userName: user?.fullName ?? 'Admin',
                         role: user?.role ?? ''),
            const SizedBox(height: 20),

            // ── Quick stats ──────────────────────────────────────────
            Text('Overview', style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _StatCard(
                label: 'Departments',
                value: depts.when(
                    data: (l) => '${l.length}',
                    loading: () => '…',
                    error: (_, __) => '—'),
                icon: Icons.business_rounded,
                color: Colors.blue,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Officers',
                value: users.when(
                    data: (l) => '${l.length}',
                    loading: () => '…',
                    error: (_, __) => '—'),
                icon: Icons.badge_rounded,
                color: Colors.green,
              )),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(
                label: 'Active Alerts',
                value: alerts.when(
                    data: (l) => '${l.where((a) => a.active).length}',
                    loading: () => '…',
                    error: (_, __) => '—'),
                icon: Icons.warning_rounded,
                color: Colors.orange,
              )),
            ]),
            const SizedBox(height: 24),

            // ── Quick actions ────────────────────────────────────────
            Text('Quick Actions', style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _QuickActionGrid(municipalityId:
                user?.municipalityId ?? ''),
            const SizedBox(height: 24),

            // ── Active emergency alerts ───────────────────────────────
            Builder(builder: (_) {
              if (alerts is! AsyncData<List<EmergencyAlertEntity>>) {
                return const SizedBox.shrink();
              }
              final alertList =
                  alerts.value;
              if (alertList.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Alerts',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700)),
                  const SizedBox(height: 8),
                  ...alertList
                      .take(3)
                      .map((a) => _AlertTile(a.title, a.severity)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go(Routes.adminAlerts),
                    child: const Text('View all alerts →'),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.userName, required this.role});
  final String userName;
  final String role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const CircleAvatar(radius: 28, child: Icon(Icons.admin_panel_settings_rounded, size: 28)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Welcome back,', style: theme.textTheme.bodySmall),
            Text(userName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(role.replaceAll('_', ' '),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.primary)),
          ]),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.municipalityId});
  final String municipalityId;

  @override
  Widget build(BuildContext context) {
    final items = [
      _QA('Departments', Icons.business_rounded,     Routes.adminDepartments),
      _QA('Categories',  Icons.category_rounded,     Routes.adminCategories),
      _QA('SLA & Rules', Icons.rule_rounded,         Routes.adminSlaRules),
      _QA('Invite User', Icons.person_add_rounded,   Routes.adminUsers),
      _QA('Alerts',      Icons.campaign_rounded,     Routes.adminAlerts),
      _QA('Audit Log',   Icons.history_rounded,      Routes.adminAuditLogs),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, childAspectRatio: 1.0,
          crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final qa = items[i];
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(qa.route),
          child: Card(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(qa.icon, size: 28,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 8),
                Text(qa.label,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QA {
  const _QA(this.label, this.icon, this.route);
  final String   label;
  final IconData icon;
  final String   route;
}

class _AlertTile extends StatelessWidget {
  const _AlertTile(this.title, this.severity);
  final String title;
  final String severity;

  Color _color() => switch (severity) {
        'CRITICAL' => Colors.red.shade700,
        'HIGH'     => Colors.orange.shade700,
        'MEDIUM'   => Colors.amber.shade700,
        _          => Colors.blue.shade700,
      };

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(Icons.warning_rounded, color: _color()),
        title: Text(title),
        subtitle: Text(severity),
        dense: true,
      );
}
