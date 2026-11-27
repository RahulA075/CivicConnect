import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../../../core/di/providers.dart';

// ── State ─────────────────────────────────────────────────────────────────────

sealed class OtpState { const OtpState(); }
final class OtpIdle    extends OtpState { const OtpIdle(); }
final class OtpLoading extends OtpState { const OtpLoading(); }
final class OtpSuccess extends OtpState { const OtpSuccess(); }
final class OtpError   extends OtpState {
  const OtpError(this.message);
  final String message;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class OtpNotifier extends StateNotifier<OtpState> {
  OtpNotifier(this._repository) : super(const OtpIdle());

  final AuthRepository _repository;

  Future<bool> verifyOtp({
    required String email,
    required String otp,
    required String purpose,
  }) async {
    state = const OtpLoading();
    final result = await _repository.verifyOtp(email: email, otp: otp);
    return result.fold(
      (failure) {
        state = OtpError(failure.message);
        return false;
      },
      (_) {
        state = const OtpSuccess();
        return true;
      },
    );
  }

  Future<void> resendOtp({
    required String email,
    required String purpose,
  }) async {
    state = const OtpLoading();
    final result = await _repository.forgotPassword(email);
    result.fold(
      (failure) => state = OtpError(failure.message),
      (_)       => state = const OtpIdle(),
    );
  }

  void reset() => state = const OtpIdle();
}

// ── Provider ──────────────────────────────────────────────────────────────────

final otpNotifierProvider =
    StateNotifierProvider.autoDispose<OtpNotifier, OtpState>(
  (ref) => OtpNotifier(ref.watch(authRepositoryProvider)),
);
