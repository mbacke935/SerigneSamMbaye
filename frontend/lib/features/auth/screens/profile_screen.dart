import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService(ApiClient());
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final loggedIn = await _authService.isLoggedIn();
    if (!loggedIn) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final user = await _authService.getMe();
      if (mounted) setState(() { _user = user; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? _buildUnauthenticated(context)
              : _buildAuthenticated(context),
    );
  }

  Widget _buildAuthenticated(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildAvatarHeader(context),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _buildInfoTile(Icons.person_outlined, 'Nom d\'utilisateur', _user!.username),
                const SizedBox(height: 12),
                _buildInfoTile(Icons.email_outlined, 'Email', _user!.email),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.favorite_rounded, color: AppTheme.primary),
                  title: const Text('Mes favoris',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary),
                  onTap: () => context.push('/favoris'),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                const SizedBox(height: 4),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppTheme.errorColor),
                  title: const Text('Se déconnecter',
                      style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
                  onTap: _logout,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: AppTheme.gold,
            child: Text(
              _user!.initiale,
              style: const TextStyle(
                  fontSize: 34, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Text(_user!.username,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(_user!.email,
              style: const TextStyle(color: AppTheme.gold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.brightness == Brightness.dark ? AppTheme.gold : AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticated(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle_outlined,
              size: 96, color: AppTheme.primary),
          const SizedBox(height: 24),
          Text('Connectez-vous',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(
            'Créez un compte pour sauvegarder vos audios, vidéos et citations favoris.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: () => context.go('/connexion'),
            child: const Text('Se connecter'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/inscription'),
            child: const Text('Créer un compte'),
          ),
        ],
      ),
    );
  }
}
