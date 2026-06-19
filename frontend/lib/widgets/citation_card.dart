import 'package:flutter/material.dart';
import '../core/models/citation_model.dart';
import '../core/theme/app_theme.dart';

class CitationCard extends StatelessWidget {
  final CitationModel citation;

  const CitationCard({super.key, required this.citation});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: AppTheme.gold, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.format_quote_rounded,
                    color: AppTheme.gold, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Citation du jour',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              citation.texte,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textPrimary,
                    height: 1.6,
                  ),
            ),
            if (citation.source != null && citation.source!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '— ${citation.source}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
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
