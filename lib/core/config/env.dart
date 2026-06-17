/// Configurazione dell'app: URL Supabase + publishable key.
///
/// I valori sono iniettati a build time via `--dart-define`, di solito da un
/// `env.json` gitignorato: `flutter run --dart-define-from-file=env.json`.
///
/// Qui non si committa nulla: senza i define le stringhe restano vuote e
/// [isConfigured] è `false`, così `main()` mostra un errore di configurazione
/// esplicito invece di crashare.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Vero solo se entrambi i valori Supabase sono stati forniti.
  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
