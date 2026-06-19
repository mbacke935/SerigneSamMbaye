import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/auth_scaffold.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final _authService = AuthService(ApiClient());

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    try {
      await _authService.register(email, _usernameCtrl.text.trim(), password);
      // Auto-connexion pour éviter une re-saisie : on enchaîne directement.
      try {
        await _authService.login(email, password);
        if (mounted) context.go('/profil');
      } on AuthException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Compte créé ! Connectez-vous.')),
          );
          context.go('/connexion');
        }
      }
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
      showBack: true,
      title: 'Créer un compte',
      subtitle: 'Sauvegardez vos audios, vidéos et citations favoris.',
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
              controller: _usernameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nom d\'utilisateur',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Au moins 3 caractères'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
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
              textInputAction: TextInputAction.next,
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
                  (v == null || v.length < 8) ? 'Au moins 8 caractères' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _register(),
              decoration: const InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
              validator: (v) => v != _passwordCtrl.text
                  ? 'Les mots de passe ne correspondent pas'
                  : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: _loading ? null : _register,
              child: _loading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text('Création…'),
                      ],
                    )
                  : const Text('Créer mon compte'),
            ),
          ],
        ),
      ),
    );
  }
}
