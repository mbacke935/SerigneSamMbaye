import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/models/audio_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/audio_player_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/favori_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/duration_ext.dart';

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
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Lecture',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildCover(),
              const SizedBox(height: 32),
              _buildTitle(),
              const Spacer(),
              _buildProgressBar(),
              const SizedBox(height: 8),
              _buildControls(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCover() {
    final thumbnail = widget.audio.imageMiniature;
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.08),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
      child: const Icon(Icons.headphones_rounded,
          color: AppTheme.gold, size: 80),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.audio.titre,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        if (widget.audio.dureeFormatee.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            widget.audio.dureeFormatee,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
        ],
      ],
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
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    activeTrackColor: AppTheme.gold,
                    inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
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
                      _playerService
                          .seekTo(Duration(milliseconds: v.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        position.mmss,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12),
                      ),
                      Text(
                        total.mmss,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12),
                      ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rewind 15s
            IconButton(
              icon: const Icon(Icons.replay_10_rounded),
              color: Colors.white,
              iconSize: 36,
              onPressed: _playerService.seekBackward,
            ),
            const SizedBox(width: 16),
            // Play / Pause
            GestureDetector(
              onTap: isLoading ? null : _playerService.togglePlayPause,
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppTheme.gold,
                  shape: BoxShape.circle,
                ),
                child: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Forward 15s
            IconButton(
              icon: const Icon(Icons.forward_10_rounded),
              color: Colors.white,
              iconSize: 36,
              onPressed: _playerService.seekForward,
            ),
          ],
        );
      },
    );
  }
}
