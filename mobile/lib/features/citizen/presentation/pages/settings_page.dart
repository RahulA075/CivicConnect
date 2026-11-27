import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../../core/di/providers.dart';
import '../../../../../core/storage/local_storage.dart';
import '../../../../../core/constants/storage_keys.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _pushEnabled  = true;
  bool _emailEnabled = true;

  @override
  void initState() {
    super.initState();
    _pushEnabled  = LocalStorage.getBool(StorageKeys.pushEnabled)  ?? true;
    _emailEnabled = LocalStorage.getBool(StorageKeys.emailEnabled) ?? true;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Appearance ────────────────────────────────────────────
          _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title:   const Text('Dark Mode'),
            trailing: DropdownButton<ThemeMode>(
              value:       themeMode,
              underline:   const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(8),
              items: const [
                DropdownMenuItem(
                    value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(
                    value: ThemeMode.light,  child: Text('Light')),
                DropdownMenuItem(
                    value: ThemeMode.dark,   child: Text('Dark')),
              ],
              onChanged: (mode) {
                if (mode == null) return;
                switch (mode) {
                  case ThemeMode.light:
                    ref.read(themeModeProvider.notifier).setLight();
                  case ThemeMode.dark:
                    ref.read(themeModeProvider.notifier).setDark();
                  case ThemeMode.system:
                    ref.read(themeModeProvider.notifier).setSystem();
                }
              },
            ),
          ),

          const Divider(height: 1),

          // ── Notifications ─────────────────────────────────────────
          _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title:    const Text('Push Notifications'),
            subtitle: const Text('Receive updates on your reports'),
            value:    _pushEnabled,
            onChanged: (v) {
              setState(() => _pushEnabled = v);
              LocalStorage.setBool(StorageKeys.pushEnabled, v);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.email_outlined),
            title:    const Text('Email Notifications'),
            subtitle: const Text('Get email updates on status changes'),
            value:    _emailEnabled,
            onChanged: (v) {
              setState(() => _emailEnabled = v);
              LocalStorage.setBool(StorageKeys.emailEnabled, v);
            },
          ),

          const Divider(height: 1),

          // ── Language ──────────────────────────────────────────────
          _SectionHeader(title: 'Language'),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title:   const Text('App Language'),
            trailing: const Text('English'),
            onTap:   () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Multi-language support coming soon')),
            ),
          ),

          const Divider(height: 1),

          // ── Data ─────────────────────────────────────────────────
          _SectionHeader(title: 'Data & Privacy'),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title:   const Text('Clear Cache'),
            onTap:   () async {
              await LocalStorage.clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cache cleared')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title:   const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap:   () {},
          ),

          const Divider(height: 1),

          // ── About ─────────────────────────────────────────────────
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title:   const Text('App Version'),
            trailing: const Text('1.0.0',
                style: TextStyle(color: Colors.grey)),
          ),
          const Gap(24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color:      Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8),
        ),
      );
}
