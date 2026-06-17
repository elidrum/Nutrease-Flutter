/// Esegue un'operazione best-effort sulla cache del diario (lettura offline RF11).
///
/// Un cache miss o un errore `sqflite` non deve mai diventare un errore visibile
/// all'utente, quindi ogni eccezione viene ingoiata e si restituisce `null`.
/// Condivisa dai repository di diario e sintomi sia per la scrittura cache-aside
/// sia per la lettura offline.
Future<T?> runCacheOp<T>(Future<T> Function() op) async {
  try {
    return await op();
  } catch (_) {
    return null;
  }
}
