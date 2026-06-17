/// Path delle rotte centralizzati (niente magic string sparse in giro).
///
/// Rispecchia il navigation graph dell'app Android.
abstract final class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String patientHome = '/home';
  static const String specialistHome = '/specialist';
  static const String profile = '/profile';

  /// Completamento del reset password; `?email=` è dove è stato inviato il codice OTP.
  static const String resetPassword = '/reset_password';

  /// Aggiunta/modifica pasto; `?meal_id=` seleziona la modalità modifica
  /// (ADR-0013), `?date=` preimposta la data.
  static const String addMeal = '/add_meal';

  /// Timeline del diario giornaliero (RF11/RF12).
  static const String diary = '/diary';

  /// Aggiunta/modifica sintomo; `?symptom_id=` seleziona la modalità modifica
  /// (ADR-0013), `?date=` preimposta la data.
  static const String addSymptom = '/add_symptom';

  /// Discovery degli specialisti (lato paziente, RF13/RF14).
  static const String specialists = '/specialists';

  /// Inbox delle richieste di collegamento ricevute (lato specialista, RF15–RF17).
  static const String linkRequests = '/link_requests';

  /// Lista dei pazienti collegati dello specialista (RF18).
  static const String linkedPatients = '/linked_patients';

  /// Diario del paziente in sola lettura (lato specialista, RF19/RF20);
  /// `?fascicolo_id=&patient_name=` identificano il paziente.
  static const String patientDiary = '/patient_diary';
}
