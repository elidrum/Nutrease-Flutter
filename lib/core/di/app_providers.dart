import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/local/diary_cache_dao.dart';
import '../../data/repository/auth_repository_impl.dart';
import '../../data/repository/diary_repository_impl.dart';
import '../../data/repository/food_repository_impl.dart';
import '../../data/repository/link_request_repository_impl.dart';
import '../../data/repository/linked_patients_repository_impl.dart';
import '../../data/repository/patient_clinical_file_repository_impl.dart';
import '../../data/repository/specialist_directory_repository_impl.dart';
import '../../data/repository/symptom_repository_impl.dart';
import '../../data/repository/user_repository_impl.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/repository/diary_repository.dart';
import '../../domain/repository/food_repository.dart';
import '../../domain/repository/link_request_repository.dart';
import '../../domain/repository/linked_patients_repository.dart';
import '../../domain/repository/patient_clinical_file_repository.dart';
import '../../domain/repository/specialist_directory_repository.dart';
import '../../domain/repository/symptom_repository.dart';
import '../../domain/repository/user_repository.dart';
import '../../domain/usecase/accept_link_request_use_case.dart';
import '../../domain/usecase/add_meal_use_case.dart';
import '../../domain/usecase/add_symptom_use_case.dart';
import '../../domain/usecase/change_password_use_case.dart';
import '../../domain/usecase/delete_account_use_case.dart';
import '../../domain/usecase/delete_meal_use_case.dart';
import '../../domain/usecase/delete_symptom_use_case.dart';
import '../../domain/usecase/get_daily_diary_use_case.dart';
import '../../domain/usecase/get_excluded_specialist_tax_codes_use_case.dart';
import '../../domain/usecase/get_linked_patients_use_case.dart';
import '../../domain/usecase/get_linked_specialist_use_case.dart';
import '../../domain/usecase/get_meal_use_case.dart';
import '../../domain/usecase/get_meals_for_date_use_case.dart';
import '../../domain/usecase/get_patient_diary_range_use_case.dart';
import '../../domain/usecase/get_patient_fascicolo_use_case.dart';
import '../../domain/usecase/get_profile_use_case.dart';
import '../../domain/usecase/get_received_link_requests_use_case.dart';
import '../../domain/usecase/get_symptom_use_case.dart';
import '../../domain/usecase/get_symptoms_for_date_use_case.dart';
import '../../domain/usecase/login_use_case.dart';
import '../../domain/usecase/logout_use_case.dart';
import '../../domain/usecase/register_use_case.dart';
import '../../domain/usecase/reject_link_request_use_case.dart';
import '../../domain/usecase/reset_password_use_case.dart';
import '../../domain/usecase/search_foods_use_case.dart';
import '../../domain/usecase/search_specialists_use_case.dart';
import '../../domain/usecase/send_link_request_use_case.dart';
import '../../domain/usecase/send_password_reset_use_case.dart';
import '../../domain/usecase/update_meal_use_case.dart';
import '../../domain/usecase/update_patient_use_case.dart';
import '../../domain/usecase/update_specialist_use_case.dart';
import '../../domain/usecase/update_symptom_use_case.dart';
import '../config/supabase_init.dart';

