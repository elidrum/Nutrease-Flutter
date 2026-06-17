# Setup — Nutrease Flutter

> Procedura per portare un clone fresco a una build che parla con Supabase.
> Il backend è quello dell'app Android sorella (https://github.com/elidrum/Nutrease): stesso
> progetto Supabase, stesso schema, stesse RLS. Il porting non li modifica.
> Se trovi un errore non documentato, aggiungilo alla sezione Troubleshooting.

---

## 1. Prerequisiti

| Tool | Versione | Verifica |
|---|---|---|
| Flutter SDK | canale `stable` | `flutter --version` |
| Dart | `^3.12` (incluso in Flutter) | `dart --version` |
| Android Studio | recente, con plugin Flutter e Dart | Settings → Plugins |
| Git | recente | `git --version` |

Serve inoltre un progetto Supabase popolato con `../Nutrease/sql/nutreaseDatabase.sql` e il
dataset `../Nutrease/sql/alimento_seed.sql` (sanity-check `count>=1388`). Verifica l'ambiente
con `flutter doctor`.

## 2. Clone + prima apertura

```bash
git clone <url-repo> nutrease-flutter && cd nutrease-flutter
flutter pub get
```
Apri in Android Studio e scegli Trust Project. Senza i segreti Supabase l'app non crasha:
mostra una schermata che spiega come configurarli (vedi §6).

## 3. Credenziali Supabase

Su [app.supabase.com](https://app.supabase.com), progetto Nutrease, Project Settings → API:
copia il **Project URL** (`https://xxx.supabase.co`) e la chiave **anon public** (oppure
`sb_publishable_...`). È la chiave pubblica, sicura da tenere in app.

Non usare mai `service_role` o `sb_secret_...`: sono chiavi admin che bypassano le RLS, solo
per il backend.

I segreti si passano via `--dart-define`, tipicamente da un `env.json` gitignored generato dal
template:
```bash
cp env.json.template env.json
```
```json
// env.json
{
  "SUPABASE_URL": "https://xxxxxxxxxxxxx.supabase.co",
  "SUPABASE_ANON_KEY": "sb_publishable_..."
}
```
Avvio:
```bash
flutter run --dart-define-from-file=env.json
```
In Android Studio: nella run configuration, campo *Additional run args* →
`--dart-define-from-file=env.json`. `env.json` è gitignored; in git c'è solo
`env.json.template` con i placeholder (vedi `core/config/env.dart`, ADR — i valori sono letti
con `String.fromEnvironment`).

## 4. Dipendenze

Definite in `pubspec.yaml`, installate con `flutter pub get`. Le principali a runtime:
- `supabase_flutter` (Auth + Postgrest)
- `provider` (DI + stato, ADR-0004/FL-2)
- `go_router` (routing auth-gated, ADR-FL-3)
- `intl` + `flutter_localizations` (date e widget Material in italiano, ADR-0005/0011)
- `sqflite` + `path` (cache offline del diario, ADR-FL-1)

Sviluppo/test: `flutter_lints`, `mocktail`, `http` (per testare i Repository contro le shape
PostgREST reali), `sqflite_common_ffi` (DB in-memory per testare il DAO off-device).

## 5. Composition root (`provider`)

Niente generatore di DI: le dipendenze condivise sono registrate in
`core/di/app_providers.dart` e montate in `main()`:
```dart
runApp(
  MultiProvider(
    providers: buildAppProviders(), // SupabaseClient + Repository + UseCase singleton
    child: const NutreaseApp(),
  ),
);
```
`main()` inizializza Supabase (`initSupabase()`) e la formattazione delle date `it_IT` **prima**
di `runApp`; i ViewModel sono creati per-schermata con `ChangeNotifierProvider`.

## 6. Smoke test al primo launch

```bash
flutter run --dart-define-from-file=env.json
```
- Con i segreti validi: parte la schermata di splash, poi login.
- Senza segreti: parte la schermata di configurazione (nessun crash) — è il check che `Env.isConfigured` funziona.

Verifica della connessione al DB: fai login con un account di test e apri la ricerca alimenti
(il dataset viene scaricato e messo in cache).

## 7. Troubleshooting

| Sintomo | Causa | Fix |
|---|---|---|
| Parte la schermata "Configura i segreti" | `--dart-define` mancanti | avvia con `--dart-define-from-file=env.json` |
| `flutter analyze` segnala errori di lint | regole di `analysis_options.yaml` | correggi; un build pulito è 0 issue |
| `permission denied for table xxx` | RLS nega | sei loggato? il ruolo corrisponde alla policy? |
| `AuthApiException` al login | credenziali errate | l'app mostra un errore generico (anti-enumeration, ADR-0024) |
| Lista alimenti vuota / lenta al primo uso | primo fetch del dataset (1.388 righe) | atteso: paginazione + parsing in isolate, poi è in cache |
| Date/picker in inglese | locale non forzato | verifica `flutter_localizations` e `locale: Locale('it')` |

## 8. Pre-flight checklist

- [ ] `flutter pub get` completa senza errori
- [ ] `flutter analyze` → 0 issue
- [ ] `flutter test` → verde
- [ ] `git status` non traccia `env.json`
- [ ] `flutter run --dart-define-from-file=env.json` avvia l'app e fa login

## 9. Approvazione specialisti (ADR-0028)

Uno specialista appena registrato parte non verificato (`specialista."Verificato" = false`):
non è visibile ai pazienti nella discovery e non può accettare richieste finché un admin non lo
approva. Non esiste una UI admin, quindi l'approvazione si fa dall'SQL editor di Supabase
(stesso backend dell'app Android):
```sql
UPDATE specialista SET "Verificato" = true WHERE "CodiceFiscale" = 'XXXXXXXXXXXXXXXX';
```
Per vedere chi è in attesa:
```sql
SELECT "CodiceFiscale","Nome","Cognome","Email","Verificato"
FROM specialista WHERE "Verificato" = false ORDER BY "Cognome";
```

## 10. Reset password — codice OTP via email

Il flusso "Password dimenticata?" usa un codice OTP a 6 cifre: `sendPasswordReset` invia la
mail, poi `ResetPasswordScreen` verifica il codice (`verifyOTP`, `OtpType.recovery`) e imposta
la nuova password. Sul Dashboard Supabase, Authentication → Emails → Templates → Reset Password,
il corpo deve usare `{{ .Token }}` (il codice) al posto di `{{ .ConfirmationURL }}` (il link):
```html
<h2>Reimposta la tua password</h2>
<p>Usa questo codice per reimpostare la password del tuo account Nutrease:</p>
<p style="font-size:28px; font-weight:bold; letter-spacing:4px;">{{ .Token }}</p>
<p>Il codice è valido per un'ora. Se non hai richiesto tu il reset, ignora questa email.</p>
```
Note: la scadenza dell'OTP si imposta in Authentication → Emails (default 3600s); per test e
demo va bene il mittente SMTP integrato di Supabase. Questo flusso non usa il link, quindi il
Site URL può restare al default.

> La build di release firmata è **fuori scope** nel porting (ADR-0022): il progetto usa la sola
> `signingConfig` di debug e si valuta via `flutter analyze`/`flutter test`.
