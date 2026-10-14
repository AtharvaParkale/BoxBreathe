import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ease_button.dart';
import '../../../../core/widgets/lists.dart';
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
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Semantics(
      label: 'Loading account',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          'Checking your account…',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }

  Widget _buildAnonymous(BuildContext context, AuthState state) {
    final theme = Theme.of(context).textTheme;
    final hasError =
        state.status == AuthStatus.error && state.errorMessage != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Keep your practice', style: theme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Sign in to keep your history and streak across devices. '
          'Everything works without an account.',
          style: theme.bodyMedium,
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.only(left: AppSpacing.md),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.white)),
              ),
              child: Text(state.errorMessage!, style: theme.bodyLarge),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        EaseButton.primary(
          label: 'Continue with Google',
          onTap: () => context.read<AuthBloc>().add(GoogleSignInRequested()),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: AppSpacing.lg),
          const _EmailPasswordDebugForm(),
        ],
      ],
    );
  }

  Widget _buildSignedIn(BuildContext context, AuthState state) {
    final theme = Theme.of(context).textTheme;
    final user = state.user!;
    final initial = (user.displayName?.isNotEmpty ?? false)
        ? user.displayName![0].toUpperCase()
        : (user.email?.isNotEmpty ?? false)
        ? user.email![0].toUpperCase()
        : '?';

    return HairlineList(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 44,
                  height: 44,
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: user.photoUrl != null
                      ? ColorFiltered(
                          // Keep the avatar inside the monochrome palette.
                          colorFilter: const ColorFilter.matrix([
                            0.2126, 0.7152, 0.0722, 0, 0, //
                            0.2126, 0.7152, 0.0722, 0, 0, //
                            0.2126, 0.7152, 0.0722, 0, 0, //
                            0, 0, 0, 1, 0,
                          ]),
                          child: Image.network(
                            user.photoUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                Text(initial, style: theme.headlineSmall),
                          ),
                        )
                      : Text(initial, style: theme.headlineSmall),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? user.email ?? 'Signed in',
                      style: theme.bodyLarge,
                    ),
                    if (user.email != null && user.displayName != null)
                      Text(user.email!, style: theme.bodyMedium),
                    Text('Synced across devices', style: theme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        ListRow(
          title: 'Sign out',
          showChevron: false,
          onTap: () => _confirmSignOut(context),
        ),
        ListRow(
          title: 'Delete account',
          titleStyle: theme.bodyLarge?.copyWith(color: AppColors.secondary),
          showChevron: false,
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
    final bloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'Your account and synced history will be permanently deleted. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete permanently',
              style: TextStyle(fontWeight: FontWeight.w600),
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
          style: theme.textTheme.labelSmall,
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
