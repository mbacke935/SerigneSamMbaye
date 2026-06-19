import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/audio_model.dart';
import '../../../core/models/video_model.dart';
import '../../../core/models/citation_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/content_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/audio_card.dart';
import '../../../widgets/video_card.dart';
import '../../../widgets/citation_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ContentService _service = ContentService(ApiClient());
  late Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_HomeData> _loadData() async {
    final results = await Future.wait([
      _service.getCitationDuJour(),
      _service.getDerniersAudios(limit: 5),
      _service.getDernieresVideos(limit: 6),
    ]);
    return _HomeData(
      citation: results[0] as CitationModel?,
      audios: results[1] as List<AudioModel>,
      videos: results[2] as List<VideoModel>,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _refresh,
        child: FutureBuilder<_HomeData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _buildError();
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
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_stories_rounded,
              color: AppTheme.gold, size: 24),
          const SizedBox(width: 8),
          Text(
            'Serigne Sam Mbaye',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
          onPressed: () => context.push('/notifications'),
        ),
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Rechercher',
          onPressed: () => context.go('/recherche'),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildContent(_HomeData data) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Citation du jour
          if (data.citation != null) ...[
            _SectionHeader(
              title: 'Citation du jour',
              showVoirTout: false,
            ),
            CitationCard(citation: data.citation!),
            const SizedBox(height: 8),
          ],

          // Biographie (carte de navigation)
          _BiographieNavCard(onTap: () => context.push('/biographie')),

          // Derniers audios
          _SectionHeader(
            title: 'Derniers audios',
            onVoirTout: () => context.go('/audios'),
          ),
          if (data.audios.isEmpty)
            _buildEmpty('Aucun audio disponible')
          else
            _AudiosSection(audios: data.audios),

          const SizedBox(height: 8),

          // Dernières vidéos
          _SectionHeader(
            title: 'Dernières vidéos',
            onVoirTout: () => context.go('/videos'),
          ),
          if (data.videos.isEmpty)
            _buildEmpty('Aucune vidéo disponible')
          else
            _VideosGrid(videos: data.videos),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded,
              color: AppTheme.textSecondary, size: 56),
          const SizedBox(height: 16),
          Text('Impossible de charger le contenu',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            onPressed: _refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Text(message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary)),
    );
  }
}

class _HomeData {
  final CitationModel? citation;
  final List<AudioModel> audios;
  final List<VideoModel> videos;

  const _HomeData({
    required this.citation,
    required this.audios,
    required this.videos,
  });
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onVoirTout;
  final bool showVoirTout;

  const _SectionHeader({
    required this.title,
    this.onVoirTout,
    this.showVoirTout = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
            ),
          ),
          if (showVoirTout && onVoirTout != null)
            TextButton(
              onPressed: onVoirTout,
              child: const Text('Voir tout',
                  style: TextStyle(color: AppTheme.primary, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _AudiosSection extends StatelessWidget {
  final List<AudioModel> audios;

  const _AudiosSection({required this.audios});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 186,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: audios.length,
        itemBuilder: (context, i) => AudioCard(audio: audios[i]),
      ),
    );
  }
}

class _VideosGrid extends StatelessWidget {
  final List<VideoModel> videos;

  const _VideosGrid({required this.videos});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.82,
        ),
        itemCount: videos.length,
        itemBuilder: (context, i) => VideoCard(video: videos[i]),
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
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, Color(0xFF1A5C44)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: AppTheme.gold, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biographie',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'Vie et enseignements de Serigne Sam Mbaye',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppTheme.gold, size: 16),
          ],
        ),
      ),
    );
  }
}
