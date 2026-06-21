import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/video_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/content_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_states.dart';
import '../../../widgets/search_field.dart';
import '../../../widgets/skeleton.dart';
import '../../../widgets/video_card.dart';
import 'video_player_screen.dart' show VideoPlayerArgs;

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  late final ContentService _contentService;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<VideoModel> _allVideos = [];
  List<VideoModel> _filteredVideos = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _contentService = ContentService(ApiClient());
    _scrollCtrl.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_searchCtrl.text.isNotEmpty) return;
    if (_loadingMore || !_hasMore) return;
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _page = 1; _hasMore = true; });
    final result = await _contentService.getVideosPaged(1);
    if (mounted) {
      setState(() {
        _allVideos = result.items;
        _filteredVideos = result.items;
        _hasMore = result.hasMore;
        _page = 1;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    final result = await _contentService.getVideosPaged(nextPage);
    if (mounted) {
      setState(() {
        _allVideos.addAll(result.items);
        _filteredVideos = _allVideos;
        _hasMore = result.hasMore;
        _page = nextPage;
        _loadingMore = false;
      });
    }
  }

  void _search(String query) {
    setState(() {
      _filteredVideos = query.isEmpty
          ? _allVideos
          : _allVideos
              .where((v) => v.titre.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vidéos')),
      body: Column(
        children: [
          SearchField(controller: _searchCtrl, hint: 'Rechercher une vidéo…', onChanged: _search),
          Expanded(child: _buildGrid()),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    if (_loading) return const SkeletonGrid(count: 6);

    if (_filteredVideos.isEmpty) {
      return EmptyState(
        icon: Icons.videocam_off_outlined,
        message: _searchCtrl.text.isEmpty ? 'Aucune vidéo disponible' : 'Aucun résultat',
        hint: _searchCtrl.text.isEmpty ? null : 'pour « ${_searchCtrl.text} »',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        controller: _scrollCtrl,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            sliver: SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = AppSpacing.md;
                  // Largeur cible ~290px : 1 colonne sur mobile, plusieurs sur web.
                  final cols =
                      (constraints.maxWidth / 290).floor().clamp(1, 4);
                  final itemWidth =
                      (constraints.maxWidth - spacing * (cols - 1)) / cols;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: AppSpacing.lg,
                    children: [
                      for (var i = 0; i < _filteredVideos.length; i++)
                        SizedBox(
                          width: itemWidth,
                          child: VideoCard(
                            video: _filteredVideos[i],
                            onTap: () => context.push('/videos/lecteur',
                                extra: VideoPlayerArgs(
                                  playlist: _filteredVideos,
                                  initialIndex: i,
                                )),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          if (_loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          if (!_hasMore && _filteredVideos.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 0, AppSpacing.xl),
                child: Center(
                  child: Text(
                    'Toutes les vidéos chargées',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
