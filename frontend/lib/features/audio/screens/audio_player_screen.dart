import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/models/audio_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/audio_player_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/favori_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/duration_ext.dart';
import '../../../widgets/equalizer_bars.dart';

class AudioPlayerScreen extends StatefulWidget {
  final AudioModel audio;

  const AudioPlayerScreen({super.key, required this.audio});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final _playerService = AudioPlayerService();
  final _client = ApiClient();
  late final FavoriService _favoriService;
  late final AuthService _authService;

  bool _isFavorited = false;
  bool _dragging = false;
  double _dragValue = 0;

  @override
  void initState() {
    super.initState();
    _favoriService = FavoriService(_client);
    _authService = AuthService(_client);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    await _playerService.playAudio(widget.audio);
    _loadFavoriState();
  }

  Future<void> _loadFavoriState() async {
    if (!await _authService.isLoggedIn()) return;
    final ids = await _favoriService.getFavoritedIds('audio');
    if (mounted) setState(() => _isFavorited = ids.contains(widget.audio.id));
  }

  Future<void> _toggleFavori() async {
    final loggedIn = await _authService.isLoggedIn();
    if (!loggedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour ajouter aux favoris.')),
      );
      return;
    }
    final isFav = await _favoriService.toggle('audio', widget.audio.id);
    if (mounted) setState(() => _isFavorited = isFav);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('En lecture',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorited ? const Color(0xFFE53935) : Colors.white,
            ),
            onPressed: _toggleFavori,
            tooltip: 'Favoris',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryLight, AppTheme.primary, Color(0xFF0A2A1F)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildCover(),
                const SizedBox(height: 28),
                _buildTitle(),
                const SizedBox(height: 16),
                _buildEqualizer(),
                const Spacer(),
                _buildProgressBar(),
                const SizedBox(height: 4),
                _buildControls(),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    final thumbnail = widget.audio.imageMiniature;
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        color: Colors.white.withValues(alpha: 0.08),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: thumbnail != null && thumbnail.isNotEmpty
          ? Image.network(thumbnail, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _coverPlaceholder())
          : _coverPlaceholder(),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.05),
      child: const Icon(Icons.headphones_rounded, color: AppTheme.gold, size: 84),
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.audio.titre,
      textAlign: TextAlign.center,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 21,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
    );
  }

  Widget _buildEqualizer() {
    return StreamBuilder<PlayerState>(
      stream: _playerService.playerStateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        return EqualizerBars(
          playing: isPlaying,
          color: AppTheme.gold,
          barCount: 7,
          height: 26,
          barWidth: 4,
          spacing: 5,
        );
      },
    );
  }

  Widget _buildProgressBar() {
    return StreamBuilder<Duration?>(
      stream: _playerService.durationStream,
      builder: (context, durSnap) {
        final total = durSnap.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: _playerService.positionStream,
          builder: (context, posSnap) {
            final position = posSnap.data ?? Duration.zero;
            final sliderMax = total.inMilliseconds.toDouble();
            final sliderValue = _dragging
                ? _dragValue
                : position.inMilliseconds
                    .toDouble()
                    .clamp(0.0, sliderMax > 0 ? sliderMax : 1.0);

            return Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    activeTrackColor: AppTheme.gold,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
                    thumbColor: AppTheme.gold,
                    overlayColor: AppTheme.gold.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: sliderValue,
                    min: 0,
                    max: sliderMax > 0 ? sliderMax : 1.0,
                    onChangeStart: (v) => setState(() {
                      _dragging = true;
                      _dragValue = v;
                    }),
                    onChanged: (v) => setState(() => _dragValue = v),
                    onChangeEnd: (v) {
                      setState(() => _dragging = false);
                      _playerService.seekTo(Duration(milliseconds: v.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(position.mmss,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                      Text(total.mmss,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildControls() {
    return StreamBuilder<PlayerState>(
      stream: _playerService.playerStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data;
        final isPlaying = state?.playing ?? false;
        final isLoading = state?.processingState == ProcessingState.loading ||
            state?.processingState == ProcessingState.buffering;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSpeedButton(),
            IconButton(
              icon: const Icon(Icons.replay_10_rounded),
              color: Colors.white,
              iconSize: 34,
              onPressed: _playerService.seekBackward,
            ),
            GestureDetector(
              onTap: isLoading ? null : _playerService.togglePlayPause,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: AppTheme.gold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gold.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(22),
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.forward_10_rounded),
              color: Colors.white,
              iconSize: 34,
              onPressed: _playerService.seekForward,
            ),
            SizedBox(
              width: 48,
              child: IconButton(
                icon: const Icon(Icons.stop_rounded),
                color: Colors.white70,
                iconSize: 28,
                onPressed: () {
                  _playerService.stop();
                  Navigator.of(context).maybePop();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSpeedButton() {
    return SizedBox(
      width: 48,
      child: ValueListenableBuilder<double>(
        valueListenable: _playerService.speedListenable,
        builder: (context, speed, _) {
          return TextButton(
            onPressed: _playerService.cycleSpeed,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
            child: Text(
              '${_fmt(speed)}x',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          );
        },
      ),
    );
  }

  String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}