/// Composition root: registra le dipendenze condivise a livello globale.
///
/// Repository e UseCase sono singleton via `Provider`; i ViewModel nascono per
/// schermata con `ChangeNotifierProvider` nel builder di ciascuna.
List<SingleChildWidget> buildAppProviders() {
  return [
    Provider<SupabaseClient>(create: (_) => supabase),
    // Repository.
    Provider<AuthRepository>(
      create: (ctx) => AuthRepositoryImpl(ctx.read<SupabaseClient>()),
    ),
    Provider<UserRepository>(
      create: (ctx) => UserRepositoryImpl(ctx.read<SupabaseClient>()),
    ),
    // Singleton voluto: possiede la cache in memoria del dataset `alimento`.
    Provider<FoodRepository>(
      create: (ctx) => FoodRepositoryImpl(ctx.read<SupabaseClient>()),
    ),
    // Singleton: possiede la cache `sqflite` del diario, aperta lazy (RF11 offline).
    Provider<DiaryCacheDao>(create: (_) => DiaryCacheDao()),
    Provider<DiaryRepository>(
      create: (ctx) => DiaryRepositoryImpl(
          ctx.read<SupabaseClient>(), ctx.read<DiaryCacheDao>()),
    ),
    Provider<SymptomRepository>(
      create: (ctx) => SymptomRepositoryImpl(
          ctx.read<SupabaseClient>(), ctx.read<DiaryCacheDao>()),
    ),
    Provider<PatientClinicalFileRepository>(
      create: (ctx) =>
          PatientClinicalFileRepositoryImpl(ctx.read<SupabaseClient>()),
    ),
    Provider<SpecialistDirectoryRepository>(
      create: (ctx) =>
          SpecialistDirectoryRepositoryImpl(ctx.read<SupabaseClient>()),
    ),
    Provider<LinkRequestRepository>(
      create: (ctx) => LinkRequestRepositoryImpl(ctx.read<SupabaseClient>()),
    ),
    Provider<LinkedPatientsRepository>(
      create: (ctx) => LinkedPatientsRepositoryImpl(ctx.read<SupabaseClient>()),
    ),
    // UseCase.
    Provider<LoginUseCase>(
      create: (ctx) => LoginUseCase(ctx.read<AuthRepository>()),
    ),
    Provider<RegisterUseCase>(
      create: (ctx) => RegisterUseCase(ctx.read<AuthRepository>()),
    ),
    Provider<LogoutUseCase>(
      create: (ctx) => LogoutUseCase(ctx.read<AuthRepository>()),
    ),
    Provider<SendPasswordResetUseCase>(
      create: (ctx) => SendPasswordResetUseCase(ctx.read<AuthRepository>()),
    ),
    Provider<ResetPasswordUseCase>(
      create: (ctx) => ResetPasswordUseCase(ctx.read<AuthRepository>()),
    ),
    Provider<ChangePasswordUseCase>(
      create: (ctx) => ChangePasswordUseCase(ctx.read<AuthRepository>()),
    ),
    Provider<DeleteAccountUseCase>(
      create: (ctx) => DeleteAccountUseCase(ctx.read<AuthRepository>()),
    ),
    Provider<GetProfileUseCase>(
      create: (ctx) => GetProfileUseCase(ctx.read<UserRepository>()),
    ),
    Provider<UpdatePatientUseCase>(
      create: (ctx) => UpdatePatientUseCase(ctx.read<UserRepository>()),
    ),
    Provider<UpdateSpecialistUseCase>(
      create: (ctx) => UpdateSpecialistUseCase(ctx.read<UserRepository>()),
    ),
    Provider<SearchFoodsUseCase>(
      create: (ctx) => SearchFoodsUseCase(ctx.read<FoodRepository>()),
    ),
    Provider<AddMealUseCase>(
      create: (ctx) => AddMealUseCase(ctx.read<DiaryRepository>()),
    ),
    Provider<UpdateMealUseCase>(
      create: (ctx) => UpdateMealUseCase(ctx.read<DiaryRepository>()),
    ),
    Provider<GetMealUseCase>(
      create: (ctx) => GetMealUseCase(ctx.read<DiaryRepository>()),
    ),
    Provider<GetMealsForDateUseCase>(
      create: (ctx) => GetMealsForDateUseCase(ctx.read<DiaryRepository>()),
    ),
    Provider<DeleteMealUseCase>(
      create: (ctx) => DeleteMealUseCase(ctx.read<DiaryRepository>()),
    ),
    Provider<GetPatientFascicoloUseCase>(
      create: (ctx) =>
          GetPatientFascicoloUseCase(ctx.read<PatientClinicalFileRepository>()),
    ),
    // Sintomi (RF10/RF12).
    Provider<AddSymptomUseCase>(
      create: (ctx) => AddSymptomUseCase(ctx.read<SymptomRepository>()),
    ),
    Provider<UpdateSymptomUseCase>(
      create: (ctx) => UpdateSymptomUseCase(ctx.read<SymptomRepository>()),
    ),
    Provider<DeleteSymptomUseCase>(
      create: (ctx) => DeleteSymptomUseCase(ctx.read<SymptomRepository>()),
    ),
    Provider<GetSymptomUseCase>(
      create: (ctx) => GetSymptomUseCase(ctx.read<SymptomRepository>()),
    ),
    Provider<GetSymptomsForDateUseCase>(
      create: (ctx) =>
          GetSymptomsForDateUseCase(ctx.read<SymptomRepository>()),
    ),
    // Diario giornaliero fuso (RF11).
    Provider<GetDailyDiaryUseCase>(
      create: (ctx) => GetDailyDiaryUseCase(
          ctx.read<DiaryRepository>(), ctx.read<SymptomRepository>()),
    ),
    // Ricerca specialisti + collegamento (RF13–RF17).
    Provider<SearchSpecialistsUseCase>(
      create: (ctx) =>
          SearchSpecialistsUseCase(ctx.read<SpecialistDirectoryRepository>()),
    ),
    Provider<GetLinkedSpecialistUseCase>(
      create: (ctx) => GetLinkedSpecialistUseCase(
        ctx.read<AuthRepository>(),
        ctx.read<SpecialistDirectoryRepository>(),
      ),
    ),
    Provider<GetExcludedSpecialistTaxCodesUseCase>(
      create: (ctx) =>
          GetExcludedSpecialistTaxCodesUseCase(ctx.read<LinkRequestRepository>()),
    ),
    Provider<SendLinkRequestUseCase>(
      create: (ctx) => SendLinkRequestUseCase(
        ctx.read<AuthRepository>(),
        ctx.read<LinkRequestRepository>(),
      ),
    ),
    Provider<GetReceivedLinkRequestsUseCase>(
      create: (ctx) =>
          GetReceivedLinkRequestsUseCase(ctx.read<LinkRequestRepository>()),
    ),
    Provider<AcceptLinkRequestUseCase>(
      create: (ctx) => AcceptLinkRequestUseCase(
        ctx.read<AuthRepository>(),
        ctx.read<LinkRequestRepository>(),
      ),
    ),
    Provider<RejectLinkRequestUseCase>(
      create: (ctx) => RejectLinkRequestUseCase(
        ctx.read<AuthRepository>(),
        ctx.read<LinkRequestRepository>(),
      ),
    ),
    // Vista diario per lo specialista (RF18–RF20).
    Provider<GetLinkedPatientsUseCase>(
      create: (ctx) =>
          GetLinkedPatientsUseCase(ctx.read<LinkedPatientsRepository>()),
    ),
    Provider<GetPatientDiaryRangeUseCase>(
      create: (ctx) => GetPatientDiaryRangeUseCase(
        ctx.read<DiaryRepository>(),
        ctx.read<SymptomRepository>(),
      ),
    ),
  ];
}
