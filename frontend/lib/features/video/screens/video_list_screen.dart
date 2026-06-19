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

class VideoListScreen extends StatefulWidget {
  const VideoListScreen({super.key});

  @override
  State<VideoListScreen> createState() => _VideoListScreenState();
}

class _VideoListScreenState extends State<VideoListScreen> {
  late final ContentService _contentService;
  final _searchCtrl = TextEditingController();

  List<VideoModel> _allVideos = [];
  List<VideoModel> _filteredVideos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _contentService = ContentService(ApiClient());
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final videos = await _contentService.getAllVideos();
    if (mounted) {
      setState(() {
        _allVideos = videos;
        _filteredVideos = videos;
        _loading = false;
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
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.78,
        ),
        itemCount: _filteredVideos.length,
        itemBuilder: (context, i) {
          final video = _filteredVideos[i];
          return VideoCard(
            video: video,
            onTap: () => context.push('/videos/lecteur', extra: video),
          );
        },
      ),
    );
  }
}
