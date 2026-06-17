# Requisiti funzionali — Nutrease Flutter

> Catalogo dei requisiti coperti dal **porting Flutter a scope ridotto**: RF1–RF20,
> raggruppati per macro-area. È il riferimento per implementare una feature: scope,
> acceptance criteria (AC), tabelle DB coinvolte (vedi `../Nutrease/sql/nutreaseDatabase.sql`)
> e dipendenze da altri RF.
> Rispetto all'app Android nativa (24 RF) sono **volutamente fuori scope** RF21 (dashboard
> statistiche), RF22 (promemoria) e RF23/RF24 (chat): vedi la sezione finale.
> Alcuni RF sono realizzati con variazioni rispetto alla spec originale, documentate negli
> ADR di `architecture.md`.

---

## Macro-area 1 — Identità e account

### RF1 — Registrazione paziente
Attore: utente non autenticato. Si registra con email, password, nome, cognome, data di nascita, sesso, altezza, peso.
- AC: email validata e unica · password ≥8 caratteri, ≥1 maiuscola, ≥1 cifra (`PasswordPolicy`) · data di nascita nel passato ed età ≥18 (`AgePolicy`, ADR-0026) · la creazione di account, `profilo_utente` e riga `paziente` è atomica lato backend (il client fa il `signUp` con i metadata, un trigger `SECURITY DEFINER` crea le righe — ADR-0015) · errore → messaggio italiano generico · su successo → home paziente.
- DB: `auth.users`, `paziente`, `profilo_utente`. Dip.: nessuna.

### RF2 — Registrazione specialista
Attore: utente non autenticato. Registrazione come specialista (dietista/nutrizionista/gastroenterologo) con dati professionali.
- AC: campi obbligatori email, password, nome, cognome, specializzazione (ENUM), numero albo, città · stesse regole password di RF1 · creazione atomica via trigger (ADR-0015) · lo specialista nasce **non verificato** e non è operativo né visibile finché non viene approvato (ADR-0028) · su successo → home specialista (banner "Account in verifica").
- DB: `auth.users`, `specialista`, `profilo_utente`. Dip.: nessuna.

### RF3 — Login
Attore: utente non autenticato. Auth email+password; il sistema determina il ruolo e instrada alla home.
- AC: `signInWithPassword` · lettura di `profilo_utente` per ruolo e codice fiscale · paziente → home paziente, specialista → home specialista · errore credenziali generico senza rivelare quale campo è errato (ADR-0024) · sessione persistente con auto-login al riavvio (ADR-0021).
- DB: `auth.users`, `profilo_utente`. Dip.: RF1 o RF2.

### RF4 — Logout
Attore: paziente/specialista. Termina la sessione.
- AC: `signOut()` · svuotamento della cache locale del diario (`sqflite`) · ritorno al login con back stack ripulito (gate di navigazione, ADR-0021).
- DB: nessuna (solo auth). Dip.: RF3.

