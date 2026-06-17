import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nutrease_flutter/domain/repository/auth_repository.dart';
import 'package:nutrease_flutter/domain/usecase/reset_password_use_case.dart';
import 'package:nutrease_flutter/presentation/screens/auth/reset_password_screen.dart';
import 'package:provider/provider.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<ResetPasswordUseCase>(
          create: (_) => ResetPasswordUseCase(_MockAuthRepository()),
          child: const ResetPasswordScreen(email: 'mario@example.com'),
        ),
      ),
    );
  }

  FilledButton submitButton(WidgetTester tester) => tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Reimposta password'),
      );

  testWidgets('renders the form with the recipient email and the 8-digit field',
      (tester) async {
    await pumpScreen(tester);

    expect(find.textContaining('mario@example.com'), findsOneWidget);
    expect(find.text('Codice (8 cifre)'), findsOneWidget);
    expect(find.text('Conferma password'), findsOneWidget);
  });

  testWidgets('enables submit only when code (8) + both passwords are filled',
      (tester) async {
    await pumpScreen(tester);

    // Disabled at start.
    expect(submitButton(tester).onPressed, isNull);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '1234567'); // only 7 digits
    await tester.enterText(fields.at(1), 'Password1');
    await tester.enterText(fields.at(2), 'Password1');
    await tester.pump();
    expect(submitButton(tester).onPressed, isNull); // still short

    await tester.enterText(fields.at(0), '12345678'); // now 8 digits
    await tester.pump();
    expect(submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('the digit-only field rejects non-numeric input', (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField).at(0), 'ab12cd34ef');
    await tester.pump();

    // Only digits kept, capped at 8.
    expect(find.text('1234'), findsOneWidget);
  });
}
