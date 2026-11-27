import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';

/// Bottom navigation shell for all authority roles.
class OfficerShell extends ConsumerWidget {
  const OfficerShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    final tabs = [
      _Tab(Routes.officerDashboard, Icons.dashboard_rounded,       'Dashboard'),
      _Tab(Routes.officerIssues,    Icons.list_alt_rounded,        'Issues'),
      _Tab(Routes.officerMap,       Icons.map_rounded,             'Map'),
      _Tab(Routes.officerAnalytics, Icons.bar_chart_rounded,       'Analytics'),
      _Tab(Routes.officerProfile,   Icons.person_outline_rounded,  'Profile'),
    ];

    final currentIdx = tabs.indexWhere((t) => location.startsWith(t.route));

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIdx < 0 ? 0 : currentIdx,
        onDestinationSelected: (i) => context.go(tabs[i].route),
        destinations: tabs
            .map((t) => NavigationDestination(
                  icon:  Icon(t.icon),
                  label: t.label,
                ))
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
