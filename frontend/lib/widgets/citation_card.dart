import 'package:flutter/material.dart';
import '../core/models/citation_model.dart';
import '../core/theme/app_theme.dart';

class CitationCard extends StatelessWidget {
  final CitationModel citation;

  const CitationCard({super.key, required this.citation});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: const Border(left: BorderSide(color: AppTheme.gold, width: 4)),
        boxShadow: AppTheme.softShadow(0.06),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.format_quote_rounded, color: AppTheme.gold, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'CITATION DU JOUR',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              citation.texte,
              style: AppTheme.serif(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: scheme.onSurface,
                height: 1.6,
              ),
            ),
            if (citation.source != null && citation.source!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                '— ${citation.source}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
