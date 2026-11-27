import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/otp_provider.dart';
import '../widgets/auth_header.dart';

/// Accepts [GoRouterState.extra] as Map<String, String>:
///   {'email': '...', 'purpose': 'REGISTRATION' | 'PASSWORD_RESET'}
class VerifyOtpPage extends ConsumerStatefulWidget {
  const VerifyOtpPage({super.key, required this.email, required this.purpose});

  final String email;
  final String purpose;

  @override
  ConsumerState<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends ConsumerState<VerifyOtpPage> {
  final _otpCtrl = TextEditingController();
  Timer?  _resendTimer;
  int     _resendCountdown = AppConstants.otpResendSecs;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = AppConstants.otpResendSecs);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown == 0) {
        t.cancel();
      } else {
        setState(() => _resendCountdown--);
      }
    });
  }

  Future<void> _verify() async {
    if (_otpCtrl.text.length != AppConstants.otpLength) return;
    final notifier = ref.read(otpNotifierProvider.notifier);
    final ok = await notifier.verifyOtp(
      email:   widget.email,
      otp:     _otpCtrl.text,
      purpose: widget.purpose,
    );
    if (!mounted) return;
    if (ok) {
      if (widget.purpose == 'REGISTRATION') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verified! Please log in.')),
        );
        context.go(Routes.login);
      } else {
        context.go(Routes.login);
      }
    }
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0) return;
    await ref.read(otpNotifierProvider.notifier).resendOtp(
      email:   widget.email,
      purpose: widget.purpose,
    );
    _startResendTimer();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent to your email.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpState  = ref.watch(otpNotifierProvider);
    final isLoading = otpState is OtpLoading;
    final error     = otpState is OtpError ? otpState.message : null;
    final theme     = Theme.of(context);

    final defaultPinTheme = PinTheme(
      width: 54,
      height: 58,
      textStyle: theme.textTheme.headlineSmall
          ?.copyWith(fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                title: 'Enter OTP',
                subtitle:
                    'A ${AppConstants.otpLength}-digit code was sent to\n${widget.email}',
              ),
              const Gap(40),

              if (error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(error,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer)),
                ),
                const Gap(16),
              ],

              // ── OTP input ─────────────────────────────────────
              Center(
                child: Pinput(
                  controller: _otpCtrl,
                  length: AppConstants.otpLength,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration?.copyWith(
                      border: Border.all(
                        color: theme.colorScheme.primary, width: 2),
                    ),
                  ),
                  errorPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration?.copyWith(
                      border: Border.all(
                        color: theme.colorScheme.error, width: 2),
                    ),
                  ),
                  onCompleted: (_) => _verify(),
                ),
              ),
              const Gap(32),

              AppButton(
                label: 'Verify',
                onPressed: _verify,
                isLoading: isLoading,
              ),
              const Gap(24),

              // ── Resend ────────────────────────────────────────
              Center(
                child: _resendCountdown > 0
                    ? Text(
                        'Resend OTP in ${_resendCountdown}s',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      )
                    : TextButton(
                        onPressed: _resend,
                        child: const Text('Resend OTP'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
