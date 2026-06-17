import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/diary/add_meal_screen.dart';
import '../screens/diary/add_symptom_screen.dart';
import '../screens/diary/diary_screen.dart';
import '../screens/home/patient_home_screen.dart';
import '../screens/home/specialist_home_screen.dart';
import '../screens/linkedpatients/linked_patients_screen.dart';
import '../screens/patientdiary/patient_diary_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/requests/link_requests_screen.dart';
import '../screens/specialists/specialists_screen.dart';
import '../screens/splash/splash_screen.dart';
import 'routes.dart';

/// Rotte pubbliche raggiungibili senza una sessione autenticata.
const Set<String> _publicRoutes = {Routes.login, Routes.register};

/// Osserva le transizioni di rotta così le schermate possono ricaricarsi quando
/// tornano in focus (equivalente ADR-0014): `DiaryScreen` ricarica in
/// `didPopNext()` dopo il pop delle schermate di aggiunta/modifica, senza
/// affidarsi a un risultato di navigazione.
final RouteObserver<PageRoute<dynamic>> diaryRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

/// Decisione pura di auth-gating (ADR-0021), estratta per testabilità.
///
/// Restituisce il path verso cui redirigere, o `null` per restare su [location].
/// - lo splash risolve da sé la destinazione via `RootViewModel` → mai rediretto.
/// - il reset-password guida il proprio flusso (a metà compare una sessione di
///   recupero transitoria) → mai rediretto.
/// - utente sloggato su una rotta protetta → login.
/// - utente loggato su una rotta pubblica → splash, che ri-risolve il ruolo e
///   inoltra alla home corretta (il redirect non può interrogare il ruolo da sé).
String? resolveRedirect({
  required bool isLoggedIn,
  required String location,
}) {
  if (location == Routes.splash || location == Routes.resetPassword) return null;

  final isPublic = _publicRoutes.contains(location);
  if (!isLoggedIn && !isPublic) return Routes.login;
  if (isLoggedIn && isPublic) return Routes.splash;
  return null;
}

/// Costruisce il router dell'app con un redirect protetto da auth.
///
/// Va chiamato dopo `initSupabase()`: legge la sessione viva e ascolta
/// `onAuthStateChange` così login/logout redirigono senza riavviare l'app.
GoRouter createAppRouter() {
  final auth = Supabase.instance.client.auth;
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: _AuthRefreshNotifier(auth.onAuthStateChange),
    observers: [diaryRouteObserver],
    redirect: (context, state) => resolveRedirect(
      isLoggedIn: auth.currentSession != null,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: Routes.patientHome,
        builder: (context, state) => const PatientHomeScreen(),
      ),
      GoRoute(
        path: Routes.specialistHome,
        builder: (context, state) => const SpecialistHomeScreen(),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: Routes.resetPassword,
        builder: (context, state) => ResetPasswordScreen(
          email: state.uri.queryParameters['email'] ?? '',
        ),
      ),
      GoRoute(
        path: Routes.addMeal,
        builder: (context, state) {
          // `meal_id` > 0 mette la schermata in modalità modifica (ADR-0013).
          final mealId =
              int.tryParse(state.uri.queryParameters['meal_id'] ?? '');
          final date =
              DateTime.tryParse(state.uri.queryParameters['date'] ?? '');
          return AddMealScreen(mealId: mealId, initialDate: date);
        },
      ),
      GoRoute(
        path: Routes.diary,
        builder: (context, state) {
          final date =
              DateTime.tryParse(state.uri.queryParameters['date'] ?? '');
          return DiaryScreen(initialDate: date);
        },
      ),
      GoRoute(
        path: Routes.addSymptom,
        builder: (context, state) {
          // `symptom_id` > 0 mette la schermata in modalità modifica (ADR-0013).
          final symptomId =
              int.tryParse(state.uri.queryParameters['symptom_id'] ?? '');
          final date =
              DateTime.tryParse(state.uri.queryParameters['date'] ?? '');
          return AddSymptomScreen(symptomId: symptomId, initialDate: date);
        },
      ),
      GoRoute(
        path: Routes.specialists,
        builder: (context, state) => const SpecialistsScreen(),
      ),
      GoRoute(
        path: Routes.linkRequests,
        builder: (context, state) => const LinkRequestsScreen(),
      ),
      GoRoute(
        path: Routes.linkedPatients,
        builder: (context, state) => const LinkedPatientsScreen(),
      ),
      GoRoute(
        path: Routes.patientDiary,
        builder: (context, state) {
          final fascicoloId =
              int.tryParse(state.uri.queryParameters['fascicolo_id'] ?? '');
          final patientName =
              state.uri.queryParameters['patient_name'] ?? '';
          return PatientDiaryScreen(
            fascicoloId: fascicoloId ?? 0,
            patientName: patientName,
          );
        },
      ),
    ],
  );
}

/// Fa da ponte tra lo stream di auth state e un [Listenable] per `refreshListenable`.
class _AuthRefreshNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _subscription;

  _AuthRefreshNotifier(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
