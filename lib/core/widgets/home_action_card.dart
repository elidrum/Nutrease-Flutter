import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Riga d'azione usata in entrambe le home (paziente/specialista): una [Card]
/// arrotondata con icona circolare, titolo, sottotitolo opzionale, chevron in
/// coda e un badge contatore opzionale.
///
/// Rispecchia l'`HomeActionCard` Android così le due app si assomigliano, e dà
/// a ogni voce della home la stessa larghezza piena e lo stesso raggio.
class HomeActionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  /// Contatore mostrato come badge sull'icona; nascosto quando `<= 0`.
  final int badgeCount;

  /// Letta dagli screen reader per l'icona leading decorativa.
  final String? iconSemanticLabel;

  const HomeActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.badgeCount = 0,
    this.iconSemanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: ConstrainedBox(
            // Altezza uniforme tra le card a prescindere dalle righe di sottotitolo.
            constraints: const BoxConstraints(
              minHeight: AppTokens.homeCardMinHeight,
            ),
            child: Row(
              children: [
                Badge.count(
                  count: badgeCount,
                  isLabelVisible: badgeCount > 0,
                  child: Container(
                    width: AppTokens.iconCircle,
                    height: AppTokens.iconCircle,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: AppTokens.iconMd,
                      color: scheme.onPrimaryContainer,
                      semanticLabel: iconSemanticLabel,
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: AppTokens.fontTitle,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppTokens.spacingXs),
                        Text(
                          subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: AppTokens.fontBody,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                Icon(
                  Icons.chevron_right,
                  size: AppTokens.iconMd,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
