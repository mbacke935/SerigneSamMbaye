import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
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
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.format_quote_rounded, color: AppTheme.gold, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'CITATION DU JOUR',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppTheme.gold,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          fontSize: 11,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  color: scheme.onSurfaceVariant,
                  tooltip: 'Copier',
                  onPressed: () => _copy(context, citation.texte),
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 18),
                  color: scheme.onSurfaceVariant,
                  tooltip: 'Partager',
                  onPressed: () => _share(citation),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Citation copiée'), duration: Duration(seconds: 2)),
    );
  }

  void _share(CitationModel c) {
    final text = c.source != null && c.source!.isNotEmpty
        ? '« ${c.texte} »\n— ${c.source}\n\nSerigne Sam Mbaye'
        : '« ${c.texte} »\n\nSerigne Sam Mbaye';
    Share.share(text, subject: 'Citation de Serigne Sam Mbaye');
  }
}
