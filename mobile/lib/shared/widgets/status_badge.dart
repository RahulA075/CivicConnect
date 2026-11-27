import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Coloured chip that displays an issue status or priority label.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  /// Constructs a badge from a status string (e.g. 'IN_PROGRESS').
  factory StatusBadge.status(String status, {Key? key}) => StatusBadge(
        key: key,
        label: status,
        color: _statusColor(status),
      );

  /// Constructs a badge from a priority string (e.g. 'HIGH').
  factory StatusBadge.priority(String priority, {Key? key}) => StatusBadge(
        key: key,
        label: priority,
        color: _priorityColor(priority),
      );

  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color:        color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border:       Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label.replaceAll('_', ' '),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color:      color,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
        ),
      );

  static Color _statusColor(String status) => switch (status.toUpperCase()) {
        'SUBMITTED'   => AppColors.statusSubmitted,
        'ASSIGNED'    => AppColors.statusAssigned,
        'IN_PROGRESS' => AppColors.statusInProgress,
        'RESOLVED'    => AppColors.statusResolved,
        'CLOSED'      => AppColors.statusClosed,
        _             => AppColors.statusSubmitted,
      };

  static Color _priorityColor(String priority) =>
      switch (priority.toUpperCase()) {
        'LOW'      => AppColors.priorityLow,
        'MEDIUM'   => AppColors.priorityMedium,
        'HIGH'     => AppColors.priorityHigh,
        'CRITICAL' => AppColors.priorityCritical,
        _          => AppColors.priorityMedium,
      };
}
