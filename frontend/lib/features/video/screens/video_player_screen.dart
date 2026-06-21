import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/models/video_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/favori_service.dart';
import '../../../core/theme/app_theme.dart';

class VideoPlayerArgs {
  final List<VideoModel> playlist;
  final int initialIndex;
  const VideoPlayerArgs({required this.playlist, required this.initialIndex});
}

class VideoPlayerScreen extends StatefulWidget {
  final VideoPlayerArgs args;
  const VideoPlayerScreen({super.key, required this.args});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late int _idx;
  VideoModel get _video => widget.args.playlist[_idx];

  // ── Players ───────────────────────────────────────────────────────────────
  VideoPlayerController? _vCtrl;
  ChewieController? _chewie;
  YoutubePlayerController? _ytCtrl;
  bool _ready = false;
  bool _error = false;

  // ── Fullscreen ────────────────────────────────────────────────────────────
  bool _isFullscreen = false;
  bool _overlayVisible = true;
  Timer? _overlayTimer;

  // ── Seek feedback ─────────────────────────────────────────────────────────
  String? _seekLabel;
  Timer? _seekLabelTimer;

  // ── Auth / Favorites ──────────────────────────────────────────────────────
  final _client = ApiClient();
  late final FavoriService _favoriService;
  late final AuthService _authService;
  bool _isFav = false;

  // ─────────────────────────────────────────────────────────────────────────
  // Init / dispose
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _idx = widget.args.initialIndex;
    _favoriService = FavoriService(_client);
    _authService = AuthService(_client);
    _setup();
    _loadFav();
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _seekLabelTimer?.cancel();
    _chewie?.dispose();
    _vCtrl?.dispose();
    _ytCtrl?.close();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Player setup
  // ─────────────────────────────────────────────────────────────────────────

