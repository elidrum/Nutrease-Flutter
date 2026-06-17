import '../../domain/model/symptom.dart';
import '../../domain/model/symptom_severity.dart';
import '../../domain/model/symptom_type.dart';

/// Stringhe UI italiane centralizzate.
///
/// Codice e chiavi in inglese, valori in italiano. Ogni feature aggiunge qui le
/// sue chiavi (o in sezioni dedicate), così le stringhe restano tutte cercabili
/// (grep) in un punto solo.
abstract final class ItStrings {
  // App.
  static const String appTitle = 'Nutrease';
  static const String appSubtitle = 'Diario alimentare e sintomatologico';

  // Azioni generiche.
  static const String retry = 'Riprova';
  static const String back = 'Indietro';
  static const String cancel = 'Annulla';
  static const String confirm = 'Conferma';
  static const String save = 'Salva';

  // Stati generici.
  static const String loadingGeneric = 'Caricamento in corso…';
  static const String emptyGeneric = 'Nessun elemento da mostrare.';
  static const String errorGeneric = 'Si è verificato un errore.';

  // Campi comuni.
  static const String email = 'Email';
  static const String password = 'Password';

  // Errore di configurazione (segreti --dart-define mancanti).
  static const String configErrorTitle = 'Configurazione mancante';
  static const String configErrorBody =
      'Configura SUPABASE_URL e SUPABASE_ANON_KEY con --dart-define '
      'per avviare l\'app.';

  // Accessibilità — label semantiche lette dagli screen reader.
  static const String errorIconLabel = 'Errore';
  static const String configIconLabel = 'Configurazione';
  static const String addFoodIconLabel = 'Aggiungi alimento';
  static const String searchIconLabel = 'Cerca';
  static const String warningIconLabel = 'Avviso';
  static const String specialistIconLabel = 'Specialista';
  static const String findSpecialistIconLabel = 'Cerca specialista';
  static const String entryActionsLabel = 'Azioni';
  static const String patientsIconLabel = 'Pazienti';
  static const String readOnlyIconLabel = 'Sola lettura';
  static const String diaryIconLabel = 'Diario';
  static const String linkRequestsIconLabel = 'Richieste di collegamento';

  // --- Auth: accesso (RF3) ---
  static const String loginTitle = 'Accedi';
  static const String loginButton = 'Accedi';
  static const String forgotPassword = 'Password dimenticata?';
  static const String goToRegister = 'Non hai un account? Registrati';
  static const String passwordResetSent =
      'Email di reimpostazione inviata. Controlla la posta.';
  static const String genericAuthError = 'Credenziali non valide.';

  // --- Auth: registrazione (RF1/RF2) ---
  static const String registerTitle = 'Registrazione';
  static const String tabPatient = 'Paziente';
  static const String tabSpecialist = 'Specialista';
  static const String firstName = 'Nome';
  static const String surname = 'Cognome';
  static const String taxCode = 'Codice fiscale';
  static const String birthDate = 'Data di nascita';
  static const String birthDateHint = 'gg/mm/aaaa';
  static const String gender = 'Sesso';
  static const String genderMale = 'Maschio';
  static const String genderFemale = 'Femmina';
  static const String genderOther = 'Altro';
  static const String vatNumber = 'Partita IVA';
  static const String specialization = 'Specializzazione';
  static const String city = 'Città';
  static const String registerButton = 'Crea account';
  static const String goToLogin = 'Hai già un account? Accedi';

  // Validazione dei campi di registrazione.
  static const String errorFirstNameRequired = 'Inserisci il nome';
  static const String errorSurnameRequired = 'Inserisci il cognome';
  static const String errorTaxCodeLength =
      'Il codice fiscale deve essere di 16 caratteri';
  static const String errorEmailInvalid = 'Inserisci un\'email valida';
  static const String errorVatNumberLength =
      'La partita IVA deve essere di 11 cifre';
  static const String errorCityRequired = 'Inserisci la città';
  static const String errorBirthDateInvalid =
      'Inserisci una data di nascita valida';
  static const String errorGenderRequired = 'Seleziona il sesso';
  static const String errorSpecializationRequired =
      'Seleziona la specializzazione';

