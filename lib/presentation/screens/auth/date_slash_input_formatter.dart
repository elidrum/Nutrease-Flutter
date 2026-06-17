import 'package:flutter/services.dart';

/// Maschera un campo data mentre l'utente digita: tiene solo le cifre e inserisce
/// `/` in automatico dopo giorno e mese (`gg/mm/aaaa`). Porting della
/// `DateMaskTransformation` Android.
class DateSlashInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < 8; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
