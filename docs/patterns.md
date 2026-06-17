# Pattern ricorrenti — Nutrease Flutter

> Catalogo dei pattern Dart/Flutter del progetto con esempi minimi.
> **Quando leggerlo**: prima di scrivere un nuovo ViewModel, Repository o schermata.
> Aggiornare quando si introduce o si abbandona un pattern. Sono la traduzione Flutter
> dei pattern Kotlin/Compose dell'app Android (https://github.com/elidrum/Nutrease).

---

## 1. ChangeNotifier + Future

Dove: tutti i ViewModel. È l'equivalente Flutter dello `StateFlow` + coroutine dell'app
Android: un `ChangeNotifier` tiene lo stato, lo aggiorna dentro un metodo `async` e chiama
`notifyListeners()`.

Flusso: il widget osserva il ViewModel con `provider` (`context.watch`/`Consumer`); il metodo
`async` chiama lo UseCase (che ritorna un `Future`), che chiama il RepositoryImpl, che chiama
`supabase_flutter`. L'`await` sospende senza bloccare il thread della UI.

```dart
Future<void> login(String email, String password) async {
  _state = _state.copyWith(isLoading: true);
  notifyListeners();
  final result = await _loginUseCase(email, password);
  _state = result.fold(
    ok: (user) => _state.copyWith(isLoading: false, navigateTo: user.role),
    err: (e) => _state.copyWith(isLoading: false, error: e.message),
  );
  notifyListeners();
}
```

## 2. UiState come oggetto immutabile

Dove: ogni schermata ha il proprio `XxxUiState` con tutti i campi per il render (loading,
errore, dati, eventi di navigazione). Le modifiche passano sempre per `copyWith`, mai per
assegnazione campo a campo, così lo stato resta coerente.

```dart
@immutable
class LoginUiState {
  final bool isLoading;
  final String? error;
  final UserRole? navigateTo; // null = nessuna navigazione pendente
  const LoginUiState({this.isLoading = false, this.error, this.navigateTo});
  LoginUiState copyWith({/* ... */}) => /* ... */;
}
```

## 3. Widget stateless + state hoisting

Dove: ogni schermata separa la parte che prende il ViewModel (osserva lo stato e delega) da
una parte stateless che riceve `UiState` e callback, senza logica. È l'equivalente del
"Composable stateless" Android.

```dart
class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return _LoginView(state: vm.state, onLogin: vm.login);
  }
}
```

## 4. Effetti one-shot (navigazione, snackbar)

Dove: navigazione dopo login/registrazione, messaggi di esito. Il ViewModel espone un campo
"evento" nello `UiState` (es. `navigateTo`) che il widget consuma una volta e poi il ViewModel
azzera, così l'effetto non si ripete a ogni rebuild. Per gli snackbar globali si usa il
`rootScaffoldMessengerKey` (`core/app_scaffold_messenger.dart`), indipendente dal `context`
della schermata. È l'equivalente del `LaunchedEffect` Android.

## 5. Async nei Repository + lavoro pesante in isolate

Dove: tutti i metodi Repository sono `async` e ritornano `Future<Result<T>>`. Dart è
single-thread: l'I/O è già non bloccante, ma il lavoro CPU pesante va spostato in un isolate.
È il caso del parsing delle 1.388 voci di `alimento`, fatto con `compute` (ADR-0029), l'analogo
del `withContext(Dispatchers.IO)` Android per i carichi pesanti.

## 6. `try/catch` + `Result<T>` per l'error handling

Dove: metodi Repository che ritornano `Result<T>`. L'eccezione Supabase/trasporto è tradotta
in un `DomainError` da `mapSupabaseError`, così l'errore arriva in UI già come messaggio
italiano e generico (anti user-enumeration sull'auth, ADR-0024).

```dart
try {
  final row = await _client.from('profilo_utente').select(/* ... */).single();
  return Ok(/* ... */);
} catch (e) {
  return Err(mapSupabaseError(e));
}
```
Il ViewModel consuma con `result.fold(ok: ..., err: ...)`. Per lo stato continuo si usa
`Resource<T>` (ADR-0012).

## 7. Dependency injection con `provider`

Dove: `core/di/app_providers.dart`. La composition root registra `SupabaseClient`, i Repository
e gli UseCase come `Provider` singleton; i ViewModel sono creati per-schermata via
`ChangeNotifierProvider` nel builder della rotta. Niente generatore di codice (al posto di
Hilt). Regola: non istanziare mai Repository o UseCase fuori dalla composition root.
