# Architettura — Nutrease Flutter

> Diagramma dell'architettura, registro degli ADR (Architecture Decision Records) e
> pattern strutturali ricorrenti (template Repository/ViewModel, layout dei package).
> Da leggere prima di una nuova decisione architetturale o di aggiungere una feature,
> per capire dove vanno i file.
> Questo è il **porting Flutter a scope ridotto** dell'app Android nativa: copre RF1–RF20
> (vedi `requirements.md`), riusa lo stesso backend Supabase **in sola lettura** (schema e
> RLS vivono in `../Nutrease/sql/` e non si toccano). La numerazione degli ADR è tenuta
> allineata a quella dell'app Android per tracciabilità: i commenti nel codice citano gli
> stessi numeri. Le decisioni relative a feature non portate (chat, statistiche, promemoria,
> release firmata) sono marcate come fuori scope.

---

## Overview

MVVM + Clean Architecture su 3 layer:
```
presentation/ (Widget + ViewModel:ChangeNotifier) ← Flutter
domain/       (UseCase + Model + Repo iface)        ← Dart puro
data/         (Repo impl + DTO + Mapper + local)    ← supabase_flutter / sqflite
                ↓ Supabase (Postgres + Auth + RLS)
```
Le frecce di dipendenza puntano verso `domain/`, che non importa né Flutter né Supabase né
sqflite. È così la traduzione uno a uno del `domain/` Kotlin dell'app Android, testabile con
soli `flutter test` senza emulatore. Lo stato della UI vive nei ViewModel (`ChangeNotifier`)
esposti per schermata via `provider`; il flusso obbligato è `Widget → ViewModel → UseCase →
Repository (interfaccia in domain) → RepositoryImpl (data) → Supabase`.

---

## Registro ADR

Formato [Michael Nygard](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions):
stato, data, contesto, decisione, conseguenze. Un ADR accettato non si ridiscute senza un
motivo forte; semmai se ne apre uno nuovo che lo sostituisce.

