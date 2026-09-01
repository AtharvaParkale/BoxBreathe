import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_containers.dart';
import '../../../../core/widgets/premium_controls.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// The Settings-page ACCOUNT block: sign-in prompt while anonymous, account
/// info + sign-out/delete while signed in. Placed as the first section on
/// the Settings page, above PREFERENCES.
class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final Widget content;
        switch (state.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            content = _buildLoading(context);
          case AuthStatus.signedIn:
            content = _buildSignedIn(context, state);
          case AuthStatus.anonymous:
          case AuthStatus.error:
            content = _buildAnonymous(context, state);
        }
        if (!kDebugMode) return content;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [content, _buildDebugFooter(context, state)],
        );
      },
    );
  }

  /// Dev-only readout (stripped from release builds via [kDebugMode]) so
  /// the raw Firebase uid/provider/status can be eyeballed against the
  /// Firestore console while testing sign-in/link/sign-out/delete flows.
  Widget _buildDebugFooter(BuildContext context, AuthState state) {
    final theme = Theme.of(context);
    final user = state.user;
    final text = user == null
        ? 'debug: status=${state.status.name}'
        : 'debug: status=${state.status.name} uid=${user.uid} '
              'provider=${user.provider.name}${state.errorMessage != null ? ' error=${state.errorMessage}' : ''}';
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.sm2),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return AppGroupContainer(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm2),
              Text(
                'Loading account…',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnonymous(BuildContext context, AuthState state) {
    final theme = Theme.of(context);
    return AppGroupContainer(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Save your progress', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                state.status == AuthStatus.error && state.errorMessage != null
                    ? state.errorMessage!
                    : 'Keep your breathing history across devices',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: state.status == AuthStatus.error
                      ? theme.colorScheme.error
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PremiumScaleButton(
                onTap: () =>
                    context.read<AuthBloc>().add(GoogleSignInRequested()),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Continue with Google',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: AppSpacing.md),
                const _EmailPasswordDebugForm(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignedIn(BuildContext context, AuthState state) {
    final theme = Theme.of(context);
    final user = state.user!;
    final initial = (user.displayName?.isNotEmpty ?? false)
        ? user.displayName![0].toUpperCase()
        : (user.email?.isNotEmpty ?? false)
        ? user.email![0].toUpperCase()
        : '?';

    return AppGroupContainer(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm2,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.08,
                ),
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Text(initial, style: theme.textTheme.titleMedium)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.displayName ?? user.email ?? 'Signed in',
                      style: theme.textTheme.titleMedium,
                    ),
                    if (user.email != null)
                      Text(user.email!, style: theme.textTheme.bodyMedium),
                    Text(
                      'Synced across devices',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const AppDivider(),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          title: const Text('Sign out'),
          onTap: () => _confirmSignOut(context),
        ),
        const AppDivider(),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          title: Text(
            'Delete account',
            style: TextStyle(color: theme.colorScheme.error),
          ),
          onTap: () => _confirmDeleteAccount(context),
        ),
      ],
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          "You'll return to a guest session. Your synced history stays saved to your account.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(SignOutRequested());
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final theme = Theme.of(context);
    final bloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your account. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Delete',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      bloc.add(DeleteAccountRequested());
    }
  }
}

/// Debug-only email/password entry point so testers don't need a Google
/// account. Gated on [kDebugMode] in [AccountSection] — never appears in a
/// release build, so there's nothing to manually strip before shipping.
class _EmailPasswordDebugForm extends StatefulWidget {
  const _EmailPasswordDebugForm();

  @override
  State<_EmailPasswordDebugForm> createState() =>
      _EmailPasswordDebugFormState();
}

class _EmailPasswordDebugFormState extends State<_EmailPasswordDebugForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(bool isSignUp) {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) return;
    context.read<AuthBloc>().add(
      isSignUp
          ? EmailSignUpRequested(email, password)
          : EmailSignInRequested(email, password),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DEBUG: email/password (removed before release)',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(hintText: 'Email'),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Password'),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _submit(false),
                child: const Text('Sign in'),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _submit(true),
                child: const Text('Sign up'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
