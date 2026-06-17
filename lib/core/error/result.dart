import 'domain_error.dart';

/// Esito one-shot per le chiamate a Repository/UseCase, senza stato continuo.
///
/// Senza framework (dipende solo da [DomainError]), così lo usa anche il layer
/// di dominio puro (ADR-0007).
sealed class Result<T> {
  const Result();

  /// Instrada su [ok] in caso di successo, su [err] in caso di errore.
  R fold<R>({
    required R Function(T value) ok,
    required R Function(DomainError error) err,
  });
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);

  @override
  R fold<R>({
    required R Function(T value) ok,
    required R Function(DomainError error) err,
  }) =>
      ok(value);
}

class Err<T> extends Result<T> {
  final DomainError error;
  const Err(this.error);

  @override
  R fold<R>({
    required R Function(T value) ok,
    required R Function(DomainError error) err,
  }) =>
      err(error);
}

/// Stato continuo della UI per un flusso dati asincrono (loading/success/error).
///
/// Portato da ADR-0012. Consumato da `AsyncValueView`.
sealed class Resource<T> {
  const Resource();
}

class Loading<T> extends Resource<T> {
  const Loading();
}

class Success<T> extends Resource<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Resource<T> {
  final DomainError error;
  const Failure(this.error);
}
