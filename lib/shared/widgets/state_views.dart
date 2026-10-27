import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_strings.dart';
import '../../design_system/design_system.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Padding(padding: EdgeInsets.all(Gap.xl), child: CircularProgressIndicator()));
}

class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Gap.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: IconSizes.message, color: theme.colorScheme.primary.withValues(alpha: AppOpacity.strong)),
            const SizedBox(height: Gap.lg),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            if (body != null) ...[
              const SizedBox(height: Gap.sm),
              Text(
                body!,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: Gap.xl),
              FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return MessageView(
      icon: Icons.cloud_off_rounded,
      title: s.errorMessage(error),
      actionLabel: onRetry == null ? null : s.retry,
      onAction: onRetry,
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => MessageView(icon: icon, title: message);
}

/// Renders loading / error / data for an [AsyncValue]. While refreshing with
/// existing data the data stays visible (no flashing spinners).
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({super.key, required this.value, required this.data, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue) return data(value.requireValue);
    if (value.hasError) return ErrorView(error: value.error!, onRetry: onRetry);
    return const LoadingView();
  }
}