  void _setup() {
    final src = _video.sourceUrl ?? '';
    if (src.isEmpty) { setState(() => _error = true); return; }

    final ytId = YoutubePlayerController.convertUrlToId(src);
    if (ytId != null) {
      _ytCtrl?.close();
      _ytCtrl = YoutubePlayerController.fromVideoId(
        videoId: ytId,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          enableCaption: false,
        ),
      );
      setState(() => _ready = true);
    } else {
      _initFile(src);
    }
  }

  Future<void> _initFile(String url) async {
    _chewie?.dispose();
    _vCtrl?.dispose();
    _chewie = null;
    _vCtrl = null;

    try {
      _vCtrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await _vCtrl!.initialize();
      _chewie = ChewieController(
        videoPlayerController: _vCtrl!,
        autoPlay: true,
        looping: false,
        allowFullScreen: false,
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
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _loadFav() async {
    if (!await _authService.isLoggedIn()) return;
    final ids = await _favoriService.getFavoritedIds('video');
    if (mounted) setState(() => _isFav = ids.contains(_video.id));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Navigation
  // ─────────────────────────────────────────────────────────────────────────

  bool get _hasPrev => _idx > 0;
  bool get _hasNext => _idx < widget.args.playlist.length - 1;

  void _playAt(int index) {
    _chewie?.dispose();
    _vCtrl?.dispose();
    _ytCtrl?.close();
    _chewie = null;
    _vCtrl = null;
    _ytCtrl = null;
    setState(() { _idx = index; _ready = false; _error = false; _isFav = false; });
    _setup();
    _loadFav();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fullscreen
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _enterFullscreen() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (!mounted) return;
    setState(() { _isFullscreen = true; _overlayVisible = true; });
    _scheduleHide();
  }

  Future<void> _exitFullscreen() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _overlayTimer?.cancel();
    if (!mounted) return;
    setState(() { _isFullscreen = false; _overlayVisible = true; });
  }

  void _scheduleHide() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _overlayVisible = false);
    });
  }

  void _onVideoTap() {
    setState(() => _overlayVisible = !_overlayVisible);
    if (_overlayVisible) _scheduleHide();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Seek
  // ─────────────────────────────────────────────────────────────────────────

  void _seek(Duration delta, {required bool forward}) {
    if (_vCtrl == null) return;
    final cur = _vCtrl!.value.position;
    final dur = _vCtrl!.value.duration;
    final target = cur + delta;
    final clamped = target < Duration.zero ? Duration.zero : (target > dur ? dur : target);
    _vCtrl!.seekTo(clamped);
    _seekLabelTimer?.cancel();
    setState(() => _seekLabel = forward ? '+10s ▶▶' : '◀◀ -10s');
    _seekLabelTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _seekLabel = null);
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Share / Favorite
  // ─────────────────────────────────────────────────────────────────────────

  void _share() {
    final url = _video.sourceUrl ?? '';
    if (url.isEmpty) return;
    Share.share('${_video.titre}\n$url');
  }

  Future<void> _toggleFav() async {
    if (!await _authService.isLoggedIn()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour ajouter aux favoris.')),
      );
      return;
    }
    final v = await _favoriService.toggle('video', _video.id);
    if (mounted) setState(() => _isFav = v);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _isFullscreen ? _buildFullscreen() : _buildNormal();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Normal mode
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildNormal() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _video.titre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        actions: [
          if (_video.sourceUrl?.isNotEmpty == true)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              onPressed: _share,
              tooltip: 'Partager',
            ),
          IconButton(
            icon: Icon(
              _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFav ? const Color(0xFFE53935) : Colors.white,
            ),
            onPressed: _toggleFav,
            tooltip: 'Favoris',
          ),
          if (_vCtrl != null)
            IconButton(
              icon: const Icon(Icons.fullscreen_rounded),
              onPressed: _enterFullscreen,
              tooltip: 'Plein écran',
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNormalVideoArea(),
          Expanded(child: _buildInfo()),
        ],
      ),
    );
  }

  Widget _buildNormalVideoArea() {
    return AspectRatio(
      aspectRatio: _vCtrl?.value.aspectRatio ?? 16 / 9,
      child: _buildVideoContent(raw: false),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Fullscreen mode
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildFullscreen() {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (d) {
          if (d.primaryVelocity != null && d.primaryVelocity! > 300) _exitFullscreen();
        },
        child: Stack(
          children: [
            // Raw video fills screen
            SizedBox.expand(
              child: Center(child: _buildVideoContent(raw: true)),
            ),

            // Seek zones — only for direct video
            if (_vCtrl != null) ...[
              Positioned(
                left: 0, top: 0, bottom: 0, width: w / 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _onVideoTap,
                  onDoubleTap: () => _seek(const Duration(seconds: 10), forward: false),
                  child: const SizedBox.expand(),
                ),
              ),
              Positioned(
                right: 0, top: 0, bottom: 0, width: w / 2,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _onVideoTap,
                  onDoubleTap: () => _seek(const Duration(seconds: 10), forward: true),
                  child: const SizedBox.expand(),
                ),
              ),
            ] else
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _onVideoTap,
                  child: const SizedBox.expand(),
                ),
              ),

            // Seek label flash
            if (_seekLabel != null)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    _seekLabel!,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),

            // Controls overlay (auto-hide)
            AnimatedOpacity(
              opacity: _overlayVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_overlayVisible,
                child: _buildFullscreenOverlay(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullscreenOverlay() {
    final safe = MediaQuery.of(context).padding;

    return Column(
      children: [
        // ── Top bar ──────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(4, safe.top + 4, 8, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
                onPressed: _exitFullscreen,
                tooltip: 'Quitter le plein écran',
              ),
              Expanded(
                child: Text(
                  _video.titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              if (_video.sourceUrl?.isNotEmpty == true)
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  onPressed: _share,
                ),
              IconButton(
                icon: Icon(
                  _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: _isFav ? const Color(0xFFE53935) : Colors.white,
                ),
                onPressed: _toggleFav,
              ),
            ],
          ),
        ),

        const Spacer(),

        // ── Bottom bar ────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(12, 20, 12, safe.bottom + 8),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress bar (direct video only)
              if (_vCtrl != null)
                ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _vCtrl!,
                  builder: (_, val, __) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VideoProgressIndicator(
                        _vCtrl!,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: AppTheme.gold,
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white12,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmtDur(val.position),
                              style: const TextStyle(color: Colors.white70, fontSize: 11)),
                          Text(_fmtDur(val.duration),
                              style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),

              // Controls row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous
                  if (widget.args.playlist.length > 1)
                    IconButton(
                      icon: Icon(Icons.skip_previous_rounded, size: 30,
                          color: _hasPrev ? Colors.white : Colors.white30),
                      onPressed: _hasPrev ? () => _playAt(_idx - 1) : null,
                    ),

                  // Seek -10s
                  if (_vCtrl != null)
                    IconButton(
                      icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 30),
                      onPressed: () => _seek(const Duration(seconds: 10), forward: false),
                    ),

                  // Play / Pause
                  if (_vCtrl != null)
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: _vCtrl!,
                      builder: (_, val, __) => IconButton(
                        icon: Icon(
                          val.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          color: Colors.white,
                          size: 48,
                        ),
                        onPressed: val.isPlaying ? _vCtrl!.pause : _vCtrl!.play,
                      ),
                    ),

                  // Seek +10s
                  if (_vCtrl != null)
                    IconButton(
                      icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 30),
                      onPressed: () => _seek(const Duration(seconds: 10), forward: true),
                    ),

                  // Next
                  if (widget.args.playlist.length > 1)
                    IconButton(
                      icon: Icon(Icons.skip_next_rounded, size: 30,
                          color: _hasNext ? Colors.white : Colors.white30),
                      onPressed: _hasNext ? () => _playAt(_idx + 1) : null,
                    ),
                ],
              ),

              // Position indicator
              if (widget.args.playlist.length > 1)
                Text(
                  '${_idx + 1} / ${widget.args.playlist.length}',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Shared video content widget
  // raw = true → VideoPlayer (no chewie controls, for fullscreen)
  // raw = false → Chewie (with controls, for normal mode)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildVideoContent({required bool raw}) {
    // Error state
    if (_error) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppTheme.gold, size: 48),
              const SizedBox(height: 12),
              const Text('Impossible de lire cette vidéo',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                label: const Text('Réessayer', style: TextStyle(color: Colors.white70)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24)),
                onPressed: () {
                  setState(() { _error = false; _ready = false; });
                  _setup();
                },
              ),
            ],
          ),
        ),
      );
    }

    // Loading state
    if (!_ready) {
      return Container(
        color: Colors.black,
        child: Stack(alignment: Alignment.center, children: [
          if (_video.imageMiniature?.isNotEmpty == true)
            Opacity(
              opacity: 0.4,
              child: Image.network(
                _video.imageMiniature!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          const CircularProgressIndicator(color: AppTheme.gold),
        ]),
      );
    }

    // YouTube
    if (_ytCtrl != null) {
      return YoutubePlayer(controller: _ytCtrl!, aspectRatio: 16 / 9);
    }

    // Direct video — raw (fullscreen) vs chewie (normal)
    if (raw) {
      return AspectRatio(
        aspectRatio: _vCtrl!.value.aspectRatio,
        child: VideoPlayer(_vCtrl!),
      );
    }
    return Chewie(controller: _chewie!);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Info section (normal mode only)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _video.titre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),

          if (_video.dureeFormatee.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.access_time_rounded, color: Colors.white54, size: 14),
              const SizedBox(width: 4),
              Text(_video.dureeFormatee,
                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ]),
          ],

          // Seek buttons (direct video only)
          if (_vCtrl != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              _seekChip(Icons.replay_10_rounded, '-10s',
                  () => _seek(const Duration(seconds: 10), forward: false)),
              const SizedBox(width: 8),
              _seekChip(Icons.forward_10_rounded, '+10s',
                  () => _seek(const Duration(seconds: 10), forward: true)),
            ]),
          ],

          // Playlist navigation
          if (widget.args.playlist.length > 1) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.skip_previous_rounded, size: 18),
                  label: const Text('Précédente'),
                  onPressed: _hasPrev ? () => _playAt(_idx - 1) : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _hasPrev ? Colors.white : Colors.white30,
                    side: BorderSide(
                        color: _hasPrev ? Colors.white24 : Colors.white12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.skip_next_rounded, size: 18),
                  label: const Text('Suivante'),
                  iconAlignment: IconAlignment.end,
                  onPressed: _hasNext ? () => _playAt(_idx + 1) : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _hasNext ? Colors.white : Colors.white30,
                    side: BorderSide(
                        color: _hasNext ? Colors.white24 : Colors.white12),
                  ),
                ),
              ),
            ]),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${_idx + 1} / ${widget.args.playlist.length}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ),
          ],

          if (_video.description?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            Text(
              _video.description!,
              style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6),
            ),
          ],
        ],
      ),
    );
  }

  Widget _seekChip(IconData icon, String label, VoidCallback onPressed) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: const BorderSide(color: Colors.white24),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        visualDensity: VisualDensity.compact,
        minimumSize: Size.zero,
      ),
    );
  }

  String _fmtDur(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}
