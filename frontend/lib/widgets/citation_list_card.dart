import 'package:flutter/material.dart';
import '../core/models/citation_model.dart';
import '../core/theme/app_theme.dart';

class CitationListCard extends StatelessWidget {
  final CitationModel citation;
  final bool isFavorited;
  final VoidCallback? onFavoriTap;

  const CitationListCard({
    super.key,
    required this.citation,
    this.isFavorited = false,
    this.onFavoriTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.format_quote_rounded,
                      color: AppTheme.gold, size: 22),
                  const SizedBox(height: 8),
                  Text(
                    citation.texte,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textPrimary,
                          height: 1.65,
                        ),
                  ),
                  if (citation.source != null &&
                      citation.source!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: 28,
                      height: 1,
                      color: AppTheme.gold.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      citation.source!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (onFavoriTap != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  isFavorited
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20,
                  color: isFavorited
                      ? const Color(0xFFE53935)
                      : AppTheme.textSecondary,
                ),
                onPressed: onFavoriTap,
                tooltip: isFavorited
                    ? 'Retirer des favoris'
                    : 'Ajouter aux favoris',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
