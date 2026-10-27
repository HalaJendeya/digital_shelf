import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final (prefs, _) = await (SharedPreferences.getInstance(), initializeDateFormatting()).wait;
  runApp(
    ProviderScope(
      // Network retries are handled by Dio for idempotent requests only;
      // providers must not silently re-run mutations or failed loads.
      retry: (_, _) => null,
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const DigitalShelfApp(),
    ),
  );
}
