import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/app_scaffold_messenger.dart';
import 'core/config/env.dart';
import 'core/config/supabase_init.dart';
import 'core/di/app_providers.dart';
import 'core/strings/it_strings.dart';
import 'core/theme/app_theme.dart';
import 'presentation/navigation/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!Env.isConfigured) {
    runApp(const _ConfigErrorApp());
    return;
  }

  await initSupabase();
  // Nomi italiani di mesi/giorni per la strip data del diario (DateFormat con it_IT).
  await initializeDateFormatting('it_IT');
  runApp(
    MultiProvider(
      providers: buildAppProviders(),
      child: const NutreaseApp(),
    ),
  );
}

/// Localizzazione solo italiana: forza i widget Material di serie (date/time
/// picker, dialog) in italiano a prescindere dalla lingua del dispositivo. I testi
/// dell'app sono già in italiano via [ItStrings].
const List<LocalizationsDelegate<dynamic>> _localizationsDelegates = [
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];
const List<Locale> _supportedLocales = [Locale('it')];
const Locale _appLocale = Locale('it');

/// Widget radice dell'app. Tiene una singola istanza di router per tutta la vita
/// dell'app.
class NutreaseApp extends StatefulWidget {
  const NutreaseApp({super.key});

  @override
  State<NutreaseApp> createState() => _NutreaseAppState();
}

class _NutreaseAppState extends State<NutreaseApp> {
  // Costruito una volta sola, dopo l'init di Supabase.
  late final _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: ItStrings.appTitle,
      theme: AppTheme.light,
      routerConfig: _router,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      locale: _appLocale,
      localizationsDelegates: _localizationsDelegates,
      supportedLocales: _supportedLocales,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Mostrato quando i secret Supabase non sono stati forniti via `--dart-define`.
class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: ItStrings.appTitle,
      theme: AppTheme.light,
      locale: _appLocale,
      localizationsDelegates: _localizationsDelegates,
      supportedLocales: _supportedLocales,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spacingLg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.settings_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                  semanticLabel: ItStrings.configIconLabel,
                ),
                const SizedBox(height: AppTokens.spacingMd),
                Text(
                  ItStrings.configErrorTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.spacingSm),
                Text(
                  ItStrings.configErrorBody,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
