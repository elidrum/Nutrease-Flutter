import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/domain/model/auth_user.dart';
import 'package:nutrease_flutter/domain/model/user_role.dart';
import 'package:nutrease_flutter/domain/repository/auth_repository.dart';
import 'package:nutrease_flutter/presentation/navigation/routes.dart';
import 'package:nutrease_flutter/presentation/screens/splash/root_view_model.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('RootViewModel', () {
    late _MockAuthRepository auth;

    setUp(() => auth = _MockAuthRepository());

    test('routes a patient to the patient home', () async {
      when(() => auth.getCurrentUser()).thenAnswer((_) async => const AuthUser(
            userId: 'u',
            email: 'p@x.com',
            role: UserRole.patient,
            taxCode: 'CF',
          ));
      final viewModel = RootViewModel(auth);

      await viewModel.resolveStartDestination();

      expect(viewModel.state.loading, isFalse);
      expect(viewModel.state.targetRoute, Routes.patientHome);
    });

    test('routes a specialist to the specialist home', () async {
      when(() => auth.getCurrentUser()).thenAnswer((_) async => const AuthUser(
            userId: 'u',
            email: 's@x.com',
            role: UserRole.specialist,
            taxCode: 'CF',
          ));
      final viewModel = RootViewModel(auth);

      await viewModel.resolveStartDestination();

      expect(viewModel.state.targetRoute, Routes.specialistHome);
    });

    test('routes to login when no session is present', () async {
      when(() => auth.getCurrentUser()).thenAnswer((_) async => null);
      final viewModel = RootViewModel(auth);

      await viewModel.resolveStartDestination();

      expect(viewModel.state.loading, isFalse);
      expect(viewModel.state.targetRoute, Routes.login);
    });
  });
}
