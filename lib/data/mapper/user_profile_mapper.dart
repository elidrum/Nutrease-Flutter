import '../../domain/model/user_role.dart';
import '../dto/user_profile_dto.dart';

/// Punto di traduzione per la lookup `profilo_utente`: `paziente/specialista`
/// (DB) ↔ [UserRole] (dominio).
extension UserProfileDtoMapper on UserProfileDto {
  UserRole toUserRole() => UserRole.fromDb(ruolo);
}
