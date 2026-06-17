# Nutrease Flutter — script di demo end-to-end

Percorso riproducibile che tocca tutte le feature portate (RF1–RF20), con due
account: un **paziente** e uno **specialista**. Pensato per la demo della tesi e
per il QA manuale.

## Prerequisiti

- App avviata con i segreti Supabase (`flutter run --dart-define-from-file=env.json`,
  vedi `README.md`).
- Schema + dataset alimenti caricati sul progetto Supabase.
- Uno specialista **verificato** (`specialista."Verificato" = true`; in MVP si
  approva dal Dashboard Supabase, ADR-0028). Senza verifica non è discoverable e
  non può accettare richieste.
- Consiglio: due dispositivi/emulatori (o due sessioni) per vedere i due ruoli in
  parallelo. In alternativa, fai logout/login tra i passi.

## Parte 1 — Paziente

1. **Registrazione (RF1/RF2)** — dalla schermata di login, "Registrati". Tab
   *Paziente*: nome, cognome, codice fiscale (16 caratteri), email, password
   (≥8, una maiuscola, una cifra), data di nascita (≥18 anni), sesso. Crea
   account → si entra nella home paziente.
2. **Auto-login (RF3)** — chiudi e riapri l'app: parte dallo splash e instrada
   direttamente alla home paziente (sessione persistente).
3. **Profilo (RF4–RF7)** — dalla home, "Profilo": modifica i dati, prova "Cambia
   password" (richiede la password attuale) e prendi nota di "Elimina account"
   (irreversibile, richiede password). *Non* eliminare ora.
4. **Diario — pasto (RF8/RF9)** — dalla home, "Diario" → FAB → "Aggiungi pasto".
   Cerca un alimento (la ricerca tollera i typo), aggiungilo scegliendo unità e
   quantità (anteprima in grammi), ripeti per più alimenti, scegli il tipo pasto
   e salva. Il pasto compare nella timeline del giorno coi nutrienti calcolati.
5. **Diario — sintomo (RF10)** — FAB → "Aggiungi sintomo": tipo (es. Gonfiore) e
   severità (es. Moderata), salva. Compare nella timeline, ordinato per ora.
6. **Timeline e modifica (RF11/RF12)** — naviga tra le date; apri una voce per
   modificarla, oppure swipe / menu "…" per eliminarla (con conferma).
7. **Discovery + richiesta (RF13/RF14)** — dalla home, "Trova specialista":
   filtra per nome, specializzazione, città. Apri una card → "Richiedi
   collegamento" con un messaggio facoltativo. La card sparisce (richiesta in
   attesa). La home mostra "Nessuno specialista collegato" finché non viene
   accettata.

## Parte 2 — Specialista

8. **Login (RF3)** — accedi con l'account specialista (verificato).
9. **Inbox richieste (RF15)** — home → "Richieste di collegamento" (badge col
   conteggio): vedi la richiesta del paziente con nome e data.
10. **Accetta / rifiuta (RF16/RF17)** — "Accetta" crea il collegamento (fascicolo
    attivo, via trigger DB). In alternativa "Rifiuta" richiede una motivazione
    obbligatoria. Accetta la richiesta della demo.
11. **I miei pazienti (RF18)** — home → "I miei pazienti": il paziente collegato
    compare nella lista (nome ed eventuale età), ordinato per cognome.
12. **Diario read-only (RF19)** — tocca il paziente: si apre il suo diario in
    **sola lettura** (banner "Stai visualizzando il diario di … (sola lettura)",
    nessun FAB né azioni di modifica). Vedi i pasti e i sintomi registrati nella
    Parte 1.
13. **Filtro periodo (RF20)** — chip *Oggi / Ultimi 7 giorni / Ultimi 30 giorni /
    Personalizzato*. Con "Personalizzato" scegli un intervallo dal date-range
    picker. Se superi i **92 giorni** compare un messaggio d'errore e nessuna
    query "esplosiva" parte (cap ADR-0017).
14. **Filtro nutriente (RF20)** — chip *Tutti / Lattosio / Sorbitolo / Glutine /
    Calorie*: il valore selezionato viene **evidenziato** nelle card e
    nell'aggregato giornaliero, **senza** filtrare via le voci (la lista resta
    intera). Cambiare nutriente è solo stato UI: nessun nuovo fetch.

## Verifica incrociata

- Il diario read-only dello specialista mostra le **stesse** voci inserite dal
  paziente (riuso dei repository del diario, nessuna duplicazione).
- Lo specialista non vede diari di pazienti non collegati (RLS).
- Tornando paziente, "Il tuo specialista" in home mostra ora lo specialista
  collegato; una nuova richiesta accettata da un altro specialista **sostituisce**
  il collegamento (avviso in discovery).
