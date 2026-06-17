import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/core/error/result.dart';
import 'package:nutrease_flutter/core/strings/it_strings.dart';
import 'package:nutrease_flutter/domain/model/gender.dart';
import 'package:nutrease_flutter/domain/model/patient.dart';
import 'package:nutrease_flutter/domain/model/specialist.dart';
import 'package:nutrease_flutter/domain/model/specialization_type.dart';
import 'package:nutrease_flutter/domain/model/user_profile.dart';
import 'package:nutrease_flutter/domain/model/user_role.dart';
import 'package:nutrease_flutter/domain/usecase/get_linked_specialist_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/get_profile_use_case.dart';
import 'package:nutrease_flutter/domain/usecase/logout_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/home/patient_home_screen.dart';
import 'package:provider/provider.dart';

class _MockGetProfile extends Mock implements GetProfileUseCase {}

class _MockLogout extends Mock implements LogoutUseCase {}

class _MockGetLinked extends Mock implements GetLinkedSpecialistUseCase {}

/// Renders the patient home and lets the async loads settle.
///
/// Regression for the Flutter guidelines §2 (Row children sized with
/// Expanded/Flexible; explicit text overflow): the linked-specialist cards must
/// not overflow on a narrow phone.
void main() {
  late _MockGetProfile getProfile;
  late _MockLogout logout;
  late _MockGetLinked getLinked;

  final profile = UserProfile(
    userId: 'u1',
    role: UserRole.patient,
    taxCode: 'PAT1',
    patient: Patient(
      taxCode: 'PAT1',
      firstName: 'Giulia',
      surname: 'Esposito',
      email: 'g@e.it',
      birthDate: DateTime(1990, 1, 1),
      gender: Gender.female,
    ),
  );

  setUp(() {
    getProfile = _MockGetProfile();
    logout = _MockLogout();
    getLinked = _MockGetLinked();
    when(() => getProfile()).thenAnswer((_) async => Ok(profile));
  });

  Widget buildApp() => MultiProvider(
        providers: [
          Provider<GetProfileUseCase>.value(value: getProfile),
          Provider<LogoutUseCase>.value(value: logout),
          Provider<GetLinkedSpecialistUseCase>.value(value: getLinked),
        ],
        child: const MaterialApp(home: PatientHomeScreen()),
      );

  /// Forces a narrow phone width to stress the card layouts.
  void useNarrowPhone(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('no-specialist card renders the long subtitle without overflow',
      (tester) async {
    useNarrowPhone(tester);
    when(() => getLinked()).thenAnswer((_) async => const Ok<Specialist?>(null));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(ItStrings.patientHomeNoSpecialistTitle), findsOneWidget);
    expect(find.text(ItStrings.patientHomeNoSpecialistSubtitle), findsOneWidget);
  });

  testWidgets('linked-specialist card renders without overflow',
      (tester) async {
    useNarrowPhone(tester);
    when(() => getLinked()).thenAnswer((_) async => const Ok<Specialist?>(
          Specialist(
            taxCode: 'SPC1',
            firstName: 'Alessandro',
            surname: 'Della Valle Bianchi',
            email: 's@e.it',
            vatNumber: '12345678901',
            specialization: SpecializationType.gastroenterologist,
          ),
        ));

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(ItStrings.patientHomeLinkedSpecialistLabel), findsOneWidget);
    expect(find.text('Alessandro Della Valle Bianchi'), findsOneWidget);
  });
}
