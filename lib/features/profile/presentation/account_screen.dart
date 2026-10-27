import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../design_system/design_system.dart';
import '../../../core/providers.dart';
import '../../../shared/widgets/common.dart';
import '../../authentication/application/auth_controller.dart';
import '../../store/data/store_repository.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final store = ref.watch(storeProvider).value;
    final locale = ref.watch(localeProvider);
    final customer = auth.customer;

    return Scaffold(
      appBar: AppBar(title: Text(s.account)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(authControllerProvider.notifier).refreshProfile().catchError((_) {}),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(Gap.lg),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Gap.lg),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: AvatarSizes.lg,
                      child: auth.isAuthenticated
                          ? Text(customer?.initials ?? '…', style: theme.textTheme.titleMedium)
                          : const Icon(Icons.person_outline_rounded),
                    ),
                    const SizedBox(width: Gap.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.isAuthenticated ? (customer?.name ?? '') : s.guest,
                            style: context.textStyles.sectionTitle,
                          ),
                          if (customer?.email != null) Text(customer!.email!, style: theme.textTheme.bodySmall),
                          if (customer?.phone != null) Text(customer!.phone!, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    if (auth.isAuthenticated)
                      IconButton(
                        tooltip: s.editProfile,
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => context.push(Routes.editProfile),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Gap.lg),
            if (!auth.isAuthenticated) ...[
              FilledButton(onPressed: () => context.push(Routes.login), child: Text(s.login)),
              const SizedBox(height: Gap.sm),
              OutlinedButton(onPressed: () => context.push(Routes.register), child: Text(s.register)),
              const SizedBox(height: Gap.lg),
            ],
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(s.orders),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.orders),
                  ),
                  ListTile(
                    leading: const Icon(Icons.favorite_border_rounded),
                    title: Text(s.favorites),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.favorites),
                  ),
                  ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: Text(s.language),
                    trailing: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: 'ar', label: Text(s.arabic)),
                        ButtonSegment(value: 'en', label: Text(s.english)),
                      ],
                      selected: {locale.languageCode},
                      onSelectionChanged: (v) => ref.read(localeProvider.notifier).setLocale(Locale(v.first)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Gap.lg),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: Text(s.appearance),
                    trailing: SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          tooltip: s.themeSystem,
                          icon: const Icon(Icons.brightness_auto_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          tooltip: s.themeLight,
                          icon: const Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          tooltip: s.themeDark,
                          icon: const Icon(Icons.dark_mode_outlined),
                        ),
                      ],
                      selected: {ref.watch(themeModeProvider)},
                      onSelectionChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v.first),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.storefront_outlined),
                    title: Text(s.aboutStore),
                    subtitle: store == null ? null : Text(store.name),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.about),
                  ),
                ],
              ),
            ),
            if (auth.isAuthenticated) ...[
              const SizedBox(height: Gap.lg),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                icon: const Icon(Icons.logout_rounded),
                label: Text(s.logout),
                onPressed: () async {
                  if (await confirmDialog(context, s.logoutConfirm)) {
                    await ref.read(authControllerProvider.notifier).logout();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
