# Glossario IT (DB) → EN (domain)

> Tabella di traduzione canonica fra i nomi DB (italiano, PascalCase quotato) e il
> codice Dart in `domain/` (inglese puro). Riferimento per mapper consistenti.
> **Quando leggerlo**: ogni volta che aggiungi un DTO o un domain model, per non
> inventare nomi diversi. **Origine**: ADR-0006. Lo schema è quello dell'app Android
> sorella (`../Nutrease/sql/`, repo: https://github.com/elidrum/Nutrease) e qui non si
> modifica: il porting è read-only sul backend.
> Le entità di chat, promemoria e statistiche sono **fuori scope** nel porting e non
> compaiono qui.

---

## Entità / Tabelle

| DB | Domain (Dart) | Descrizione |
|---|---|---|
| `paziente` | `Patient` | Profilo paziente |
| `specialista` | `Specialist` | Profilo specialista |
| `profilo_utente` | `UserProfile` / `AuthUser` | Lookup auth ↔ ruolo |
| `fascicoloclinico` | `fascicoloId` + `LinkedPatient` | Collegamento attivo paziente ↔ specialista |
| `alimento` | `Food` | Anagrafica alimento |
| `alimento_pasto` | `MealFoodItem` | Voce di pasto (alimento + quantità) |
| `pasto` | `Meal` | Pasto composto |
| `sintomo` | `Symptom` | Sintomo registrato |
| `richiesta_collegamento` | `LinkRequest` / `LinkRequestWithPatient` | Richiesta paziente → specialista |

## Campi comuni

| DB | Domain | Tipo Dart |
|---|---|---|
| `IdAlimento` | `id` | `int` |
| `IdPasto` / `IdFascicolo` | `id` / `fascicoloId` | `int` |
| `auth_uid` | `userId` | `String` (UUID auth) |
| `Nome` | `name` | `String` |
| `Cognome` | `surname` | `String` |
| `Email` | `email` | `String` |
| `CodiceFiscale` / `codice_fiscale` | `taxCode` | `String` |
| `DataNascita` | `birthDate` | `DateTime` (date-only) |
| `Sesso` | `gender` | `Gender` |
| `Altezza` | `heightCm` | `double` |
| `Peso` | `weightKg` | `double` |
| `Categoria` | `category` | `String` |
| `Data` / `Ora` | `date` / `time` | `DateTime` / `String` (`HH:mm:ss`) |

## Campi per feature

**Alimenti / Nutrizione**

| DB | Domain | Unità |
|---|---|---|
| `LattosioP100g` | `lactosePer100g` | g/100g |
| `SorbitoloP100g` | `sorbitolPer100g` | g/100g |
| `GlutineP100g` | `glutenPer100g` | g/100g |
| `CaloriePer100g` | `kcalPer100g` | kcal/100g |
| `ConversioniUnitaMisura` | `unitConversions` | `Map<String,double>` |
| `QuantitaGrammi` | `amountGrams` | grammi |
| `LattosioCalc`/`SorbitoloCalc`/`GlutineCalc`/`CalorieCalc` | `NutrientTotals` | da trigger |
| `Tipologia` | `type` | `MealType` |

**Sintomi**: `Tipologia`→`type` (`SymptomType`) · `Gravita`→`severity` (`SymptomSeverity`).

**Richieste**: `Stato`→`status` (`LinkRequestStatus`) · `MessaggioRichiesta`→`message` (`String?`) · `MotivazioneRifiuto`→`rejectionReason` (`String?`) · `DataRichiesta`/`DataRisposta`→`requestedAt`/`respondedAt` (`DateTime`/`DateTime?`).

**Profilo / Ruoli**: `ruolo`→`role` (`UserRole`).

## ENUM — mapping valori

I domain enum mappano l'etichetta DB italiana (inviata/letta alla lettera) su un nome inglese:

- **`sesso_paziente`/`Gender`**: `M`→`male`, `F`→`female`, `Altro`→`other`.
- **`tipologia_pasto`/`MealType`**: `Colazione`→`breakfast`, `Pranzo`→`lunch`, `Merenda`→`snack`, `Cena`→`dinner`.
- **`ruolo_utente`/`UserRole`**: `paziente`→`patient`, `specialista`→`specialist` (`segretaria` è fuori scope: ruolo non supportato).
- **`stato_richiesta`/`LinkRequestStatus`**: `In Attesa`→`sent`, `Accettata`→`accepted`, `Rifiutata`→`rejected`.
- **specializzazione/`SpecializationType`**: `Nutrizionista`→`nutritionist`, `Dietista`→`dietitian`, `Gastroenterologo`→`gastroenterologist`.
- **`SymptomSeverity`**: `none`/`mild`/`moderate`/`severe`, con intensità 1/3/6/9 per la UI.

## Regole di sicurezza linguistica

1. **Identificatori** in `domain/` sempre in inglese; i **commenti** sono in italiano (convenzione del porting — diversa dall'app Android, che li teneva in inglese).
2. Nei **DTO**: nomi italiani, mappano 1:1 i campi JSON di Supabase.
3. Nei **Mapper**: ogni `toDomain()`/`toDto()` è il punto di traduzione unico.
4. **Stringhe UI** in `ItStrings` (ADR-0011), in italiano.
5. Le etichette degli enum DB (`In Attesa`, `Colazione`, …) si inviano e si leggono **alla lettera**: non vanno tradotte nelle query.

> Se rinomini un campo aggiorna anche i mapper; se aggiungi un enum aggiungi la tabella valori.
