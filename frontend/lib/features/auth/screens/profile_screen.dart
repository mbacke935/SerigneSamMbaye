import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/audio_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/font_scale_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/notification_prefs_service.dart';
import '../../../core/services/theme_service.dart';
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
  List<AudioModel> _history = [];
  Map<String, bool> _notifPrefs = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final loggedIn = await _authService.isLoggedIn();
    final history = await HistoryService().getHistory();
    final notifPrefs = await NotificationPrefsService().loadAll();
    UserModel? user;
    if (loggedIn) {
      try {
        user = await _authService.getMe();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _user = user;
        _history = history;
        _notifPrefs = notifPrefs;
        _loading = false;
      });
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

  // ─── Authenticated ─────────────────────────────────────────────────────────

  Widget _buildAuthenticated(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildAvatarHeader(context),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoTile(Icons.person_outlined, 'Nom d\'utilisateur', _user!.username),
                const SizedBox(height: 12),
                _buildInfoTile(Icons.email_outlined, 'Email', _user!.email),
                const SizedBox(height: 24),
                if (_history.isNotEmpty) _buildStats(),
                const Divider(height: 32),
                _buildThemeTile(context),
                const Divider(height: 8),
                _buildFontScaleTile(context),
                const Divider(height: 32),
                _buildNotifSection(),
                const Divider(height: 32),
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(Icons.headphones_rounded, '${_history.length}', 'audios écoutés'),
          _statItem(Icons.history_rounded, _lastListened(), 'dernier audio'),
        ],
      ),
    );
  }

  String _lastListened() {
    if (_history.isEmpty) return '—';
    return _history.first.titre.split(' ').take(2).join(' ');
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 22),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildNotifSection() {
    const labels = {
      'audio': ('Nouveaux audios', Icons.headphones_outlined),
      'video': ('Nouvelles vidéos', Icons.videocam_outlined),
      'citation': ('Citation du jour', Icons.format_quote_outlined),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Notifications',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        for (final entry in labels.entries)
          SwitchListTile(
            secondary: Icon(entry.value.$2, color: AppTheme.primary),
            title: Text(entry.value.$1,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            value: _notifPrefs[entry.key] ?? true,
            activeColor: AppTheme.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            onChanged: (v) async {
              await NotificationPrefsService().setEnabled(entry.key, v);
              if (mounted) setState(() => _notifPrefs[entry.key] = v);
            },
          ),
      ],
    );
  }

  // ─── Shared ────────────────────────────────────────────────────────────────

  Widget _buildThemeTile(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, _) {
        final mode = ThemeService().mode;
        return ListTile(
          leading: Icon(
            mode == ThemeMode.dark
                ? Icons.dark_mode_rounded
                : mode == ThemeMode.light
                    ? Icons.light_mode_rounded
                    : Icons.brightness_auto_rounded,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.gold
                : AppTheme.primary,
          ),
          title: const Text('Thème', style: TextStyle(fontWeight: FontWeight.w600)),
          trailing: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded, size: 18)),
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded, size: 18)),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded, size: 18)),
            ],
            selected: {mode},
            onSelectionChanged: (s) => ThemeService().setMode(s.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      },
    );
  }

  Widget _buildFontScaleTile(BuildContext context) {
    return ListenableBuilder(
      listenable: FontScaleService(),
      builder: (context, _) {
        final scale = FontScaleService().scale;
        return ListTile(
          leading: Icon(
            Icons.text_fields_rounded,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.gold
                : AppTheme.primary,
          ),
          title: const Text('Taille du texte',
              style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Slider(
            value: scale,
            min: 0.8,
            max: 1.4,
            divisions: 6,
            activeColor: AppTheme.primary,
            label: '${(scale * 100).round()}%',
            onChanged: (v) => FontScaleService().setScale(v),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        );
      },
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
          Icon(icon,
              color: scheme.brightness == Brightness.dark
                  ? AppTheme.gold
                  : AppTheme.primary,
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11, color: scheme.onSurfaceVariant)),
                  Text(value,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
          ),
        ],
      ),
    );
  }

  // ─── Unauthenticated ───────────────────────────────────────────────────────

  Widget _buildUnauthenticated(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
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
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 16),
            _buildThemeTile(context),
            _buildFontScaleTile(context),
          ],
        ),
      ),
    );
  }
}
