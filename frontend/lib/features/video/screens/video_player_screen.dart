import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../core/models/video_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/favori_service.dart';
import '../../../core/theme/app_theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _playerReady = false;
  bool _playerError = false;

  final _client = ApiClient();
  late final FavoriService _favoriService;
  late final AuthService _authService;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _favoriService = FavoriService(_client);
    _authService = AuthService(_client);
    _initPlayer();
    _loadFavoriState();
  }

  Future<void> _initPlayer() async {
    final url = widget.video.fichier;
    if (url == null || url.isEmpty) {
      setState(() => _playerError = true);
      return;
    }
    try {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(url));
      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControlsOnInitialize: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.gold,
          handleColor: AppTheme.gold,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
      );

      if (mounted) setState(() => _playerReady = true);
    } catch (_) {
      if (mounted) setState(() => _playerError = true);
    }
  }

  Future<void> _loadFavoriState() async {
    if (!await _authService.isLoggedIn()) return;
    final ids = await _favoriService.getFavoritedIds('video');
    if (mounted) setState(() => _isFavorited = ids.contains(widget.video.id));
  }

  Future<void> _toggleFavori() async {
    if (!await _authService.isLoggedIn()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour ajouter aux favoris.')),
      );
      return;
    }
    final isFav = await _favoriService.toggle('video', widget.video.id);
    if (mounted) setState(() => _isFavorited = isFav);
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.video.titre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _isFavorited ? const Color(0xFFE53935) : Colors.white,
            ),
            onPressed: _toggleFavori,
            tooltip: 'Favoris',
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVideoPlayer(),
          Expanded(child: _buildInfo()),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_playerError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: AppTheme.gold, size: 48),
                SizedBox(height: 12),
                Text('Impossible de lire cette vidéo',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ),
      );
    }

    if (!_playerReady) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.video.imageMiniature != null &&
                  widget.video.imageMiniature!.isNotEmpty)
                Opacity(
                  opacity: 0.4,
                  child: Image.network(
                    widget.video.imageMiniature!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              const CircularProgressIndicator(color: AppTheme.gold),
            ],
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }

  Widget _buildInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video.titre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          if (widget.video.dureeFormatee.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    color: Colors.white54, size: 14),
                const SizedBox(width: 4),
                Text(
                  widget.video.dureeFormatee,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ],
          if (widget.video.description != null &&
              widget.video.description!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            Text(
              widget.video.description!,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 14, height: 1.6),
            ),
          ],
        ],
      ),
    );
  }
}