  // --- Profilo (RF4–RF7) ---
  static const String profileTitle = 'Profilo';
  static const String editProfile = 'Modifica profilo';
  static const String changePasswordTitle = 'Cambia password';
  static const String currentPassword = 'Password attuale';
  static const String newPassword = 'Nuova password';
  static const String deleteAccountTitle = 'Elimina account';
  static const String deleteAccountWarning =
      'Questa azione è irreversibile. Inserisci la password per confermare '
      'l\'eliminazione dell\'account.';
  static const String logout = 'Esci';
  static const String profileUpdated = 'Profilo aggiornato';
  static const String passwordUpdated = 'Password aggiornata';
  static const String delete = 'Elimina';

  // --- Auth: completamento reset password (codice OTP) ---
  static const String resetPasswordTitle = 'Reimposta password';
  static const String resetCodeLabel = 'Codice (8 cifre)';
  static const String confirmPassword = 'Conferma password';
  static const String resetPasswordButton = 'Reimposta password';
  static const String passwordResetDone =
      'Password reimpostata. Accedi con la nuova password.';
  static const String errorPasswordsMismatch = 'Le password non coincidono.';
  static const String showPassword = 'Mostra password';
  static const String hidePassword = 'Nascondi password';

  /// Intro nella schermata di reset; [email] è l'indirizzo a cui è stato inviato
  /// il codice OTP.
  static String resetPasswordIntro(String email) =>
      'Inserisci il codice a 8 cifre inviato a $email e scegli una nuova '
      'password.';

  // --- Diario: aggiungi/modifica pasto (RF8/RF9) ---
  static const String addMealTitle = 'Aggiungi pasto';
  static const String editMealTitle = 'Modifica pasto';
  static const String mealType = 'Tipo pasto';
  static const String searchFoodHint = 'Cerca un alimento…';
  static const String noFoodsFound = 'Nessun alimento trovato…';
  static const String quantity = 'Quantità';
  static const String unit = 'Unità';
  static const String selectedFoods = 'Alimenti del pasto';
  static const String noSelectedFoods =
      'Nessun alimento aggiunto. Cerca un alimento per iniziare.';
  static const String saveMeal = 'Salva pasto';
  static const String mealSaved = 'Pasto registrato';
  static const String add = 'Aggiungi';
  static const String remove = 'Rimuovi';
  static const String errorQuantityPositive =
      'Inserisci una quantità maggiore di zero';
  static const String errorFutureMealDate =
      'Non puoi aggiungere un pasto in una data futura';

  /// Anteprima della conversione in grammi, es. "= 30 g".
  static String gramsPreview(String grams) => '= $grams g';

  // --- Home (shell per ruolo) ---
  static const String patientHomeTitle = 'Home';
  static const String specialistHomeTitle = 'Home';
  static const String profileAction = 'Profilo';

  // Sottotitolo sotto il saluto (parità con Android).
  static const String patientHomeSubtitle =
      'Tieni traccia di pasti e sintomi ogni giorno';
  static const String specialistHomeSubtitle =
      'Gestisci i tuoi pazienti e le loro richieste';

  /// Saluto nelle home; [name] è il nome dell'utente.
  static String greeting(String name) => 'Ciao, $name';

