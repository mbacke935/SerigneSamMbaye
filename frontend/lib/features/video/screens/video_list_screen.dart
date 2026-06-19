import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/video_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/content_service.dart';
import '../../../core/theme/app_theme.dart';
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
              .where((v) =>
                  v.titre.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vidéos')),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildGrid()),
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
          hintText: 'Rechercher une vidéo...',
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

  Widget _buildGrid() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_filteredVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_outlined,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'Aucune vidéo disponible'
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

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
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