### ADR-0001 — MVVM + Clean Architecture a 3 layer
Accettato. Contesto: progetto portabile e testabile. Decisione: 3 layer (data/domain/presentation), interfaccia Repository in `domain/` e implementazione in `data/`, un ViewModel per schermata. Lo stato della UI è un `ChangeNotifier` con un campo `UiState` immutabile, notificato con `notifyListeners()` (l'equivalente Flutter dello `StateFlow` Android). Conseguenze: più codice di servizio (DTO, Domain, Mapper per ogni feature) ma confini chiari e niente Flutter nella logica di base.

### ADR-0002 — Supabase Auth come unico provider di identità
Accettato. Contesto: serve autenticazione email/password con join sulle tabelle profilo. Decisione: Supabase Auth come unico provider, lo stesso backend che ospita i dati. Conseguenze: una sola identità per utente, quindi le RLS usano `auth.uid()` direttamente. Niente provider social, non richiesti.

### ADR-0003 — SDK `supabase_flutter`
Accettato. Contesto: accesso a Supabase da Dart/Flutter. Decisione: pacchetto ufficiale `supabase_flutter` (Auth + Postgrest), inizializzato in `main()` prima di `runApp`. Conseguenze: API `Future`-first; la sessione persistente è gestita dall'SDK (storage sicuro on-device), quindi `currentSession` è già leggibile dopo `Supabase.initialize`. Sostituisce il `supabase-kt` dell'app Android.

### ADR-0004 — Dependency injection con `provider` (composition root)
Accettato. Contesto: serve DI per Repository, UseCase e `SupabaseClient`. Decisione: niente generatore di codice (al posto di Hilt/KSP dell'app Android); le dipendenze condivise sono `Provider` singleton registrati in un'unica composition root (`core/di/app_providers.dart`), i ViewModel sono creati per-schermata via `ChangeNotifierProvider` nel builder della rotta. Conseguenze: zero annotazioni e zero build-step, grafo delle dipendenze leggibile in un solo file; in cambio il wiring è manuale.

### ADR-0005 — `DateTime` Dart + `intl` (niente librerie esterne per le date)
Accettato. Contesto: il `domain/` deve restare puro e le date servono in dominio, DTO e UI. Decisione: `DateTime` del core Dart in dominio e DTO (sempre date-only o ISO string verso il DB); la formattazione localizzata (nomi mesi/giorni in `it_IT`) avviene solo in `presentation/` via `intl`/`DateFormat`. Conseguenze: dominio senza dipendenze, sostituisce il `kotlinx-datetime` dell'app Android uno a uno.

### ADR-0006 — Mapping DB PascalCase italiano e domain inglese
Accettato. Contesto: lo schema DB è in italiano con identificatori PascalCase quotati (`"IdAlimento"`, `"LattosioP100g"`); i domain model sono in inglese per leggibilità. Decisione: DB in PascalCase italiano; DTO che serializzano i nomi DB; domain model in inglese (`Food`, `lactosePer100g`, `Patient`, `Specialist`); il mapper in `data/mapper/` traduce. Conseguenze: un layer di traduzione in più, ma `domain/` pulito. La tabella di traduzione sta nel commento in testa a ciascun mapper.

### ADR-0007 — Regola "domain/ puro"
Accettato. Contesto: evitare che il dominio si accoppi ai framework. Decisione: in `domain/` sono vietati gli import di `package:flutter/*`, `package:supabase_flutter/*` e `package:sqflite/*`; il dominio riusa solo `core/error/` (`Result`/`DomainError`, anch'essi framework-free). Il controllo avviene in code review. Conseguenze: UseCase e modelli testabili senza emulatore; le dipendenze dei framework restano in DTO, mapper e implementazioni dei Repository.

### ADR-0008 — Niente SDK di crash reporting nell'MVP
Accettato. Contesto: un servizio di crash reporting aggiunge SDK e configurazione per ogni dev. Decisione: nessun SDK di error reporting; i crash si leggono dalla console durante test e demo. Conseguenze: dipendenze minime e zero configurazione extra. Integrabile dopo senza impatti architetturali.

### ADR-0009 — RLS con lookup via `profilo_utente`
Accettato. Contesto: `auth.users` ha solo email e password, ma le RLS devono sapere se l'utente è paziente o specialista. Decisione (backend, invariata dall'app Android): la tabella `profilo_utente` come lookup; le policy la interrogano con `auth.uid()`. Conseguenze: un join logico per policy (veloce, tabella piccola e indicizzata); il client, dopo il login, legge il proprio `profilo_utente` per ruolo e codice fiscale.

### ADR-0010 — Nutrienti via trigger (non colonna GENERATED)
Accettato. Contesto: `LattosioCalc` dipende da `QuantitaGrammi * alimento.LattosioP100g / 100`, e Postgres non permette subquery in `GENERATED ALWAYS AS`. Decisione (backend): colonne normali `*Calc` su `alimento_pasto`, riempite dal trigger `calcola_nutrienti_pasto`. Conseguenze: il client invia solo i grammi e legge i totali già calcolati; le letture sono semplici (niente join per la somma).

### ADR-0011 — Stringhe UI centralizzate in `ItStrings`
Accettato. Contesto: convenzione di progetto (identificatori in inglese, testi UI in italiano). Decisione: tutte le stringhe utente in `core/strings/it_strings.dart` (classe `ItStrings`); i widget Material sono forzati in italiano via `flutter_localizations` con locale fisso `it`. Sostituisce lo `strings.xml` dell'app Android. Conseguenze: testi ricercabili in un punto solo e i18n predisposta.

### ADR-0012 — Error handling: `Result<T>` + `Resource<T>`
Accettato. Contesto: serve distinguere l'esito secco di una chiamata dallo stato continuo (loading/success/error) della UI. Decisione: `sealed class Result<T>` (`Ok`/`Err`) per Repository e UseCase, e `sealed class Resource<T>` (`Loading`/`Success`/`Failure`) per lo stato async consumato da `AsyncValueView`. Entrambi dipendono solo da `DomainError` (dominio puro). Conseguenze: gestione uniforme con `switch` esaustivo, gli errori arrivano in UI già come messaggi italiani.

### ADR-0013 — Edit mode via query param della rotta
Accettato. Contesto: `AddMealScreen`/`AddSymptomScreen` servono sia per inserire che per modificare (RF12); passare un oggetto di dominio nell'URL è fragile. Decisione: la rotta riceve `?meal_id=`/`?symptom_id=` (`go_router`): assente o nullo = inserimento, valore positivo = modifica (il ViewModel carica la voce e precompila lo stato). Sostituisce il `SavedStateHandle` dell'app Android. Conseguenze: nav graph con soli tipi primitivi, pattern riusato per ogni form.

### ADR-0014 — Refresh del diario via `RouteObserver`
Accettato. Contesto: dopo il salvataggio di un pasto la lista restava vecchia (il ViewModel sopravvive alla navigazione). Decisione: un `RouteObserver` (`diaryRouteObserver`) notifica `DiaryScreen`, che ricarica in `didPopNext()` quando le schermate di aggiunta/modifica vengono chiuse, senza affidarsi a un risultato di navigazione. Sostituisce il `LifecycleStartEffect` dell'app Android. Conseguenze: una chiamata di rete in più al ritorno, accettabile per l'MVP.

### ADR-0015 — Registrazione atomica via trigger su `auth.users`
Accettato. Contesto: creare account e profilo con scritture separate lascia stati a metà se una fallisce. Decisione (backend): il client passa i campi come metadata nel `signUp`; un trigger `SECURITY DEFINER` su `auth.users` (`crea_profilo_da_auth`) inserisce `profilo_utente` e `paziente`/`specialista` nella stessa transazione. `AuthRepository.register` delega quindi tutto al backend. Conseguenze: atomicità garantita dal DB; gli errori del trigger tornano come 5xx opachi, mitigati dalla validazione client.

### ADR-0016 — Vista diario specialista: riuso di `DiaryRepository`/`SymptomRepository`
Accettato. Contesto: per RF18–RF20 servirebbe un repository dedicato, ma `getMealsForDate(fascicoloId, date)` e `getSymptomsForDate(fascicoloId, date)` accettano già un `fascicoloId` parametrico e le RLS autorizzano la lettura allo specialista collegato. Decisione: nessun nuovo repository per il diario; si riusano quelli esistenti passando il `fascicoloId` del paziente. L'unico repository nuovo è `LinkedPatientsRepository`; il fan-out per giorno sta in `GetPatientDiaryRangeUseCase` (`Future.wait`). Conseguenze: zero duplicazione, il diritto di lettura vive solo nelle policy SQL; la UI specialista è read-only (nessun FAB/menu).

### ADR-0017 — Cap di 92 giorni sul range del diario specialista
Accettato. Contesto: `GetPatientDiaryRangeUseCase` itera giorno per giorno con due read parallele al giorno; un range troppo ampio fa esplodere le chiamate PostgREST parallele e va in timeout. Decisione: cap lato client a 92 giorni; oltre, la richiesta fallisce subito con un `ValidationError` (il date picker non vincola, ma la richiesta non parte). Conseguenze: chiamate limitate; per intervalli più lunghi servirebbe un RPC server-side aggregato (rimandato).

### ADR-0018 — Grafico statistiche
**Fuori scope nel porting.** RF21 (dashboard statistiche con grafico) non è portato: la `PatientDiaryScreen` resta sola lettura senza grafici né BMI.

### ADR-0019 — Promemoria del diario (notifiche locali)
**Fuori scope nel porting.** RF22 non è portato: nessuno scheduler né notifiche locali.

### ADR-0020 — Chat real-time
**Fuori scope nel porting.** RF23/RF24 non sono portati: nessun canale Realtime, nessuna schermata chat.

### ADR-0021 — Auto-login con gate di sessione + re-auth sulle operazioni sensibili
Accettato. Contesto: RF3 chiede una sessione persistente; RF6/RF7 chiedono di ri-autenticarsi prima del cambio password o dell'eliminazione. Decisione: destinazione iniziale `splash`; `RootViewModel` legge la sessione ripristinata (`Supabase.initialize` è atteso in `main`) e instrada alla home per ruolo o al login; il re-auth ri-esegue `signInWithPassword` prima delle operazioni sensibili; le regole password sono centralizzate in `domain/model/PasswordPolicy`. Conseguenze: un round-trip in più all'avvio verso `profilo_utente`, logica di sessione in un punto solo, password mai salvata.

### ADR-0022 — Build di release firmata
**Fuori scope nel porting.** Il porting si valuta via `flutter analyze`/`flutter test`; la build Android usa la sola `signingConfig` di debug. Nessun keystore nel repo.

### ADR-0023 — Accettazione e re-invio richiesta: trigger SECURITY DEFINER + upsert
Accettato. Contesto: all'accettazione il trigger che crea il fascicolo deve scrivere su tabelle dove lo specialista non è ancora titolare; il re-invio dopo un rifiuto violerebbe il vincolo `UNIQUE(CodFiscalePaziente, CodFiscaleSpecialista)`. Decisione (backend + client): `crea_fascicolo_da_richiesta` è `SECURITY DEFINER`; `LinkRequestRepositoryImpl.sendLinkRequest` usa un **upsert** che riporta la richiesta a "In Attesa" e azzera `DataRisposta`/`MotivazioneRifiuto`. Nota: in Dart i `null` espliciti vengono serializzati, quindi non c'è il problema di `encodeDefaults` del client Kotlin. Conseguenze: accettazione e re-invio robusti a prescindere dallo stato residuo.

### ADR-0024 — Eliminazione account: errori generici (`DomainError`) + RPC server-side
Accettato. Contesto: gli errori di auth non devono esporre dettagli tecnici né rivelare se un'email esiste, e la cancellazione dal client verrebbe filtrata dalle RLS. Decisione: una `sealed class DomainError` con messaggi già generici (login e re-auth danno sempre lo stesso `AuthError`); l'eliminazione passa per l'RPC `delete_own_account` (`SECURITY DEFINER`), che cancella i dati di dominio e l'auth user atomicamente e blocca lo specialista con pazienti collegati restituendo `has_linked_patients`. Conseguenze: niente enumerazione utenti, cancellazione completa, specialista protetto dai cascade pericolosi.

### ADR-0025 — Promemoria multipli
**Fuori scope nel porting.** Conseguenza di ADR-0019: RF22 non è portato.

### ADR-0026 — Età minima alla registrazione + maschera per la data di nascita
Accettato. Contesto: la registrazione paziente accettava qualunque data di nascita, senza vincolo d'età, con un campo fragile. Decisione: una regola pura `domain/model/AgePolicy` (`minAge = 18`, `isValidBirthDate(birthDate, now)` con "oggi" iniettabile per test deterministici), applicata sia nella UI (errore inline e bottone disabilitato) sia in modo autoritativo nel `RegisterViewModel`; la data si digita a sole cifre e le `/` sono inserite in sola visualizzazione da un `TextInputFormatter` (`date_slash_input_formatter.dart`). Conseguenze: limite d'età centralizzato e testato; vale solo per i pazienti (gli specialisti non hanno data di nascita).

### ADR-0027 — Badge "letto/visto" in home
**Fuori scope nel porting.** I badge dell'app Android riguardavano soprattutto le chat non lette (non portate); il porting non usa persistenza locale di stato UI (nessuna dipendenza da `shared_preferences`).

### ADR-0028 — Verifica/approvazione specialisti (gate `Verificato`)
Accettato. Contesto: chiunque potrebbe registrarsi come specialista e vedere i dati clinici dei pazienti che lo collegano. Decisione (backend + client): colonna `specialista."Verificato"` (default false); le policy mostrano ai pazienti solo i verificati e impediscono a un non-verificato di accettare/rifiutare; lato client `Specialist.isVerified` alimenta un banner "Account in verifica" nella home specialista. Conseguenze: nessuno specialista opera o è visibile senza approvazione, controllo interamente server-side. L'approvazione avviene dal Dashboard Supabase (niente UI admin).

### ADR-0029 — Ricerca alimenti: client-side su dataset in cache + ranking fuzzy in Dart puro
Accettato. Contesto: una ricerca `ILIKE '%query%'` lato DB non tollera i refusi né il match multi-parola. Decisione: `FoodRepository.getAllFoods()` scarica l'intera tabella `alimento` una volta e la tiene in cache in memoria; tutto il matching e il ranking stanno in `domain/model/food_search.dart` (puro, testato): normalizzazione (minuscole + rimozione accenti con mappa esplicita), tokenizzazione, semantica AND per token, livelli esatto > prefisso > sottostringa > fuzzy (Levenshtein, 1 refuso), ordinamento per rilevanza poi nome. Il caricamento è protetto da una guard **single-flight** e il parsing del dataset gira in un isolate via `compute`. Conseguenze: tolleranza ai refusi, ricerca multi-parola e istantanea anche offline dopo il primo scaricamento.

### ADR-0030 — Promemoria esatti
**Fuori scope nel porting.** Conseguenza di ADR-0019: RF22 non è portato.

---

## Decisioni specifiche del porting Flutter

### ADR-FL-1 — Cache offline del diario via `sqflite` (read-side)
Accettato. Contesto: RF11 chiede una consultazione del diario anche con rete assente; l'app Android aveva rimandato la cache su Room (restando online-only). Nel porting la cache di lettura è stata implementata. Decisione: un `DiaryCacheDao` su `sqflite` (DB aperto pigramente, iniettabile come in-memory FFI nei test) con scrittura **cache-aside** best-effort dopo ogni lettura online e fallback al giorno in cache quando rete/DB falliscono; ogni `update`/`delete` usa `where`/`whereArgs` (mai concatenazione di stringhe). La cache conserva i totali del pasto, non le singole righe alimento. Conseguenze: lettura del diario resiliente offline; le scritture restano online-only.

### ADR-FL-2 — Stato UI come `ChangeNotifier` + `provider`
Accettato. Contesto: serve l'equivalente Flutter del binding `StateFlow`/Hilt dell'app Android. Decisione: ogni schermata ha un ViewModel `ChangeNotifier` con un `UiState` immutabile; le dipendenze condivise (Repository, UseCase, `SupabaseClient`) sono `Provider` singleton nella composition root, i ViewModel sono `ChangeNotifierProvider` per-schermata. Conseguenze: ricostruzioni mirate, ViewModel testabili in isolamento con UseCase finti.

### ADR-FL-3 — Routing auth-gated con `go_router`
Accettato. Contesto: serve un gate che reindirizzi a login/home in base alla sessione, senza riavviare l'app a login/logout. Decisione: `go_router` con `redirect` puro (`resolveRedirect`, estratto e testato) e un `refreshListenable` agganciato a `onAuthStateChange`; `splash` e `reset_password` non vengono mai reindirizzati (risolvono da soli la propria destinazione). Conseguenze: navigazione coerente con lo stato di auth, logica di gate isolata e unit-testabile.

---

## Dataset alimentare

- `alimento`: 1.388 voci, valori nutrizionali per 100 g. Popolamento: prima
  `../Nutrease/sql/nutreaseDatabase.sql`, poi `../Nutrease/sql/alimento_seed.sql`
  (sanity-check `count>=1388`). Il porting non modifica lo schema né i dati.
- Il dataset supera il limite di righe di default di PostgREST, quindi `getAllFoods()` lo
  scarica paginando con `range` (pagina da 1000) e ordina per `IdAlimento`.
- Il grammo è l'unità base implicita: il JSON `ConversioniUnitaMisura` contiene solo le
  conversioni non banali (per esempio `{"cucchiaio":15,"fetta":30}`) e mai la chiave `"g"`;
  lato client `Food.availableUnits()` antepone `"g"` come prima opzione.
- Il parsing delle 1.388 voci gira in un isolate via `compute` per non bloccare la UI; il
  dataset parsato resta in cache in memoria nel `FoodRepositoryImpl` (singleton).

---

## Pattern ricorrenti

### Layout dei file per feature
```
data/dto/food_dto.dart · data/mapper/food_mapper.dart · data/repository/food_repository_impl.dart
domain/model/food.dart · domain/repository/food_repository.dart · domain/usecase/search_foods_use_case.dart
presentation/screens/diary/{diary_screen,diary_view_model}.dart · presentation/navigation/app_router.dart
core/di/app_providers.dart (SupabaseClient singleton + binding dei repository) · core/theme/
```

### Template Repository
```dart
// domain/repository/food_repository.dart
abstract interface class FoodRepository {
  Future<Result<List<Food>>> getAllFoods();
}
// data/repository/food_repository_impl.dart
class FoodRepositoryImpl implements FoodRepository {
  FoodRepositoryImpl(this._client);
  final SupabaseClient _client;
  // ...
}
```

### Template ViewModel
```dart
class DiaryViewModel extends ChangeNotifier {
  DiaryViewModel(this._getMealsForDate);
  final GetMealsForDateUseCase _getMealsForDate;

  Resource<List<Meal>> _state = const Loading();
  Resource<List<Meal>> get state => _state;

  Future<void> load(int fascicoloId, DateTime date) async {
    _state = const Loading();
    notifyListeners();
    final result = await _getMealsForDate(fascicoloId, date);
    _state = result.fold(
      ok: (meals) => Success(meals),
      err: (e) => Failure(e),
    );
    notifyListeners();
  }
}
```

---

## Vincoli non negoziabili

1. Niente import di `package:flutter/*`, `package:supabase_flutter/*` o `package:sqflite/*` in `domain/`.
2. Niente credenziali committate: i segreti Supabase passano da `--dart-define`/`env.json` (gitignored), mai nel codice né nel template.
3. Niente modifiche allo schema o alle RLS del backend: il porting è read-only su `../Nutrease/sql/`.
4. Niente query SQL grezze lato server dal client: sempre PostgREST (`supabase_flutter`) o RPC; nel DAO locale sempre `where`/`whereArgs`, mai concatenazione.
5. Niente logica di business nei widget: va negli UseCase; i widget leggono solo lo `UiState`.
6. `flutter analyze` deve restare a 0 issue (config in `analysis_options.yaml`) e `flutter test` verde.
7. Testi utente in italiano via `ItStrings` (ADR-0011); identificatori del codice in inglese.
