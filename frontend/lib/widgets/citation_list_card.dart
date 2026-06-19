import 'package:flutter/material.dart';
import '../core/models/citation_model.dart';
import '../core/theme/app_theme.dart';

class CitationListCard extends StatelessWidget {
  final CitationModel citation;
  final bool isFavorited;
  final VoidCallback? onFavoriTap;
  final VoidCallback? onTap;

  const CitationListCard({
    super.key,
    required this.citation,
    this.isFavorited = false,
    this.onFavoriTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? scheme.surface : const Color(0xFFFFFBF0),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppTheme.gold.withValues(alpha: 0.25)),
          boxShadow: AppTheme.softShadow(0.04),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.md, AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.format_quote_rounded, color: AppTheme.gold, size: 22),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      citation.texte,
                      textAlign: TextAlign.center,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.serif(
                        fontSize: 15.5,
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurface,
                        height: 1.6,
                      ),
                    ),
                    if (citation.source != null && citation.source!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(width: 28, height: 1, color: AppTheme.gold.withValues(alpha: 0.4)),
                      const SizedBox(height: 6),
                      Text(
                        citation.source!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onFavoriTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: Icon(
                    isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 20,
                    color: isFavorited ? const Color(0xFFE53935) : scheme.onSurfaceVariant,
                  ),
                  onPressed: onFavoriTap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
