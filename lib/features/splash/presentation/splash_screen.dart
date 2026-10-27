import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/state_views.dart';
import '../../store/data/store_repository.dart';
import '../application/bootstrap_provider.dart';

/// Shows store branding while the bootstrap runs; the router leaves this
/// screen automatically once [bootstrapProvider] completes.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final bootstrap = ref.watch(bootstrapProvider);
    final store = ref.watch(storeProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: bootstrap.hasError && !bootstrap.isLoading
              ? ErrorView(
                  error: bootstrap.error!,
                  onRetry: () {
                    ref.invalidate(storeProvider);
                    ref.invalidate(bootstrapProvider);
                  },
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.lg),
                      child: SizedBox.square(
                        dimension: AppSizes.logoLg,
                        child: AppNetworkImage(url: store?.logo, fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(height: Gap.lg),
                    Text(
                      store?.name ?? '',
                      style: context.textStyles.pageTitle,
                    ),
                    const SizedBox(height: Gap.xl),
                    const AppSpinner(size: SpinnerSize.large),
                    const SizedBox(height: Gap.md),
                    Text(s.connecting, style: theme.textTheme.bodySmall),
                  ],
                ),
        ),
      ),
    );
  }
}
