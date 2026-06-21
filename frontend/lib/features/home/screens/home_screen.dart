import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/album_model.dart';
import '../../../core/models/audio_model.dart';
import '../../../core/models/video_model.dart';
import '../../../core/models/citation_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/album_service.dart';
import '../../../core/services/content_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/album_card.dart';
import '../../../widgets/app_states.dart';
import '../../../widgets/audio_card.dart';
import '../../../widgets/citation_card.dart';
import '../../../widgets/fade_slide_in.dart';
import '../../../widgets/skeleton.dart';
import '../../../widgets/video_card.dart';
import '../../video/screens/video_player_screen.dart' show VideoPlayerArgs;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiClient = ApiClient();
  late final ContentService _service = ContentService(_apiClient);
  late final AlbumService _albumService = AlbumService(_apiClient);
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_HomeData> _loadData() async {
    final results = await Future.wait([
      _service.getCitationDuJour(),
      _albumService.getAlbums(),
      _service.getDerniersAudios(limit: 8),
      _service.getDernieresVideos(limit: 6),
      HistoryService().getHistory(),
    ]);
    return _HomeData(
      citation: results[0] as CitationModel?,
      albums: results[1] as List<AlbumModel>,
      audios: results[2] as List<AudioModel>,
      videos: results[3] as List<VideoModel>,
      history: results[4] as List<AudioModel>,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadData());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_HomeData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return ListView(children: [
                const SizedBox(height: 120),
                ErrorRetry(
                  message: 'Impossible de charger le contenu',
                  onRetry: _refresh,
                ),
              ]);
            }
            return _buildContent(snapshot.data!);
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: AppSpacing.md,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.auto_stories_rounded, color: AppTheme.gold, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('As-salâm aleykoum',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                Text('Serigne Sam Mbaye',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700, height: 1.1)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          tooltip: 'Notifications',
          onPressed: () => context.push('/notifications'),
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Rechercher',
          onPressed: () => context.go('/recherche'),
        ),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }

  Widget _buildLoading() {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        SizedBox(height: AppSpacing.md),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: SkeletonBox(height: 120, radius: AppRadius.md),
        ),
        SizedBox(height: AppSpacing.lg),
        SkeletonAudioRail(),
        SizedBox(height: AppSpacing.lg),
        SkeletonGrid(),
      ],
    );
  }

  Widget _buildContent(_HomeData data) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        const SizedBox(height: AppSpacing.sm),
        if (data.citation != null)
          FadeSlideIn(child: CitationCard(citation: data.citation!)),
        FadeSlideIn(
          delay: const Duration(milliseconds: 60),
          child: _BiographieNavCard(onTap: () => context.push('/biographie')),
        ),
        if (data.history.isNotEmpty) ...[
          _SectionHeader(title: 'Récemment écoutés'),
          FadeSlideIn(
            delay: const Duration(milliseconds: 75),
            child: _AudiosRail(audios: data.history),
          ),
        ],
        if (data.albums.isNotEmpty) ...[
          _SectionHeader(title: 'Albums'),
          FadeSlideIn(
            delay: const Duration(milliseconds: 90),
            child: _AlbumsRail(albums: data.albums),
          ),
        ],
        _SectionHeader(title: 'Derniers audios', onVoirTout: () => context.go('/audios')),
        if (data.audios.isEmpty)
          _empty('Aucun audio disponible')
        else
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: _AudiosRail(audios: data.audios),
          ),
        const SizedBox(height: AppSpacing.sm),
        _SectionHeader(title: 'Dernières vidéos', onVoirTout: () => context.go('/videos')),
        if (data.videos.isEmpty)
          _empty('Aucune vidéo disponible')
        else
          FadeSlideIn(
            delay: const Duration(milliseconds: 150),
            child: _VideosRail(videos: data.videos),
          ),
      ],
    );
  }

  Widget _empty(String message) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Text(message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
}

class _HomeData {
  final CitationModel? citation;
  final List<AlbumModel> albums;
  final List<AudioModel> audios;
  final List<VideoModel> videos;
  final List<AudioModel> history;

  const _HomeData({
    required this.citation,
    required this.albums,
    required this.audios,
    required this.videos,
    required this.history,
  });
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onVoirTout;

  const _SectionHeader({required this.title, this.onVoirTout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700)),
          ),
          if (onVoirTout != null)
            TextButton(onPressed: onVoirTout, child: const Text('Voir tout')),
        ],
      ),
    );
  }
}

class _AlbumsRail extends StatelessWidget {
  final List<AlbumModel> albums;
  const _AlbumsRail({required this.albums});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) => AlbumCard(
          album: albums[i],
          onTap: () => context.push('/albums/${albums[i].id}', extra: albums[i].titre),
        ),
      ),
    );
  }
}

class _AudiosRail extends StatelessWidget {
  final List<AudioModel> audios;
  const _AudiosRail({required this.audios});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 188,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: audios.length,
        itemBuilder: (context, i) => AudioCard(
          audio: audios[i],
          onTap: () => context.push('/audios/lecteur', extra: audios[i]),
        ),
      ),
    );
  }
}

class _VideosRail extends StatelessWidget {
  final List<VideoModel> videos;
  const _VideosRail({required this.videos});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 234,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: videos.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, i) => SizedBox(
          width: 280,
          child: VideoCard(
            video: videos[i],
            onTap: () => context.push('/videos/lecteur',
                extra: VideoPlayerArgs(playlist: videos, initialIndex: i)),
          ),
        ),
      ),
    );
  }
}

class _BiographieNavCard extends StatelessWidget {
  final VoidCallback onTap;
  const _BiographieNavCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryLight],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppTheme.softShadow(0.18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.menu_book_rounded, color: AppTheme.gold, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Biographie',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('Vie et enseignements',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.gold, size: 15),
          ],
        ),
      ),
    );
  }
}
