import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Runtime environment configuration.
/// Instantiated once per app flavour and injected via Riverpod.
class AppConfig {
  final String baseUrl;
  final String googleMapsApiKey;
  final String flavor;
  final bool enableLogging;

  const AppConfig({
    required this.baseUrl,
    required this.googleMapsApiKey,
    required this.flavor,
    this.enableLogging = false,
  });

  bool get isDev => flavor == 'dev';
  bool get isStaging => flavor == 'staging';
  bool get isProd => flavor == 'prod';

  /// Development configuration — auto-discovers the backend at runtime.
  ///
  /// Scans every host in the phone's /24 subnet and returns the first one
  /// that responds on port 8080. Works for USB tethering, WiFi, and emulator.
  static Future<AppConfig> devAsync() async {
    // Hardcoded PC Wi-Fi IP for direct phone ↔ backend connection.
    // Update this when the PC IP changes (check: Get-NetIPAddress -AddressFamily IPv4).
    const hardcodedHost = '192.168.53.105';
    // ignore: avoid_print
    print('[AppConfig] ✅ Backend resolved (hardcoded): http://$hardcodedHost:8080');
    return AppConfig(
      baseUrl: 'http://$hardcodedHost:8080',
      googleMapsApiKey: 'YOUR_DEV_MAPS_API_KEY',
      flavor: 'dev',
      enableLogging: true,
    );
  }

  factory AppConfig.dev() => const AppConfig(
        baseUrl: 'http://10.0.2.2:8080',
        googleMapsApiKey: 'YOUR_DEV_MAPS_API_KEY',
        flavor: 'dev',
        enableLogging: true,
      );

  factory AppConfig.staging() => const AppConfig(
        baseUrl: 'https://api-staging.civicconnect.in',
        googleMapsApiKey: 'YOUR_STAGING_MAPS_API_KEY',
        flavor: 'staging',
        enableLogging: true,
      );

  factory AppConfig.prod() => const AppConfig(
        baseUrl: 'https://api.civicconnect.in',
        googleMapsApiKey: 'YOUR_PROD_MAPS_API_KEY',
        flavor: 'prod',
        enableLogging: false,
      );

  // ── Backend discovery ───────────────────────────────────────────────────────

  static Future<String> _discoverBackendHost() async {
    final candidates = <String>[];

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLinkLocal: false,
        );
        for (final iface in interfaces) {
          for (final addr in iface.addresses) {
            final parts = addr.address.split('.');
            if (parts.length != 4) continue;
            final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
            // Scan the full /24 subnet
            for (int last = 1; last <= 254; last++) {
              final candidate = '$prefix.$last';
              if (candidate != addr.address) {
                candidates.add(candidate);
              }
            }
          }
        }
      } catch (_) {}
    }

    // Emulator alias as final fallback
    candidates.add('10.0.2.2');

    // ignore: avoid_print
    print('[AppConfig] Scanning ${candidates.length} candidates...');

    final completer = Completer<String>();
    var remaining = candidates.length;

    for (final host in candidates) {
      _probeHost(host).then((alive) {
        if (alive && !completer.isCompleted) {
          completer.complete(host);
        }
        remaining--;
        if (remaining == 0 && !completer.isCompleted) {
          completer.complete('10.0.2.2');
        }
      });
    }

    // Wait up to 10 seconds — /24 parallel scan is fast but networks vary
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        // ignore: avoid_print
        print('[AppConfig] Discovery timed out — using emulator fallback');
        return '10.0.2.2';
      },
    );
  }

  /// Probe host:8080/actuator/health with a 3s timeout.
  /// Accepts 200 (healthy) or 503 (app up, dependency down).
  static Future<bool> _probeHost(String host) async {
    try {
      final response = await http
          .get(Uri.parse('http://$host:8080/actuator/health'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200 || response.statusCode == 503;
    } catch (_) {
      return false;
    }
  }
}
