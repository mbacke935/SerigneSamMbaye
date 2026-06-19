import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final _authService = AuthService(ApiClient());

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      await _authService.login(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) context.go('/profil');
    } on AuthException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Une erreur est survenue. Réessayez.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Bon retour',
      subtitle: 'Connectez-vous pour retrouver vos favoris.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null) ...[
              AuthErrorBanner(message: _errorMessage!),
              const SizedBox(height: AppSpacing.md),
            ],
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) =>
                  (v == null || !v.contains('@')) ? 'Email invalide' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _login(),
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) =>
                  (v == null || v.length < 6) ? 'Mot de passe trop court' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const _LoadingLabel(text: 'Connexion…')
                  : const Text('Se connecter'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _loading ? null : () => context.go('/'),
              child: const Text('Continuer sans compte'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: TextButton(
                onPressed: () => context.go('/inscription'),
                child: RichText(
                  text: TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium,
                    children: [
                      const TextSpan(text: 'Pas encore de compte ? '),
                      TextSpan(
                        text: 'S\'inscrire',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingLabel extends StatelessWidget {
  final String text;
  const _LoadingLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(text),
      ],
    );
  }
}
