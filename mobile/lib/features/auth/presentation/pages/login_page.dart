import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../../../../core/di/providers.dart';
import '../widgets/auth_header.dart';
import '../widgets/social_login_button.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final notifier = ref.read(authNotifierProvider.notifier);
    final success  = await notifier.login(
      email:    _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );
    if (success && mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState is AuthLoading;
    final error     = authState is AuthError ? authState.failure.message : null;

    // (No auto-clear here — errors are cleared when user edits fields, see AppTextField onChanged)

    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Gap(24),
                const AuthHeader(
                  title: 'Welcome back',
                  subtitle: 'Log in to CivicConnect',
                ),
                const Gap(40),

                // ── Error banner ──────────────────────────────────
                if (error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: theme.colorScheme.error, size: 20),
                        const Gap(8),
                        Expanded(
                          child: Text(error,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onErrorContainer)),
                        ),
                      ],
                    ),
                  ),
                  const Gap(16),
                ],

                // ── Fields ────────────────────────────────────────
                AppTextField(
                  controller: _emailCtrl,
                  label: 'Email or Phone',
                  hint: 'Enter your email or phone',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (v) => Validators.required(v, label: 'Email or Phone'),
                  onChanged: (_) {
                    if (ref.read(authNotifierProvider) is AuthError) {
                      ref.read(authNotifierProvider.notifier).clearError();
                    }
                  },
                ),
                const Gap(16),
                AppTextField(
                  controller: _passCtrl,
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  prefixIcon: const Icon(Icons.lock_outline),
                  onSubmitted: (_) => _submit(),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Password is required' : null,
                  onChanged: (_) {
                    if (ref.read(authNotifierProvider) is AuthError) {
                      ref.read(authNotifierProvider.notifier).clearError();
                    }
                  },
                ),
                const Gap(8),

                // ── Forgot password ───────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(Routes.forgotPassword),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const Gap(24),

                // ── Login button ──────────────────────────────────
                AppButton(
                  label: 'Log In',
                  onPressed: _submit,
                  isLoading: isLoading,
                ),
                const Gap(16),

                // ── Divider ───────────────────────────────────────
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  const Expanded(child: Divider()),
                ]),
                const Gap(16),

                // ── Google button ─────────────────────────────────
                GoogleLoginButton(
                  isLoading: false,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Google Sign-In requires Firebase configuration')),
                    );
                  },
                ),
                const Gap(32),

                // ── Register link ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?",
                        style: theme.textTheme.bodyMedium),
                    TextButton(
                      onPressed: () => context.push(Routes.register),
                      child: const Text('Sign Up'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
