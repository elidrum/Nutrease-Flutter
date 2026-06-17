import 'package:flutter/material.dart';

import '../strings/it_strings.dart';
import '../theme/app_theme.dart';

/// Messaggio d'errore centrato con un'azione di retry opzionale.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.error,
              size: 48,
              semanticLabel: ItStrings.errorIconLabel,
            ),
            const SizedBox(height: AppTokens.spacingMd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppTokens.spacingLg),
              FilledButton(
                onPressed: onRetry,
                child: const Text(ItStrings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