### RF5 — Modifica profilo
Attore: paziente/specialista (solo i propri dati).
- AC: il paziente modifica altezza, peso, data di nascita, sesso (non l'email); lo specialista specializzazione, città, numero albo · stesse validazioni di RF1/RF2 · update parziale sulla tabella di ruolo · le RLS permettono l'update solo della propria riga.
- DB: `paziente`/`specialista`, `profilo_utente`. Dip.: RF3.

### RF6 — Cambio password
Attore: utente autenticato.
- AC: richiede la password corrente (re-auth, ADR-0021) · nuova password con le regole di RF1 (`PasswordPolicy`) · `updateUser(password: ...)`.
- DB: `auth.users`. Dip.: RF3.

### RF7 — Eliminazione account
Attore: utente autenticato.
- AC: conferma con modale + re-auth · eliminazione via RPC server-side `delete_own_account` (`SECURITY DEFINER`): cancella i dati di dominio e l'auth user atomicamente (ADR-0024) · lo specialista con pazienti collegati è bloccato (`has_linked_patients`) · logout automatico.
- DB: tabelle di ruolo + `auth.users` (lato RPC). Dip.: RF3.

---

## Macro-area 2 — Diario e alimenti

### RF8 — Ricerca alimenti con conversione unità
Attore: paziente. Ricerca incrementale con suggerimenti; anteprima della quantità in grammi per l'unità scelta.
- AC: ricerca **client-side** sul dataset in cache, con tolleranza ai refusi e match multi-parola (ranking fuzzy in `food_search.dart`, ADR-0029) · risultati con nome, categoria e unità da `ConversioniUnitaMisura` · unità ≠ grammo → conversione automatica in grammi · empty state esplicito.
- DB: `alimento`. Dip.: RF3.

### RF9 — Inserimento pasto multi-alimento
Attore: paziente. Pasto con uno o più alimenti, ciascuno con quantità e unità.
- AC: tipo pasto (ENUM) · data/ora selezionabili (default adesso) · lista alimenti aggiungibile/rimuovibile prima del submit · per alimento quantità >0 e unità tra quelle disponibili · al submit INSERT `pasto` poi INSERT multipli `alimento_pasto` (il trigger `calcola_nutrienti_pasto` popola i `*Calc`) · fallimento parziale → rollback logico (cancellazione della testata, cascade FK) · conferma + refresh.
- DB: `pasto`, `alimento_pasto`, `alimento`. Dip.: RF8.

### RF10 — Registrazione sintomi con severità
Attore: paziente. Sintomo con tipo, severità e orario.
- AC: tipo da ENUM · severità con label (da Lieve a Grave) · data/ora (default adesso) · INSERT `sintomo`.
- DB: `sintomo`. Dip.: RF3.

### RF11 — Consultazione diario giornaliero (paziente)
Attore: paziente. Vista del proprio diario per una data.
- AC: date picker (default oggi) · timeline cronologica mista pasti+sintomi (fusione pura, `DailyDiary.timeline`) · per pasto: tipo, ora, totali nutrienti aggregati (somma `*Calc`) · per sintomo: tipo, ora, severità · pull-to-refresh · **cache offline di lettura** della giornata via `sqflite` (ADR-FL-1).
- DB: `pasto`, `alimento_pasto`, `alimento`, `sintomo`. Dip.: RF9, RF10.

### RF12 — Modifica/eliminazione voci diario
Attore: paziente.
- AC: dalla voce → Modifica/Elimina · la modifica apre la form di RF9/RF10 precompilata (edit mode via query param della rotta, ADR-0013) · eliminazione con modale + DELETE (cascade FK `ON DELETE CASCADE` per `alimento_pasto`) · le RLS limitano alle proprie voci.
- DB: `pasto`, `alimento_pasto`, `sintomo`. Dip.: RF9, RF10, RF11.

---

## Macro-area 3 — Collaborazione (collegamento paziente–specialista)

### RF13 — Discovery specialisti
Attore: paziente. Cerca specialisti per città, specializzazione o nome.
- AC: filtri combinabili · lista con nome, specializzazione, città · CTA "Richiedi collegamento" (→RF14) · esclude gli specialisti già collegati o con richiesta pendente · mostra solo specialisti **verificati** (ADR-0028).
- DB: `specialista`, `profilo_utente`, `richiesta_collegamento`. Dip.: RF3 (come paziente).

### RF14 — Invio richiesta di collegamento
Attore: paziente.
- AC: messaggio opzionale · il re-invio dopo un rifiuto è un **upsert** sulla UNIQUE (riporta la riga a "In Attesa", azzera `DataRisposta`/`MotivazioneRifiuto`), non un secondo INSERT — evita il `23505` (ADR-0023).
- DB: `richiesta_collegamento`. Dip.: RF13.

### RF15 — Visualizzazione richieste ricevute
Attore: specialista. Lista delle richieste in attesa.
- AC: filtra lo stato "In Attesa" · mostra nome paziente, età, messaggio, data, più recenti prima · pull-to-refresh.
- DB: `richiesta_collegamento`, `paziente`, `profilo_utente`. Dip.: RF14.

### RF16 — Accettazione richiesta
Attore: specialista. Accetta → crea il fascicolo clinico.
- AC: il client fa solo l'UPDATE a "Accettata"; il fascicolo lo crea il trigger `crea_fascicolo_da_richiesta`, `SECURITY DEFINER` per poter scrivere dove lo specialista non è ancora titolare (ADR-0023) · il paziente compare in "Pazienti collegati" (RF18).
- DB: `richiesta_collegamento`, `fascicoloclinico`. Dip.: RF15.

### RF17 — Rifiuto richiesta con motivazione
Attore: specialista.
- AC: motivazione opzionale · UPDATE a "Rifiutata" con `MotivazioneRifiuto` · scompare dalla lista in attesa.
- DB: `richiesta_collegamento`. Dip.: RF15.

### RF18 — Lista pazienti collegati
Attore: specialista. Elenco dei pazienti a fascicolo attivo.
- AC: query `fascicoloclinico` con lo specialista corrente e stato attivo · card con nome ed età · tap → RF19.
- DB: `fascicoloclinico`, `paziente`, `profilo_utente`. Dip.: RF16.

### RF19 — Consultazione diario paziente (specialista)
Attore: specialista. Vista **read-only** del diario di un paziente collegato.
- AC: UI come RF11 ma senza alcun CRUD (nessun FAB/menu/azione) · le RLS autorizzano solo i pazienti con fascicolo attivo · banner "Stai visualizzando il diario di <nome>" · riusa `DiaryRepository`/`SymptomRepository` parametrici (ADR-0016).
- DB: `pasto`, `alimento_pasto`, `alimento`, `sintomo`, `fascicoloclinico`. Dip.: RF18.

### RF20 — Filtri per periodo e nutriente
Attore: specialista (in RF19). Filtra per intervallo di date e per nutriente.
- AC: range di date (oggi / 7 / 30 giorni / personalizzato) con cap a **92 giorni** lato client (ADR-0017) · filtro nutriente (lattosio/sorbitolo/glutine) come **evidenziazione**, non come soglia rigida · nessun export CSV (fuori scope).
- DB: `pasto`, `alimento_pasto`, `sintomo`. Dip.: RF19.

---

## Fuori scope nel porting

Presenti nell'app Android nativa, **non portati** qui (vedi `README.md` e gli ADR relativi):

- **RF21 — Dashboard statistiche paziente** (BMI, grafico nutrienti, frequenza sintomi). La `PatientDiaryScreen` resta sola lettura senza grafici. ADR-0018.
- **RF22 — Promemoria del diario** (notifiche locali ricorrenti). Nessuno scheduler. ADR-0019/0025/0030.
- **RF23 / RF24 — Chat paziente ↔ specialista** (invio e ricezione real-time). Nessun canale Realtime né schermata chat. ADR-0020.

---

## Note trasversali

- Sicurezza: le query sensibili sono protette da RLS; gli UseCase non disabilitano mai le policy. Il backend è invariato e usato in sola lettura.
- Localizzazione: testo UI in italiano via `ItStrings` (ADR-0011); i widget Material sono forzati a locale `it`.
- Accessibilità: `semanticLabel`/`Semantics` sulle icone e sui controlli principali.
- Offline: RF11 funziona in lettura parziale offline grazie alla cache `sqflite` (ADR-FL-1); le scritture restano online-only.
