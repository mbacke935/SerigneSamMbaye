import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/audio_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/audio_player_service.dart';
import '../../../core/services/content_service.dart';
import '../../../core/services/favori_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/audio_list_tile.dart';

class AudioListScreen extends StatefulWidget {
  const AudioListScreen({super.key});

  @override
  State<AudioListScreen> createState() => _AudioListScreenState();
}

class _AudioListScreenState extends State<AudioListScreen> {
  final _client = ApiClient();
  late final ContentService _contentService;
  late final FavoriService _favoriService;
  late final AuthService _authService;
  final _playerService = AudioPlayerService();
  final _searchCtrl = TextEditingController();

  List<AudioModel> _allAudios = [];
  List<AudioModel> _filteredAudios = [];
  Set<int> _favoritedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _contentService = ContentService(_client);
    _favoriService = FavoriService(_client);
    _authService = AuthService(_client);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final audios = await _contentService.getAllAudios();
    Set<int> favorited = {};
    if (await _authService.isLoggedIn()) {
      favorited = await _favoriService.getFavoritedIds('audio');
    }
    if (mounted) {
      setState(() {
        _allAudios = audios;
        _filteredAudios = audios;
        _favoritedIds = favorited;
        _loading = false;
      });
    }
  }

  void _search(String query) {
    setState(() {
      _filteredAudios = query.isEmpty
          ? _allAudios
          : _allAudios
              .where((a) =>
                  a.titre.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  Future<void> _toggleFavori(AudioModel audio) async {
    final loggedIn = await _authService.isLoggedIn();
    if (!loggedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Connectez-vous pour sauvegarder des favoris.'),
          action: SnackBarAction(
            label: 'Connexion',
            onPressed: () => context.go('/connexion'),
          ),
        ),
      );
      return;
    }
    final isFav = await _favoriService.toggle('audio', audio.id);
    if (mounted) {
      setState(() {
        if (isFav) {
          _favoritedIds.add(audio.id);
        } else {
          _favoritedIds.remove(audio.id);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audios')),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _search,
        decoration: InputDecoration(
          hintText: 'Rechercher un audio...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchCtrl.clear();
                    _search('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_filteredAudios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.headphones_outlined,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'Aucun audio disponible'
                  : 'Aucun résultat pour "${_searchCtrl.text}"',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ValueListenableBuilder<AudioModel?>(
      valueListenable: _playerService.currentAudioListenable,
      builder: (context, currentAudio, _) {
        return RefreshIndicator(
          color: AppTheme.primary,
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: _filteredAudios.length,
            itemBuilder: (context, i) {
              final audio = _filteredAudios[i];
              return AudioListTile(
                audio: audio,
                isCurrentlyPlaying: currentAudio?.id == audio.id,
                isFavorited: _favoritedIds.contains(audio.id),
                onTap: () => context.push('/audios/lecteur', extra: audio),
                onFavoriTap: () => _toggleFavori(audio),
              );
            },
          ),
        );
      },
    );
  }
}
