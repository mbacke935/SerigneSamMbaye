import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'fade_slide_in.dart';

/// Gabarit commun aux écrans d'authentification : logo + titre + sous-titre,
/// puis le formulaire. Épuré, centré, lisible, compatible clair/sombre.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showBack
          ? AppBar(backgroundColor: Colors.transparent, elevation: 0)
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: FadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: AppTheme.softShadow(0.18),
                        ),
                        child: const Icon(Icons.auto_stories_rounded,
                            color: AppTheme.gold, size: 40),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bannière d'erreur d'authentification (cohérente, thème-aware).
class AuthErrorBanner extends StatelessWidget {
  final String message;
  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.errorColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: AppTheme.errorColor, fontWeight: FontWeight.w500, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}
