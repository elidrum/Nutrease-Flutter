import 'package:flutter/material.dart';

/// Design token riutilizzabili (spaziature, raggi, elevazione).
///
/// Le schermate leggono le dimensioni da qui e i colori da
/// `Theme.of(context).colorScheme` — mai valori hardcoded.
abstract final class AppTokens {
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;

  static const double elevationCard = 1;

  /// Verde chiaro dell'app-bar / brand (usato anche per tingere le chip selezionate).
  static const Color appBarColor = Color.fromARGB(255, 199, 239, 185);

  // Dimensioni delle icone.
  static const double iconSm = 20; // icone inline (es. la data del diario)
  static const double iconMd = 28; // icone leading + chevron sulle card della home
  static const double iconCircle = 52; // contenitore circolare dell'icona sulle card della home

  // Altezza minima del contenuto di una card azione della home: così i
  // sottotitoli su 1 o 2 righe danno card della stessa altezza (può comunque
  // crescere a scale di testo grandi).
  static const double homeCardMinHeight = 80;

  static const double fabSize = 72; // FAB del diario, tra le misure M3 da 56 e 96
  static const double buttonHeight = 56; // CTA primarie (FilledButton)

  // Menu "aggiungi voce" del diario: una larghezza fissa permette di centrarlo
  // sopra il FAB, con righe più alte del default per un popup più arioso.
  static const double menuWidth = 240;
  static const double menuItemHeight = 56;

  // Inset finale per allineare i glifi delle azioni dell'app-bar al contenuto del
  // body ([spacingLg]): un'icona da 24px sta 12px dentro il suo IconButton da
  // 48px, quindi il padding necessario è spacingLg - 12 = 12.
  static const double appBarActionInset = 12;

  // Dimensioni tipografiche (px), tarate in design review e centralizzate per
  // coerenza tra le schermate. Applicate via copyWith sugli stili di testo
  // Material; tenute fuori dal TextTheme globale di proposito, così le schermate
  // che non le adottano mantengono la scala Material di default.
  static const double fontAppBarTitle = 22; // titoli app-bar di default (theme)
  static const double fontHomeAppBarTitle = 26; // la Home tiene il titolo più grande
  static const double fontDisplay = 34; // saluto / testo hero
  static const double fontTitle = 21; // titoli di sezione, card e date
  static const double fontSubtitle = 18; // header secondari, testo degli empty state
  static const double fontBody = 16; // corpo card / testo di supporto
}

/// Tema Material 3 costruito da un unico seed color.
abstract final class AppTheme {
  /// Seed verde che richiama nutrizione/salute.
  static const Color _seedColor = Color(0xFF2E7D32);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );
    // Raggio degli angoli "large" condiviso tra bottoni e campi di input.
    final lgRadius = BorderRadius.circular(AppTokens.radiusLg);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.appBarColor,
        foregroundColor: Colors.black, // il testo scuro si legge bene sul verde chiaro
        elevation: 0,
        centerTitle: true, // la Home lo sovrascrive a false (HomeScaffold).
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: AppTokens.fontAppBarTitle,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: AppTokens.elevationCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppTokens.buttonHeight),
          textStyle: const TextStyle(
            fontSize: AppTokens.fontSubtitle,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: lgRadius),
        ),
      ),

      // Campi/selettori arrotondati (stesso raggio dei bottoni), mantenendo i
      // colori di stato M3. I bordi specifici per stato vincono sul `border`
      // semplice del campo, quindi questo arrotonda ogni
      // TextField/DropdownButtonFormField in tutta l'app.
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: lgRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: lgRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: lgRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: lgRadius,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: lgRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: lgRadius,
          borderSide:
              BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.12)),
        ),
      ),
    );
  }
}
