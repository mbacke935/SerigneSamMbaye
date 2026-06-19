import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// État vide cohérent (aucun contenu).
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? hint;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppTheme.primary.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (hint != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: secondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// État d'erreur avec bouton « Réessayer ».
class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorRetry({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: secondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: secondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: 180,
              child: FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Réessayer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
