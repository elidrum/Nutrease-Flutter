import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Intestazione sopra un campo di form (form pasto/sintomo): stesso peso e
/// stessa dimensione tra le schermate, così le sezioni restano coerenti.
class SectionLabel extends StatelessWidget {
  final String text;

  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: AppTokens.fontSubtitle,
              fontWeight: FontWeight.w600,
            ),
      );
}
