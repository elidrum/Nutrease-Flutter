# Backlog — Nutrease Flutter

> Piano per sprint del **porting Flutter a scope ridotto** (RF1–RF20). Ogni voce è un RF di
> `requirements.md`, ordinato per dipendenze. A porting concluso resta come storico della
> pianificazione e lista dei debiti / fuori scope.
> Il riferimento dell'app Android nativa completa (24 RF) è https://github.com/elidrum/Nutrease.

---

## Sprint 1 — Scaffolding
Obiettivo: fondamenta del progetto, build verde, Supabase connesso.
- [x] Scaffolding del progetto e tema Material 3
- [x] Init Supabase in `main()` + lettura segreti via `--dart-define` (`Env`)
- [x] Composition root `provider` (`core/di/app_providers.dart`, ADR-0004/FL-2)
- [x] Modello errori `Result`/`Resource`/`DomainError` (ADR-0012)
- [x] Router auth-gated con `go_router` (ADR-FL-3) + widget di stato (loading/empty/error)

DoD: l'app parte; senza segreti mostra la schermata di configurazione, con segreti raggiunge il login.

## Sprint 2 — Autenticazione e account (RF1–RF7)
Obiettivo: paziente e specialista si registrano, loggano e gestiscono l'account.
- [x] **RF1** Registrazione paziente (età ≥18 `AgePolicy`, password `PasswordPolicy`, ADR-0026)
- [x] **RF2** Registrazione specialista (parte non verificato, ADR-0028)
- [x] **RF3** Login con routing per ruolo + auto-login (ADR-0021)
- [x] **RF4** Logout (svuota la cache `sqflite`)
- [x] **RF5** Modifica profilo · **RF6** Cambio password (re-auth) · **RF7** Eliminazione account (RPC, ADR-0024)
- [x] Reset password via OTP ("Password dimenticata?")

DoD: registrazione paziente → login → logout → registrazione specialista → login → logout.

## Sprint 3 — Ricerca alimenti e pasti (RF8–RF9)
Obiettivo: il paziente cerca alimenti e registra pasti.
- [x] **RF8** Ricerca alimenti client-side con ranking fuzzy + conversione unità (ADR-0029)
- [x] **RF9** Inserimento pasto multi-alimento (trigger `calcola_nutrienti_pasto`, rollback logico)

DoD: il paziente cerca "spagetti" (con refuso) e registra un pasto multi-alimento.

## Sprint 4 — Sintomi, diario e cache offline (RF10–RF12)
Obiettivo: diario giornaliero completo, con lettura offline.
- [x] **RF10** Registrazione sintomi con severità
- [x] **RF11** Consultazione diario (timeline mista pasti+sintomi, `DailyDiary.timeline`)
- [x] **RF12** Modifica/eliminazione voci (edit mode via query param, ADR-0013)
- [x] Cache offline read-side del diario via `sqflite` (ADR-FL-1)

DoD: il paziente registra pasti e sintomi, li vede in timeline, ne modifica uno; il diario di
ieri resta consultabile offline.

## Sprint 5 — Discovery e richieste di collegamento (RF13–RF17)
Obiettivo: il paziente trova uno specialista e si collega.
- [x] **RF13** Discovery specialisti (solo verificati, esclude già collegati/pendenti)
- [x] **RF14** Invio richiesta (re-invio come upsert, ADR-0023)
- [x] **RF15** Richieste ricevute (lato specialista) · **RF16** Accettazione (trigger crea fascicolo) · **RF17** Rifiuto con motivazione
- [x] Card "Il tuo specialista" lato paziente

DoD: il paziente invia una richiesta, lo specialista la accetta, il collegamento compare da entrambi i lati.

## Sprint 6 — Vista specialista e rifinitura (RF18–RF20)
Obiettivo: lo specialista consulta i diari; rifinitura finale.
- [x] **RF18** Lista pazienti collegati
- [x] **RF19** Diario paziente **read-only** (riuso `DiaryRepository`/`SymptomRepository`, ADR-0016)
- [x] **RF20** Filtri periodo (oggi/7g/30g/personalizzato, cap 92gg ADR-0017) + nutriente come evidenziazione
- [x] Rifinitura: accessibilità, stringhe in `ItStrings`, README, demo-script, QA, `flutter analyze`/`flutter test`

DoD: lo specialista apre il diario di un paziente collegato, filtra "ultimi 7 giorni" + "Lattosio"
e vede l'aggregato evidenziato, senza poter modificare nulla.

---

## Fuori scope nel porting

Presenti nell'app Android nativa, non portati (vedi `requirements.md` e gli ADR):
- **RF21** Dashboard statistiche paziente (grafico, BMI) — ADR-0018.
- **RF22** Promemoria del diario (notifiche locali) — ADR-0019/0025/0030.
- **RF23/RF24** Chat real-time paziente ↔ specialista — ADR-0020.

## Debiti noti / pulizie

- [ ] Reset password: il flusso OTP funziona; un eventuale deep-link resta un'estensione (ADR-0024).
- [ ] Eliminazione account specialista con pazienti collegati: bloccata (`has_linked_patients`); servirebbe uno scollegamento (ADR-0024).
- [ ] Verifica specialisti: il gate `Verificato` esiste lato DB, ma l'approvazione si fa dal Dashboard Supabase (niente UI admin, ADR-0028).

## Workflow per task

```bash
git checkout -b feature/rfN-titolo-breve
# implementa leggendo requirements.md §RFN
flutter analyze && flutter test
git add -A && git commit -m "feat(rfN): <titolo>"
```
