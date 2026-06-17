import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/domain_error.dart';
import '../../core/error/result.dart';
import '../../domain/model/patient.dart';
import '../../domain/model/specialist.dart';
import '../../domain/model/user_profile.dart';
import '../../domain/model/user_role.dart';
import '../../domain/repository/user_repository.dart';
import '../dto/patient_dto.dart';
import '../dto/specialist_dto.dart';
import '../mapper/patient_mapper.dart';
import '../mapper/specialist_mapper.dart';
import 'supabase_error_mapper.dart';

/// [UserRepository] su Supabase. Le RLS limitano ogni lettura/scrittura alla
/// riga del chiamante.
class UserRepositoryImpl implements UserRepository {
  final SupabaseClient _client;

  const UserRepositoryImpl(this._client);

  @override
  Future<Result<UserProfile>> getProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return const Err(AuthError());

      final profileRow = await _client
          .from('profilo_utente')
          .select('ruolo, codice_fiscale')
          .eq('auth_uid', user.id)
          .maybeSingle();
      if (profileRow == null) {
        return const Err(NotFoundError('Profilo non trovato.'));
      }

      final role = UserRole.fromDb(profileRow['ruolo'] as String);
      final taxCode = profileRow['codice_fiscale'] as String;

      switch (role) {
        case UserRole.patient:
          final row = await _client
              .from('paziente')
              .select()
              .eq('CodiceFiscale', taxCode)
              .single();
          return Ok(UserProfile(
            userId: user.id,
            role: role,
            taxCode: taxCode,
            patient: PatientDto.fromJson(row).toDomain(),
          ));
        case UserRole.specialist:
          final row = await _client
              .from('specialista')
              .select()
              .eq('CodiceFiscale', taxCode)
              .single();
          return Ok(UserProfile(
            userId: user.id,
            role: role,
            taxCode: taxCode,
            specialist: SpecialistDto.fromJson(row).toDomain(),
          ));
      }
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<void>> updatePatient(Patient patient) async {
    try {
      // PATCH parziale: solo i campi anagrafici modificabili, mai l'email.
      await _client.from('paziente').update({
        'Nome': patient.firstName,
        'Cognome': patient.surname,
        'Telefono': patient.phone,
        'Citta': patient.city,
      }).eq('CodiceFiscale', patient.taxCode);
      return const Ok(null);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }

  @override
  Future<Result<void>> updateSpecialist(Specialist specialist) async {
    try {
      // PATCH parziale: campi professionali modificabili, mai l'email.
      await _client.from('specialista').update({
        'Nome': specialist.firstName,
        'Cognome': specialist.surname,
        'PartitaIVA': specialist.vatNumber,
        'Specializzazione': specialist.specialization?.dbLabel,
        'Citta': specialist.city,
        'Info': specialist.info,
      }).eq('CodiceFiscale', specialist.taxCode);
      return const Ok(null);
    } catch (e) {
      return Err(mapSupabaseError(e));
    }
  }
}
