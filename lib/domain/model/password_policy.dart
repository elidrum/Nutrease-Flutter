/// Regola di robustezza della password (RF1/RF2/RF6), portata 1:1 dall'app
/// Android: almeno 8 caratteri, una lettera maiuscola e una cifra.
///
/// Pura e senza framework, riusata da registrazione e cambio password.
/// Restituisce un messaggio in italiano pronto da mostrare, o `null` quando la
/// password è valida.
abstract final class PasswordPolicy {
  static const int minLength = 8;

  /// Restituisce il messaggio italiano della prima regola fallita, o `null` se valida.
  static String? validate(String password) {
    if (password.length < minLength) {
      return 'La password deve contenere almeno $minLength caratteri';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'La password deve contenere almeno una lettera maiuscola';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'La password deve contenere almeno una cifra';
    }
    return null;
  }
}