  // --- Timeline diario (RF11/RF12) ---
  static const String diaryTitle = 'Diario alimentare';
  static const String diaryAction = 'Diario alimentare';
  static const String diarySubtitle = 'Consulta i pasti e i sintomi della giornata';
  static const String diaryEmpty =
      'Nessuna voce per questa giornata. Tocca + per aggiungere un pasto o un sintomo';
  static const String diaryAddEntry = 'Aggiungi voce';
  static const String diaryAddMeal = 'Aggiungi pasto';
  static const String diaryAddSymptom = 'Aggiungi sintomo';
  static const String diaryToday = 'Oggi';
  static const String diaryPreviousDay = 'Giorno precedente';
  static const String diaryNextDay = 'Giorno successivo';
  static const String diaryPickDate = 'Scegli data';
  static const String diaryDailyTotals = 'Totali del giorno';
  static const String edit = 'Modifica';
  static const String mealDeleted = 'Pasto eliminato';
  static const String symptomDeleted = 'Sintomo eliminato';
  static const String confirmDeleteTitle = 'Conferma eliminazione';
  static const String confirmDeleteMeal =
      'Vuoi eliminare questo pasto? L\'operazione è irreversibile.';
  static const String confirmDeleteSymptom =
      'Vuoi eliminare questo sintomo? L\'operazione è irreversibile.';
  static const String offlineDetailUnavailable =
      'Dettaglio alimenti non disponibile offline';

  /// Riga dei totali nutrienti su una card pasto, es. "Lattosio 1.2 g · …".
  static String mealTotalsLine({
    required String lactose,
    required String sorbitol,
    required String gluten,
    required String kcal,
  }) =>
      'Lattosio $lactose g · Sorbitolo $sorbitol g · Glutine $gluten g · $kcal kcal';

  // --- Aggiungi/modifica sintomo (RF10) ---
  static const String addSymptomTitle = 'Aggiungi sintomo';
  static const String editSymptomTitle = 'Modifica sintomo';
  static const String symptomType = 'Tipo di sintomo';
  static const String symptomSeverity = 'Severità';

  // Label data/ora condivise (form pasto + sintomo).
  static const String dateTimeLabel = 'Data e ora'; // intestazione di sezione
  static const String dateLabel = 'Data'; // prefisso del bottone data
  static const String timeLabel = 'Ora'; // prefisso del bottone ora
  static const String saveSymptom = 'Salva sintomo';
  static const String symptomSaved = 'Sintomo registrato';

  // Tipo a testo libero, mostrato quando si seleziona "Altro".
  static const String symptomOtherFieldLabel = 'Specifica il sintomo';
  static const String errorSymptomOtherRequired =
      'Specifica il tipo di sintomo';
  static const String errorFutureSymptomDate =
      'Non puoi aggiungere un sintomo in una data futura';

  /// Cosa mostrare per il tipo di un sintomo: il testo libero del paziente per
  /// "Altro" (così lo specialista lo legge), altrimenti la [symptomTypeLabel] fissa.
  static String symptomDisplayLabel(Symptom symptom) {
    final custom = symptom.otherDescription?.trim() ?? '';
    if (symptom.type == SymptomType.other && custom.isNotEmpty) return custom;
    return symptomTypeLabel(symptom.type);
  }

  /// Etichetta italiana per un [SymptomType] (coincide con la `Descrizione` persistita).
  static String symptomTypeLabel(SymptomType type) => switch (type) {
        SymptomType.bloating => 'Gonfiore',
        SymptomType.cramps => 'Crampi',
        SymptomType.diarrhea => 'Diarrea',
        SymptomType.constipation => 'Stitichezza',
        SymptomType.nausea => 'Nausea',
        SymptomType.reflux => 'Reflusso',
        SymptomType.other => 'Altro',
      };

  /// Etichetta italiana per un livello [SymptomSeverity].
  static String severityLabel(SymptomSeverity severity) => switch (severity) {
        SymptomSeverity.none => 'Assente',
        SymptomSeverity.mild => 'Lieve',
        SymptomSeverity.moderate => 'Moderata',
        SymptomSeverity.severe => 'Grave',
      };

