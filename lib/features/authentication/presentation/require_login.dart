import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../shared/widgets/state_views.dart';
import '../application/auth_controller.dart';

/// Returns true when signed in. Otherwise opens the login screen on top of the
/// current page (so the customer returns here afterwards) and returns whether
/// the login succeeded.
Future<bool> ensureSignedIn(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  if (container.read(isAuthenticatedProvider)) return true;
  final result = await context.push<bool>(Routes.login);
  return result == true && container.read(isAuthenticatedProvider);
}

/// Inline placeholder for tabs that need an account (cart, favorites).
class LoginPrompt extends StatelessWidget {
  const LoginPrompt({super.key, this.icon = Icons.lock_outline_rounded});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return MessageView(
      icon: icon,
      title: s.loginRequired,
      body: s.loginRequiredBody,
      actionLabel: s.login,
      onAction: () => context.push(Routes.login),
    );
  }
}
