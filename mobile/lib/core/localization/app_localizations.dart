import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

import 'l10n/messages_en.dart';
import 'l10n/messages_hi.dart';
import 'l10n/messages_mr.dart';

/// Provides localised strings throughout the app.
///
/// Usage:
/// ```dart
/// final l10n = AppLocalizations.of(context)!;
/// Text(l10n.appName);
/// ```
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
  ];

  late final Map<String, String> _strings = _loadStrings();

  Map<String, String> _loadStrings() => switch (locale.languageCode) {
        'hi' => hindiMessages,
        'mr' => marathiMessages,
        _    => englishMessages,
      };

  // ── Accessor ───────────────────────────────────────────────────────

  String _t(String key) => _strings[key] ?? key;

  // ── App-wide ───────────────────────────────────────────────────────
  String get appName          => _t('appName');
  String get ok               => _t('ok');
  String get cancel           => _t('cancel');
  String get save             => _t('save');
  String get submit           => _t('submit');
  String get retry            => _t('retry');
  String get loading          => _t('loading');
  String get error            => _t('error');
  String get success          => _t('success');
  String get noInternetTitle  => _t('noInternetTitle');
  String get noInternetBody   => _t('noInternetBody');

  // ── Auth ───────────────────────────────────────────────────────────
  String get login            => _t('login');
  String get logout           => _t('logout');
  String get register         => _t('register');
  String get email            => _t('email');
  String get password         => _t('password');
  String get forgotPassword   => _t('forgotPassword');
  String get otpSent          => _t('otpSent');
  String get verifyOtp        => _t('verifyOtp');
  String get resendOtp        => _t('resendOtp');

  // ── Issues ─────────────────────────────────────────────────────────
  String get reportIssue      => _t('reportIssue');
  String get issueTitle       => _t('issueTitle');
  String get issueDescription => _t('issueDescription');
  String get issueLocation    => _t('issueLocation');
  String get issueStatus      => _t('issueStatus');
  String get issuePriority    => _t('issuePriority');
  String get myIssues         => _t('myIssues');
  String get nearbyIssues     => _t('nearbyIssues');

  // ── Notifications ──────────────────────────────────────────────────
  String get notifications    => _t('notifications');
  String get markAllRead      => _t('markAllRead');
  String get noNotifications  => _t('noNotifications');

  // ── Profile ────────────────────────────────────────────────────────
  String get profile          => _t('profile');
  String get editProfile      => _t('editProfile');
  String get settings         => _t('settings');
  String get darkMode         => _t('darkMode');
  String get language         => _t('language');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales
          .any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    Intl.defaultLocale = locale.languageCode;
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
