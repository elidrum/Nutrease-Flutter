# Nutrease Flutter

> Vetrina pubblica del porting. Contesto tecnico esteso in `docs/`.

[![Status](https://img.shields.io/badge/status-porting%20completo-brightgreen)]()
[![Flutter](https://img.shields.io/badge/Flutter-stable-blue)]()
[![Dart](https://img.shields.io/badge/Dart-3.12-blue)]()

---

Porting Flutter di **Nutrease**, app per il monitoraggio alimentare e sintomatologico, a
**scope ridotto** rispetto all'app Android nativa. Pensata per due figure che lavorano insieme:

- **Paziente** — registra pasti e sintomi nel diario, cerca alimenti e si collega a uno specialista.
- **Specialista** (nutrizionista, dietista, gastroenterologo) — consulta in **sola lettura** i diari dei pazienti collegati, con filtri per nutriente e periodo.

L'obiettivo clinico è stimare automaticamente lattosio, sorbitolo e glutine ingeriti, per
individuare correlazioni con i sintomi e supportare la diagnosi delle intolleranze alimentari.

Questo repository è il porting dell'app Android nativa completa
([github.com/elidrum/Nutrease](https://github.com/elidrum/Nutrease)): riusa lo **stesso backend
Supabase in sola lettura** (schema e RLS non si modificano).

## Stack tecnologico

| Livello | Tecnologia |
|---|---|
| Linguaggio | Dart 3.12 |
| UI | Flutter + Material 3 |
| Navigazione | go_router (routing auth-gated) |
| Backend | Supabase (Postgres + Auth + RLS) — condiviso, read-only |
| Cache | sqflite (lettura diario offline) + dataset alimenti in memoria |
| DI / stato | provider + ChangeNotifier |
| Date/orari | DateTime + intl |

Architettura: MVVM + Clean Architecture su 3 layer (`data`/`domain`/`presentation`). Dettagli
e ADR in [`docs/architecture.md`](docs/architecture.md).

## Funzionalità

Catalogo completo in [`docs/requirements.md`](docs/requirements.md). In sintesi (RF1–RF20):

- Autenticazione e gestione profilo (paziente / specialista), reset password via OTP
- Ricerca alimenti con ranking fuzzy e conversione automatica delle unità in grammi
- Diario alimentare multi-alimento con stima nutrienti e registrazione sintomi
- Consultazione diario giornaliero con cache offline in lettura
- Discovery specialisti, richieste di collegamento, fascicolo clinico
- Consultazione diario paziente lato specialista (read-only) con filtri per periodo e nutriente

**Scope ridotto rispetto all'app Android** — sono volutamente fuori scope: chat paziente ↔
specialista (RF23/RF24), promemoria del diario (RF22) e dashboard statistiche dello specialista
(RF21). La vista del diario lato specialista è quindi sola lettura, senza grafici né BMI.

## Setup rapido

Procedura completa in [`docs/setup.md`](docs/setup.md). In breve:

1. Clona il repo, apri in Android Studio ed esegui `flutter pub get`.
2. I segreti Supabase si passano via `--dart-define`, da un `env.json` gitignored (copia da
   `env.json.template`):
   ```json
   { "SUPABASE_URL": "https://<progetto>.supabase.co", "SUPABASE_ANON_KEY": "sb_publishable_<...>" }
   ```
3. Avvia: `flutter run --dart-define-from-file=env.json`.

> Senza segreti validi l'app non crasha: mostra una schermata che spiega come configurarli.
> `env.json` è gitignored; in git c'è solo `env.json.template` con i placeholder.

## Struttura del progetto

```
lib/
├── core/         # config/ error/ di/ theme/ strings/ widgets/
├── data/         # dto/ mapper/ repository/ local/ (Supabase + sqflite)
├── domain/       # (puro) model/ repository/ usecase/
└── presentation/ # navigation/ screens/ (Widget + ViewModel ChangeNotifier)
```

Flusso obbligato: `Widget → ViewModel → UseCase → Repository (interfaccia in domain) →
RepositoryImpl (data) → Supabase`. Il layer `domain/` resta puro (nessun import
Flutter/Supabase/sqflite). Identificatori del codice in inglese, commenti e stringhe UI in
italiano (`core/strings/it_strings.dart`).

## Test e analisi

```bash
flutter analyze   # 0 issue
flutter test      # verde
```

## Git workflow

- Messaggi di commit descrittivi in italiano, uno per area funzionale.
- Mai committare credenziali: `env.json` e le chiavi restano fuori dal VCS (gitignored).

## Licenza

Progetto ad uso interno (tesi/esame). Non distribuire senza autorizzazione.
