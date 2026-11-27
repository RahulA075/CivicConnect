import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationPreferencesPage extends ConsumerWidget {
  const NotificationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPrefsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: prefsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (prefs) => _PrefsForm(prefs: prefs),
      ),
    );
  }
}

class _PrefsForm extends ConsumerStatefulWidget {
  const _PrefsForm({required this.prefs});
  final NotificationPreferencesEntity prefs;

  @override
  ConsumerState<_PrefsForm> createState() => _PrefsFormState();
}

class _PrefsFormState extends ConsumerState<_PrefsForm> {
  late bool _push;
  late bool _email;
  late bool _sms;
  late Map<String, bool> _overrides;

  // Event types and their labels
  static const _eventTypes = {
    'ISSUE_SUBMITTED': 'Issue Submitted',
    'STATUS_CHANGE':   'Status Updates',
    'ASSIGNMENT':      'Assignments',
    'NEARBY_ISSUE':    'Nearby Issues',
    'EMERGENCY_ALERT': 'Emergency Alerts',
    'ANNOUNCEMENT':    'Announcements',
  };

  @override
  void initState() {
    super.initState();
    _push      = widget.prefs.pushEnabled;
    _email     = widget.prefs.emailEnabled;
    _sms       = widget.prefs.smsEnabled;
    _overrides = Map<String, bool>.from(widget.prefs.eventOverrides);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Channels ──────────────────────────────────────────────────
        Text('Notification Channels',
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: 8),
        Card(
          child: Column(children: [
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('In-app and device notifications'),
              secondary: const Icon(Icons.notifications_rounded),
              value: _push,
              onChanged: (v) => setState(() => _push = v),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Sent to your registered email'),
              secondary: const Icon(Icons.email_rounded),
              value: _email,
              onChanged: (v) => setState(() => _email = v),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('SMS Notifications'),
              subtitle: const Text('Text messages to your phone'),
              secondary: const Icon(Icons.sms_rounded),
              value: _sms,
              onChanged: (v) => setState(() => _sms = v),
            ),
          ]),
        ),

        const SizedBox(height: 24),

        // ── Per-event overrides ────────────────────────────────────────
        Text('Event-level Overrides',
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: 4),
        Text('Fine-tune which events send push notifications.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline)),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: _eventTypes.entries.map((entry) {
              final enabled = _overrides[entry.key] ?? true;
              return SwitchListTile(
                title: Text(entry.value),
                value: enabled,
                onChanged: _push
                    ? (v) => setState(() => _overrides[entry.key] = v)
                    : null,
                dense: true,
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 32),

        // ── Save ──────────────────────────────────────────────────────
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_rounded),
          label: const Text('Save Preferences'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    // eventOverrides: false means disabled; true means enabled
    // Backend expects false = suppressed, so we invert for storage
    final overridesForApi = Map.fromEntries(
      _eventTypes.keys.map((k) => MapEntry(k, _overrides[k] ?? true)),
    );

    final updated = NotificationPreferencesEntity(
      pushEnabled:    _push,
      emailEnabled:   _email,
      smsEnabled:     _sms,
      eventOverrides: overridesForApi,
    );

    final ok = await ref
        .read(notificationPrefsProvider.notifier)
        .update(updated);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Preferences saved' : 'Failed to save'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
