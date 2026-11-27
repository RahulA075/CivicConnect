import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/otp_provider.dart';
import '../widgets/auth_header.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  bool  _sent       = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final result = await ref
        .read(authRepositoryProvider)
        .forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {
        setState(() => _sent = true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final otpState  = ref.watch(otpNotifierProvider);
    final isLoading = otpState is OtpLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: _sent ? _SentState(
            email: _emailCtrl.text.trim(),
            onVerify: () => context.push(Routes.verifyOtp,
                extra: {
                  'email':   _emailCtrl.text.trim(),
                  'purpose': 'PASSWORD_RESET',
                }),
          ) : Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(
                  title: 'Reset Password',
                  subtitle:
                      "Enter your email and we'll send\nan OTP to reset your password.",
                ),
                const Gap(40),
                AppTextField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'your@email.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: Validators.email,
                ),
                const Gap(28),
                AppButton(
                  label: 'Send OTP',
                  onPressed: _submit,
                  isLoading: isLoading,
                ),
                const Gap(16),
                Center(
                  child: TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back to Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SentState extends StatelessWidget {
  const _SentState({required this.email, required this.onVerify});
  final String        email;
  final VoidCallback  onVerify;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Gap(16),
        Icon(Icons.mark_email_read_outlined,
            size: 80, color: theme.colorScheme.primary),
        const Gap(24),
        Text('OTP Sent!',
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center),
        const Gap(12),
        Text(
          'Check your inbox at\n$email\nand enter the OTP to reset your password.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const Gap(40),
        FilledButton(
          onPressed: onVerify,
          child: const Text('Enter OTP'),
        ),
      ],
    );
  }
}
