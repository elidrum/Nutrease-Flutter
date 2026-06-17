/// Modello d'errore a livello di dominio.
///
/// Sta in `lib/core/` ma è **senza framework** (niente import Flutter/Supabase/
/// sqflite), così il layer puro `lib/domain/` può dipenderne (ADR-0007). Ogni
/// variante porta un [message] in italiano già pronto da mostrare. Gli errori di
/// auth restano generici per non permettere la user-enumeration (ADR-0012/0024).
sealed class DomainError {
  final String message;
  const DomainError(this.message);
}

class NetworkError extends DomainError {
  const NetworkError([super.message = 'Errore di rete. Riprova.']);
}

/// Errore credenziali generico: non rivela mai quale campo fosse sbagliato.
class AuthError extends DomainError {
  const AuthError([super.message = 'Credenziali non valide.']);
}

class ValidationError extends DomainError {
  const ValidationError(super.message);
}

class NotFoundError extends DomainError {
  const NotFoundError([super.message = 'Elemento non trovato.']);
}

class UnknownError extends DomainError {
  const UnknownError([super.message = 'Si è verificato un errore.']);
}
