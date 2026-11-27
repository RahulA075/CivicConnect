import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';

/// Bottom-navigation shell for MUNICIPAL_ADMIN / SYSTEM_ADMIN.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    const tabs = [
      _Tab(Routes.adminDashboard,   Icons.dashboard_rounded,         'Dashboard'),
      _Tab(Routes.adminUsers,       Icons.people_alt_rounded,        'Users'),
      _Tab(Routes.adminDepartments, Icons.business_rounded,          'Depts'),
      _Tab(Routes.adminAlerts,      Icons.warning_amber_rounded,     'Alerts'),
      _Tab(Routes.adminAuditLogs,   Icons.history_rounded,           'Audit'),
    ];

    final idx = tabs.indexWhere((t) => location.startsWith(t.route));

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx < 0 ? 0 : idx,
        onDestinationSelected: (i) => context.go(tabs[i].route),
        destinations: tabs
            .map((t) => NavigationDestination(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}

class _Tab {
  const _Tab(this.route, this.icon, this.label);
  final String   route;
  final IconData icon;
  final String   label;
}
