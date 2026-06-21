import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';
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

  // Piste affichée (peut changer si playlist auto-avance)
  AudioModel get _currentAudio =>
      _playerService.currentAudio ?? widget.audio;

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
    HapticFeedback.lightImpact();
    final loggedIn = await _authService.isLoggedIn();
    if (!loggedIn) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour ajouter aux favoris.')),
      );
      return;
    }
    final isFav = await _favoriService.toggle('audio', _currentAudio.id);
    if (mounted) setState(() => _isFavorited = isFav);
  }

  void _share() {
    Share.share(
      'Écouter « ${_currentAudio.titre} » — Serigne Sam Mbaye\n${_currentAudio.sourceUrl ?? ""}',
      subject: _currentAudio.titre,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudioModel?>(
      valueListenable: _playerService.currentAudioListenable,
      builder: (context, currentAudio, _) {
        final audio = currentAudio ?? widget.audio;
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
                icon: const Icon(Icons.share_rounded, color: Colors.white70),
                onPressed: _share,
                tooltip: 'Partager',
              ),
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
                    _buildCover(audio),
                    const SizedBox(height: 28),
                    _buildTitle(audio),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ValueListenableBuilder<String?>(
                        valueListenable: _playerService.errorListenable,
                        builder: (context, error, _) {
                          if (error != null) return _buildError(error);
                          return Column(
                            children: [
                              _buildEqualizer(),
                              const Spacer(),
                              _buildProgressBar(),
                              const SizedBox(height: 4),
                              _buildControls(),
                              const SizedBox(height: 36),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCover(AudioModel audio) {
    final thumbnail = audio.imageMiniature;
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
          ? CachedNetworkImage(
              imageUrl: thumbnail,
              fit: BoxFit.cover,
              placeholder: (_, __) => _coverPlaceholder(),
              errorWidget: (_, __, ___) => _coverPlaceholder(),
            )
          : _coverPlaceholder(),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.05),
      child: const Icon(Icons.headphones_rounded, color: AppTheme.gold, size: 84),
    );
  }

  Widget _buildTitle(AudioModel audio) {
    return Text(
      audio.titre,
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

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.gold, size: 56),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: _initPlayer,
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.gold),
            label: const Text('Réessayer',
                style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildEqualizer() {
    return StreamBuilder<PlayerState>(
      stream: _playerService.playerStateStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data?.playing ?? false;
        return Container(
          height: 56,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPlaying ? Icons.graphic_eq_rounded : Icons.equalizer_rounded,
                color: AppTheme.gold.withValues(alpha: 0.8),
                size: 18,
              ),
              const SizedBox(width: 12),
              EqualizerBars(
                playing: isPlaying,
                color: AppTheme.gold,
                barCount: 9,
                height: 30,
                barWidth: 5,
                spacing: 6,
              ),
            ],
          ),
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

        return Column(
          children: [
            Row(
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
                  onTap: isLoading
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          _playerService.togglePlayPause();
                        },
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
            ),
            // Prev / Next si playlist active
            ValueListenableBuilder<AudioModel?>(
              valueListenable: _playerService.currentAudioListenable,
              builder: (context, _, __) {
                final hasPrev = _playerService.hasPrevious;
                final hasNext = _playerService.hasNext;
                if (!hasPrev && !hasNext) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.skip_previous_rounded,
                            color: hasPrev ? Colors.white : Colors.white24, size: 32),
                        onPressed: hasPrev ? _playerService.playPrevious : null,
                        tooltip: 'Précédent',
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: Icon(Icons.skip_next_rounded,
                            color: hasNext ? Colors.white : Colors.white24, size: 32),
                        onPressed: hasNext ? _playerService.playNext : null,
                        tooltip: 'Suivant',
                      ),
                    ],
                  ),
                );
              },
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
