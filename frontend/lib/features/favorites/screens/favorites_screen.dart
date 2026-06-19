import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/favorites_data.dart';
import '../../../core/models/audio_model.dart';
import '../../../core/models/video_model.dart';
import '../../../core/models/citation_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/favori_service.dart';
import '../../../core/services/audio_player_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/audio_list_tile.dart';
import '../../../widgets/video_card.dart';
import '../../../widgets/citation_list_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final _client = ApiClient();
  late final FavoriService _favoriService;
  late final AuthService _authService;
  final _playerService = AudioPlayerService();

  TabController? _tabController;
  bool _loadingAuth = true;
  bool _isLoggedIn = false;
  FavoritesData _data = FavoritesData.empty();
  bool _loadingData = false;

  @override
  void initState() {
    super.initState();
    _favoriService = FavoriService(_client);
    _authService = AuthService(_client);
    _tabController = TabController(length: 3, vsync: this);
    _checkAuth();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await _authService.isLoggedIn();
    if (mounted) {
      setState(() { _isLoggedIn = loggedIn; _loadingAuth = false; });
      if (loggedIn) _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    setState(() => _loadingData = true);
    final data = await _favoriService.getFavorites();
    if (mounted) setState(() { _data = data; _loadingData = false; });
  }

  Future<void> _removeAudio(AudioModel audio) async {
    await _favoriService.toggle('audio', audio.id);
    setState(() {
      _data = FavoritesData(
        audios: _data.audios.where((a) => a.id != audio.id).toList(),
        videos: _data.videos,
        citations: _data.citations,
      );
    });
  }

  Future<void> _removeVideo(VideoModel video) async {
    await _favoriService.toggle('video', video.id);
    setState(() {
      _data = FavoritesData(
        audios: _data.audios,
        videos: _data.videos.where((v) => v.id != video.id).toList(),
        citations: _data.citations,
      );
    });
  }

  Future<void> _removeCitation(CitationModel citation) async {
    await _favoriService.toggle('citation', citation.id);
    setState(() {
      _data = FavoritesData(
        audios: _data.audios,
        videos: _data.videos,
        citations: _data.citations.where((c) => c.id != citation.id).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes favoris'),
        bottom: _isLoggedIn
            ? TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primary,
                tabs: [
                  Tab(text: 'Audios (${_data.audios.length})'),
                  Tab(text: 'Vidéos (${_data.videos.length})'),
                  Tab(text: 'Citations (${_data.citations.length})'),
                ],
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingAuth) return const Center(child: CircularProgressIndicator());

    if (!_isLoggedIn) return _buildNotLoggedIn();

    if (_loadingData) return const Center(child: CircularProgressIndicator());

    return TabBarView(
      controller: _tabController,
      children: [
        _AudiosTab(
          audios: _data.audios,
          onPlay: (audio) async {
            await _playerService.playAudio(audio);
            if (mounted) context.push('/audios/lecteur', extra: audio);
          },
          onRemove: _removeAudio,
        ),
        _VideosTab(
          videos: _data.videos,
          onTap: (v) => context.push('/videos/lecteur', extra: v),
          onRemove: _removeVideo,
        ),
        _CitationsTab(
          citations: _data.citations,
          onRemove: _removeCitation,
        ),
      ],
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border_rounded,
                size: 80, color: AppTheme.textSecondary),
            const SizedBox(height: 24),
            Text('Connectez-vous pour voir vos favoris',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: 10),
            Text(
              'Sauvegardez vos audios, vidéos et citations préférés.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/connexion'),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tabs ──────────────────────────────────────────────────────────────────

class _AudiosTab extends StatelessWidget {
  final List<AudioModel> audios;
  final ValueChanged<AudioModel> onPlay;
  final ValueChanged<AudioModel> onRemove;
  const _AudiosTab(
      {required this.audios, required this.onPlay, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (audios.isEmpty) return _emptyTab('Aucun audio en favori');
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: audios.length,
      itemBuilder: (context, i) {
        final audio = audios[i];
        return Dismissible(
          key: ValueKey(audio.id),
          direction: DismissDirection.endToStart,
          background: _dismissBg(),
          onDismissed: (_) => onRemove(audio),
          child: AudioListTile(
            audio: audio,
            isCurrentlyPlaying: false,
            isFavorited: true,
            onTap: () => onPlay(audio),
            onFavoriTap: () => onRemove(audio),
          ),
        );
      },
    );
  }
}

class _VideosTab extends StatelessWidget {
  final List<VideoModel> videos;
  final ValueChanged<VideoModel> onTap;
  final ValueChanged<VideoModel> onRemove;
  const _VideosTab(
      {required this.videos, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return _emptyTab('Aucune vidéo en favori');
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: videos.length,
      itemBuilder: (context, i) => Stack(
        children: [
          VideoCard(video: videos[i], onTap: () => onTap(videos[i])),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => onRemove(videos[i]),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Color(0xFFE53935), size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CitationsTab extends StatelessWidget {
  final List<CitationModel> citations;
  final ValueChanged<CitationModel> onRemove;
  const _CitationsTab(
      {required this.citations, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (citations.isEmpty) return _emptyTab('Aucune citation en favori');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: citations.length,
      itemBuilder: (context, i) => CitationListCard(
        citation: citations[i],
        isFavorited: true,
        onFavoriTap: () => onRemove(citations[i]),
      ),
    );
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────

Widget _emptyTab(String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.favorite_border_rounded,
            size: 56, color: AppTheme.textSecondary),
        const SizedBox(height: 16),
        Text(message,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 14)),
      ],
    ),
  );
}

Widget _dismissBg() {
  return Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    color: const Color(0xFFE53935),
    child: const Icon(Icons.delete_outline_rounded,
        color: Colors.white, size: 28),
  );
}
