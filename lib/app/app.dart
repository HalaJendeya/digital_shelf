import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';
import '../design_system/design_system.dart';
import '../features/authentication/application/auth_controller.dart';
import '../features/store/data/store_repository.dart';
import 'l10n/app_strings.dart';
import 'router/app_router.dart';

class DigitalShelfApp extends ConsumerWidget {
  const DigitalShelfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final store = ref.watch(storeProvider).value;
    final messengerKey = ref.watch(scaffoldMessengerKeyProvider);

    // Tell the customer when the server ends their session (401), rather than
    // silently dropping them to guest mode.
    ref.listen(authControllerProvider.select((a) => a.sessionExpired), (_, expired) {
      if (expired) {
        messengerKey.currentState?.showSnackBar(
          SnackBar(content: Text(AppStrings(ref.read(localeProvider).languageCode).sessionExpired)),
        );
      }
    });

    return MaterialApp.router(
      title: store?.name ?? 'Digital Shelf',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      routerConfig: ref.watch(routerProvider),
      locale: locale,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: ref.watch(themeModeProvider),
      theme: buildAppTheme(brightness: Brightness.light),
      darkTheme: buildAppTheme(brightness: Brightness.dark),
    );
  }
}
