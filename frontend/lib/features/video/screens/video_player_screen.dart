import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/models/video_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/favori_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/video_thumbnail.dart';

class VideoPlayerArgs {
  final List<VideoModel> playlist;
  final int initialIndex;
  const VideoPlayerArgs({required this.playlist, required this.initialIndex});
}

enum _Gesture { brightness, volume }

class VideoPlayerScreen extends StatefulWidget {
  final VideoPlayerArgs args;
  const VideoPlayerScreen({super.key, required this.args});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late int _idx;
  VideoModel get _video => widget.args.playlist[_idx];

  // ── Players ────────────────────────────────────────────────────────────────
  VideoPlayerController? _vCtrl;
  YoutubePlayerController? _ytCtrl;
  bool _ready = false;
  bool _error = false;

  // ── UI state ─────────────────────────────────────────────────────────────
  bool _isFullscreen = false;
  bool _controlsVisible = true;
  bool _locked = false;
  Timer? _hideTimer;

  // ── Playback ───────────────────────────────────────────────────────────────
  double _speed = 1.0;
  bool _autoNextHandled = false;
  Timer? _posTimer;

  // ── Seek / gesture feedback ──────────────────────────────────────────────
  String? _seekLabel;
  Timer? _seekLabelTimer;
  _Gesture? _gesture;
  double _gestureValue = 0;
  Timer? _gestureTimer;
  double _brightness = 0.5;
  double _volume = 1.0;

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
    _loadPersistedSpeed();
    _initBrightness();
    _setup();
    _loadFav();
  }

  @override
  void dispose() {
    _saveCurrentPosition();
    _hideTimer?.cancel();
    _seekLabelTimer?.cancel();
    _gestureTimer?.cancel();
    _posTimer?.cancel();
    _vCtrl?.removeListener(_videoListener);
    _vCtrl?.dispose();
    _ytCtrl?.close();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!kIsWeb) {
      try {
        ScreenBrightness().resetApplicationScreenBrightness();
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _initBrightness() async {
    if (kIsWeb) return;
    try {
      _brightness = await ScreenBrightness().application;
    } catch (_) {}
  }

  Future<void> _loadPersistedSpeed() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getDouble('video_speed') ?? 1.0;
    if (mounted) setState(() => _speed = s);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Player setup
  // ─────────────────────────────────────────────────────────────────────────

  void _setup() {
    final src = _video.sourceUrl ?? '';
    if (src.isEmpty) {
      setState(() => _error = true);
      return;
    }

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
    _vCtrl?.removeListener(_videoListener);
    _vCtrl?.dispose();
    _vCtrl = null;
    _autoNextHandled = false;

    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      _vCtrl = ctrl;
      await ctrl.initialize();
      await ctrl.setPlaybackSpeed(_speed);
      await ctrl.setVolume(_volume);

      // Reprise : on repositionne là où on s'était arrêté.
      final saved = await _loadPosition(_video.id);
      final dur = ctrl.value.duration;
      if (saved != null && saved.inSeconds > 5 && saved < dur - const Duration(seconds: 5)) {
        await ctrl.seekTo(saved);
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reprise à ${_fmtDur(saved)}'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          });
        }
      }

      ctrl.addListener(_videoListener);
      await ctrl.play();
      _startPositionTimer();
      if (mounted) {
        setState(() => _ready = true);
        _scheduleHide();
      }
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  void _videoListener() {
    final ctrl = _vCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final val = ctrl.value;
    final dur = val.duration;
    // Enchaînement automatique en fin de vidéo.
    if (dur > Duration.zero &&
        val.position >= dur - const Duration(milliseconds: 800) &&
        !_autoNextHandled) {
      _autoNextHandled = true;
      _clearPosition(_video.id);
      if (_hasNext) {
        _playAt(_idx + 1);
      }
    }
  }

  Future<void> _loadFav() async {
    if (!await _authService.isLoggedIn()) return;
    final ids = await _favoriService.getFavoritedIds('video');
    if (mounted) setState(() => _isFav = ids.contains(_video.id));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Position persistence (resume)
  // ─────────────────────────────────────────────────────────────────────────

  void _startPositionTimer() {
    _posTimer?.cancel();
    _posTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final ctrl = _vCtrl;
      if (ctrl != null && ctrl.value.isPlaying) {
        _savePosition(_video.id, ctrl.value.position);
      }
    });
  }

  void _saveCurrentPosition() {
    final ctrl = _vCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;
    // En fin de vidéo, on n'enregistre pas (sinon « reprise » la relancerait
    // à la fin et l'enchaînement auto se déclencherait en boucle).
    if (dur > Duration.zero && pos >= dur - const Duration(seconds: 5)) {
      _clearPosition(_video.id);
      return;
    }
    _savePosition(_video.id, pos);
  }

  Future<void> _savePosition(int id, Duration pos) async {
    if (pos.inSeconds < 5) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('vpos_$id', pos.inSeconds);
  }

  Future<Duration?> _loadPosition(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getInt('vpos_$id');
    return (s != null && s > 5) ? Duration(seconds: s) : null;
  }

  Future<void> _clearPosition(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('vpos_$id');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Navigation between playlist items
  // ─────────────────────────────────────────────────────────────────────────

  bool get _hasPrev => _idx > 0;
  bool get _hasNext => _idx < widget.args.playlist.length - 1;

  void _playAt(int index) {
    _saveCurrentPosition();
    _posTimer?.cancel();
    _vCtrl?.removeListener(_videoListener);
    _vCtrl?.dispose();
    _ytCtrl?.close();
    _vCtrl = null;
    _ytCtrl = null;
    setState(() {
      _idx = index;
      _ready = false;
      _error = false;
      _isFav = false;
      _controlsVisible = true;
    });
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
    setState(() {
      _isFullscreen = true;
      _controlsVisible = true;
    });
    _scheduleHide();
  }

  Future<void> _exitFullscreen() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!mounted) return;
    setState(() {
      _isFullscreen = false;
      _locked = false;
      _controlsVisible = true;
    });
    _scheduleHide();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Controls visibility
  // ─────────────────────────────────────────────────────────────────────────

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && (_vCtrl?.value.isPlaying ?? false)) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _onSurfaceTap() {
    if (_locked) {
      // En mode verrouillé, un tap révèle juste le bouton de déverrouillage.
      _showControls();
      return;
    }
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHide();
  }

  void _toggleLock() {
    setState(() {
      _locked = !_locked;
      _controlsVisible = true;
    });
    _scheduleHide();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Seek / play-pause / speed
  // ─────────────────────────────────────────────────────────────────────────

  void _togglePlay() {
    final ctrl = _vCtrl;
    if (ctrl == null) return;
    setState(() {
      if (ctrl.value.isPlaying) {
        ctrl.pause();
        _saveCurrentPosition();
        _controlsVisible = true;
        _hideTimer?.cancel();
      } else {
        ctrl.play();
        _scheduleHide();
      }
    });
  }

  void _seek(Duration delta, {required bool forward}) {
    final ctrl = _vCtrl;
    if (ctrl == null) return;
    final cur = ctrl.value.position;
    final dur = ctrl.value.duration;
    final target = cur + delta;
    final clamped =
        target < Duration.zero ? Duration.zero : (target > dur ? dur : target);
    ctrl.seekTo(clamped);
    _seekLabelTimer?.cancel();
    setState(() => _seekLabel = forward ? '+10 s' : '−10 s');
    _seekLabelTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _seekLabel = null);
    });
  }

  void _seekToFraction(double f) {
    final ctrl = _vCtrl;
    if (ctrl == null) return;
    final dur = ctrl.value.duration;
    ctrl.seekTo(dur * f.clamp(0.0, 1.0));
  }

  Future<void> _showSpeedSheet() async {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
    _hideTimer?.cancel();
    final picked = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(children: [
                Icon(Icons.speed_rounded, color: AppTheme.gold, size: 20),
                SizedBox(width: 8),
                Text('Vitesse de lecture',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
              ]),
            ),
            for (final s in speeds)
              ListTile(
                title: Text(s == 1.0 ? 'Normale (1×)' : '$s×',
                    style: const TextStyle(color: Colors.white)),
                trailing: _speed == s
                    ? const Icon(Icons.check_rounded, color: AppTheme.gold)
                    : null,
                onTap: () => Navigator.pop(context, s),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() => _speed = picked);
      await _vCtrl?.setPlaybackSpeed(picked);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('video_speed', picked);
    }
    _scheduleHide();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Brightness / Volume gestures (mobile, fullscreen only)
  // ─────────────────────────────────────────────────────────────────────────

  bool get _gesturesEnabled => _isFullscreen && !kIsWeb && !_locked;

  void _onVerticalDrag(_Gesture kind, double dy) {
    if (!_gesturesEnabled) return;
    final next = (kind == _Gesture.brightness ? _brightness : _volume) -
        dy / 280;
    final clamped = next.clamp(0.0, 1.0);
    if (kind == _Gesture.brightness) {
      _brightness = clamped;
      if (!kIsWeb) {
        try {
          ScreenBrightness().setApplicationScreenBrightness(clamped);
        } catch (_) {}
      }
    } else {
      _volume = clamped;
      _vCtrl?.setVolume(clamped);
    }
    setState(() {
      _gesture = kind;
      _gestureValue = clamped;
    });
    _gestureTimer?.cancel();
    _gestureTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _gesture = null);
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
    return PopScope(
      canPop: !_isFullscreen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isFullscreen) _exitFullscreen();
      },
      child: _isFullscreen ? _buildFullscreen() : _buildNormal(),
    );
  }

  // ── Normal mode ────────────────────────────────────────────────────────────

  Widget _buildNormal() {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(_video.titre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        actions: [
          if (_video.sourceUrl?.isNotEmpty == true)
            IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: _share,
                tooltip: 'Partager'),
          IconButton(
            icon: Icon(
              _isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFav ? const Color(0xFFE53935) : Colors.white,
            ),
            onPressed: _toggleFav,
            tooltip: 'Favoris',
          ),
          if (_vCtrl != null && _ready)
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
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildPlayerArea(fullscreen: false),
          ),
          Expanded(child: _buildInfo()),
        ],
      ),
    );
  }

  // ── Fullscreen mode ─────────────────────────────────────────────────────

  Widget _buildFullscreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _buildPlayerArea(fullscreen: true),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Player area : video surface + gestures + custom controls overlay
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildPlayerArea({required bool fullscreen}) {
    // YouTube : on s'appuie sur les contrôles natifs de l'iframe.
    if (_ytCtrl != null && _ready) {
      return ColoredBox(
        color: Colors.black,
        child: Center(child: YoutubePlayer(controller: _ytCtrl!, aspectRatio: 16 / 9)),
      );
    }

    if (_error) return _buildError();
    if (!_ready || _vCtrl == null) return _buildLoading();

    final w = MediaQuery.of(context).size.width;

    return MouseRegion(
      // Web/desktop : un mouvement de souris révèle les contrôles ; le curseur
      // se masque avec eux pendant la lecture.
      cursor: _controlsVisible ? MouseCursor.defer : SystemMouseCursors.none,
      onHover: (_) => _onPointerHover(),
      onExit: (_) => _onPointerExit(),
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: _vCtrl!.value.aspectRatio,
                child: VideoPlayer(_vCtrl!),
              ),
            ),

          // Gesture zones (left / right halves)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: w / 2,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _onSurfaceTap,
              onDoubleTap: _locked
                  ? null
                  : () => _seek(const Duration(seconds: 10), forward: false),
              onVerticalDragUpdate: (d) =>
                  _onVerticalDrag(_Gesture.brightness, d.primaryDelta ?? 0),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: w / 2,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _onSurfaceTap,
              onDoubleTap: _locked
                  ? null
                  : () => _seek(const Duration(seconds: 10), forward: true),
              onVerticalDragUpdate: (d) =>
                  _onVerticalDrag(_Gesture.volume, d.primaryDelta ?? 0),
            ),
          ),

          // Buffering spinner
          ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: _vCtrl!,
            builder: (_, val, __) => (val.isBuffering && val.isInitialized)
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.gold))
                : const SizedBox.shrink(),
          ),

          // Seek flash
          if (_seekLabel != null) _buildSeekFlash(),

          // Gesture indicator (brightness / volume)
          if (_gesture != null) _buildGestureIndicator(),

          // Controls overlay
            AnimatedOpacity(
              opacity: _controlsVisible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_controlsVisible,
                child: _locked
                    ? _buildLockedOverlay()
                    : _buildControls(fullscreen: fullscreen),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPointerHover() {
    _hideTimer?.cancel();
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _onPointerExit() {
    if (!(_vCtrl?.value.isPlaying ?? false)) return;
    _hideTimer?.cancel();
    if (_controlsVisible) setState(() => _controlsVisible = false);
  }

  // ── Controls overlay (unlocked) ──────────────────────────────────────────

  Widget _buildControls({required bool fullscreen}) {
    final safe = MediaQuery.of(context).padding;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.transparent, Colors.black54],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Column(
        children: [
          // Top bar (fullscreen only — normal mode uses the AppBar)
          if (fullscreen)
            Padding(
              padding: EdgeInsets.fromLTRB(4, safe.top + 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: _exitFullscreen,
                    tooltip: 'Quitter le plein écran',
                  ),
                  Expanded(
                    child: Text(_video.titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                  ),
                  _speedButton(),
                  IconButton(
                    icon: const Icon(Icons.lock_open_rounded, color: Colors.white),
                    onPressed: _toggleLock,
                    tooltip: 'Verrouiller',
                  ),
                  if (_video.sourceUrl?.isNotEmpty == true)
                    IconButton(
                        icon: const Icon(Icons.share_rounded, color: Colors.white),
                        onPressed: _share),
                  IconButton(
                    icon: Icon(
                      _isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _isFav ? const Color(0xFFE53935) : Colors.white,
                    ),
                    onPressed: _toggleFav,
                  ),
                ],
              ),
            ),

          // Center transport controls
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.args.playlist.length > 1)
                    _circleBtn(Icons.skip_previous_rounded, 30,
                        _hasPrev ? () => _playAt(_idx - 1) : null),
                  _circleBtn(Icons.replay_10_rounded, 32,
                      () => _seek(const Duration(seconds: 10), forward: false)),
                  ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: _vCtrl!,
                    builder: (_, val, __) => _circleBtn(
                      val.isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      62,
                      _togglePlay,
                    ),
                  ),
                  _circleBtn(Icons.forward_10_rounded, 32,
                      () => _seek(const Duration(seconds: 10), forward: true)),
                  if (widget.args.playlist.length > 1)
                    _circleBtn(Icons.skip_next_rounded, 30,
                        _hasNext ? () => _playAt(_idx + 1) : null),
                ],
              ),
            ),
          ),

          // Bottom scrubber
          _buildBottomBar(fullscreen: fullscreen, safe: safe),
        ],
      ),
    );
  }

  Widget _buildBottomBar({required bool fullscreen, required EdgeInsets safe}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, fullscreen ? safe.bottom + 6 : 6),
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: _vCtrl!,
        builder: (_, val, __) {
          final dur = val.duration.inMilliseconds.toDouble();
          final pos = val.position.inMilliseconds
              .toDouble()
              .clamp(0.0, dur <= 0 ? 1.0 : dur);
          return Row(
            children: [
              Text(_fmtDur(val.position),
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    activeTrackColor: AppTheme.gold,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: AppTheme.gold,
                    overlayColor: AppTheme.gold.withValues(alpha: 0.2),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: dur <= 0 ? 0 : pos,
                    max: dur <= 0 ? 1 : dur,
                    onChangeStart: (_) => _hideTimer?.cancel(),
                    onChanged: (v) {
                      if (dur > 0) _seekToFraction(v / dur);
                    },
                    onChangeEnd: (_) => _scheduleHide(),
                  ),
                ),
              ),
              Text(_fmtDur(val.duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              if (!fullscreen) ...[
                const SizedBox(width: 4),
                _speedButton(),
                IconButton(
                  icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
                  onPressed: _enterFullscreen,
                  tooltip: 'Plein écran',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildLockedOverlay() {
    return SafeArea(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: FloatingActionButton.small(
            heroTag: 'unlock',
            backgroundColor: Colors.black54,
            elevation: 0,
            onPressed: _toggleLock,
            child: const Icon(Icons.lock_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // ── Small UI pieces ──────────────────────────────────────────────────────

  Widget _speedButton() {
    return TextButton(
      onPressed: _showSpeedSheet,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 36),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.speed_rounded, size: 18, color: Colors.white),
        const SizedBox(width: 4),
        Text(_speed == 1.0 ? '1×' : '$_speed×',
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _circleBtn(IconData icon, double size, VoidCallback? onTap) {
    return IconButton(
      icon: Icon(icon, size: size, color: onTap == null ? Colors.white30 : Colors.white),
      onPressed: onTap,
      splashRadius: size * 0.7,
    );
  }

  Widget _buildSeekFlash() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(_seekLabel!,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildGestureIndicator() {
    final isBright = _gesture == _Gesture.brightness;
    final pct = (_gestureValue * 100).round();
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isBright
                  ? (pct > 50
                      ? Icons.brightness_high_rounded
                      : Icons.brightness_low_rounded)
                  : (pct == 0
                      ? Icons.volume_off_rounded
                      : pct > 50
                          ? Icons.volume_up_rounded
                          : Icons.volume_down_rounded),
              color: AppTheme.gold,
              size: 30,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: _gestureValue,
                  minHeight: 5,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.gold),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('$pct%',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ColoredBox(
      color: Colors.black,
      child: Stack(alignment: Alignment.center, children: [
        if (_video.imageMiniature?.isNotEmpty == true)
          Opacity(
            opacity: 0.35,
            child: Image.network(_video.imageMiniature!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
        const CircularProgressIndicator(color: AppTheme.gold),
      ]),
    );
  }

  Widget _buildError() {
    return ColoredBox(
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
              label: const Text('Réessayer',
                  style: TextStyle(color: Colors.white70)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24)),
              onPressed: () {
                setState(() {
                  _error = false;
                  _ready = false;
                });
                _setup();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Info section (normal mode only)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_video.titre,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.3)),
          if (videoMetaLine(_video).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(videoMetaLine(_video),
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ],
          if (_video.description?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            Text(_video.description!,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14, height: 1.6)),
          ],
          if (widget.args.playlist.length > 1) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.white12),
            const SizedBox(height: 12),
            Row(children: [
              const Text('À suivre',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('${_idx + 1} / ${widget.args.playlist.length}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            ...List.generate(widget.args.playlist.length, (i) {
              if (i == _idx) return const SizedBox.shrink();
              return _upNextTile(i);
            }),
          ],
        ],
      ),
    );
  }

  Widget _upNextTile(int index) {
    final v = widget.args.playlist[index];
    return InkWell(
      onTap: () => _playAt(index),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 132, child: VideoThumbnail(video: v, radius: 8, playSize: 30)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.25)),
                  if (videoMetaLine(v).isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(videoMetaLine(v),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ],
              ),
            ),
          ],
        ),
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