  // --- Ricerca specialisti (RF13) + richiesta di collegamento (RF14) ---
  static const String specialistsTitle = 'Trova specialista';
  static const String findSpecialistAction = 'Trova specialista';
  static const String findSpecialistSubtitle =
      'Cerca e collegati a un professionista';
  static const String specialistSearchHint = 'Cerca per nome o cognome…';
  static const String specializationFilter = 'Specializzazione';
  static const String specializationAll = 'Tutte';
  static const String cityFilter = 'Città';
  static const String specialistsEmpty = 'Nessuno specialista trovato';
  static const String requestLinkAction = 'Richiedi collegamento';
  static const String sendLinkRequestTitle = 'Richiesta di collegamento';
  static const String linkRequestMessageHint = 'Messaggio (facoltativo)';
  static const String sendAction = 'Invia';
  static const String linkRequestSent = 'Richiesta inviata';

  // --- Home paziente: card dello specialista collegato (delta Android 2026-06-12) ---
  static const String patientHomeLinkedSpecialistLabel = 'Il tuo specialista';
  static const String patientHomeNoSpecialistTitle =
      'Nessuno specialista collegato';
  static const String patientHomeNoSpecialistSubtitle =
      'Cerca un professionista e invia una richiesta di collegamento';

  /// Banner di avviso sostituzione nella ricerca; [name] è lo specialista attuale.
  static String specialistsAlreadyLinkedWarning(String name) =>
      'Sei già collegato a $name: se un nuovo specialista accetta la tua '
      'richiesta, sostituirà il collegamento attuale.';

  /// Riga di avviso sostituzione dentro il dialog di invio richiesta.
  static String sendLinkRequestReplaceWarning(String name) =>
      'Sei già collegato a $name: questa richiesta, se accettata, sostituirà '
      'il collegamento attuale.';

  // --- Inbox specialista: richieste di collegamento ricevute (RF15–RF17) ---
  static const String linkRequestsTitle = 'Richieste di collegamento';
  static const String linkRequestsAction = 'Richieste di collegamento';
  static const String linkRequestsSubtitle =
      'Accetta o rifiuta le richieste in attesa';
  static const String linkRequestsEmpty = 'Nessuna richiesta in attesa';
  static const String acceptAction = 'Accetta';
  static const String rejectAction = 'Rifiuta';
  static const String rejectLinkRequestTitle = 'Rifiuta richiesta';
  static const String rejectReasonHint = 'Motivazione (obbligatoria)';
  static const String linkRequestAccepted = 'Richiesta accettata';
  static const String linkRequestRejected = 'Richiesta rifiutata';
  static const String linkRequestActionError =
      'Operazione non riuscita. Riprova.';
  static const String noMessage = 'Nessun messaggio';

  // --- Specialista: lista pazienti collegati (RF18) ---
  static const String linkedPatientsTitle = 'I miei pazienti';
  static const String linkedPatientsAction = 'I miei pazienti';
  static const String linkedPatientsSubtitle =
      'Consulta i diari dei pazienti collegati';
  static const String linkedPatientsEmpty = 'Nessun paziente collegato';

  /// Riga età del paziente su una card paziente collegato, es. "34 anni".
  static String patientAgeYears(int years) => '$years anni';

  // --- Specialista: diario paziente in sola lettura (RF19/RF20) ---
  /// Titolo dell'app-bar col nome del paziente di cui si mostra il diario.
  static String patientDiaryTitle(String name) => 'Diario di $name';
  static const String patientDiaryEmpty =
      'Nessuna voce nel periodo selezionato.';

  // Chip filtro periodo (RF20).
  static const String periodFilterLabel = 'Periodo';
  static const String periodToday = 'Oggi';
  static const String periodLast7 = 'Ultimi 7 giorni';
  static const String periodLast30 = 'Ultimi 30 giorni';
  static const String periodCustom = 'Personalizzato';

  // Chip evidenziazione nutrienti (RF20): solo evidenziazione, mai un filtro vero.
  static const String nutrientFilterLabel = 'Nutriente';
  static const String nutrientAll = 'Tutti';
  static const String nutrientLactose = 'Lattosio';
  static const String nutrientSorbitol = 'Sorbitolo';
  static const String nutrientGluten = 'Glutine';
  static const String nutrientKcal = 'Calorie';
}
