import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_storage.dart';

/// Persists and exposes the current [ThemeMode].
/// Reads from Hive on startup; writes on every change.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final stored = LocalStorage.getString(_key);
    return _fromString(stored);
  }

  void setLight()  => _update(ThemeMode.light);
  void setDark()   => _update(ThemeMode.dark);
  void setSystem() => _update(ThemeMode.system);

  void toggle() {
    _update(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  void _update(ThemeMode mode) {
    LocalStorage.setString(_key, mode.name);
    state = mode;
  }

  ThemeMode _fromString(String? value) => switch (value) {
    'light'  => ThemeMode.light,
    'dark'   => ThemeMode.dark,
    _        => ThemeMode.system,
  };
}

/// Riverpod provider for [ThemeModeNotifier].
final themeModeNotifierProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
