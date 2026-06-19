import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/search_result_model.dart';
import '../../../core/models/audio_model.dart';
import '../../../core/models/video_model.dart';
import '../../../core/models/biographie_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/audio_player_service.dart';
import '../../../core/services/search_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/citation_list_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final _service = SearchService(ApiClient());
  final _playerService = AudioPlayerService();

  SearchResultModel? _result;
  bool _loading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().length < 2) {
      setState(() { _result = null; _loading = false; });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(query));
  }

  Future<void> _search(String query) async {
    final result = await _service.search(query);
    if (mounted) setState(() { _result = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Rechercher audios, vidéos, citations…',
            hintStyle: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
                fontSize: 14),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
          ),
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _searchCtrl.clear();
                _onChanged('');
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchCtrl.text.trim().isEmpty) {
      return _buildHint('Tapez au moins 2 caractères pour rechercher',
          Icons.search_rounded);
    }

    if (_searchCtrl.text.trim().length == 1) {
      return _buildHint('Un caractère de plus…', Icons.keyboard_rounded);
    }

    if (_result == null) {
      return _buildHint('Aucun résultat trouvé', Icons.sentiment_dissatisfied_rounded);
    }

    if (_result!.isEmpty) {
      return _buildHint(
          'Aucun résultat pour "${_result!.query}"',
          Icons.search_off_rounded);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _buildCount(),
        if (_result!.audios.isNotEmpty) ...[
          _SectionHeader(title: 'Audios', count: _result!.audios.length),
          ..._result!.audios.map((a) => _AudioResult(
                audio: a,
                onTap: () => _openAudio(a),
              )),
        ],
        if (_result!.videos.isNotEmpty) ...[
          _SectionHeader(title: 'Vidéos', count: _result!.videos.length),
          ..._result!.videos.map((v) => _VideoResult(
                video: v,
                onTap: () => context.push('/videos/lecteur', extra: v),
              )),
        ],
        if (_result!.citations.isNotEmpty) ...[
          _SectionHeader(
              title: 'Citations', count: _result!.citations.length),
          ..._result!.citations.map((c) => CitationListCard(citation: c)),
        ],
        if (_result!.biographies.isNotEmpty) ...[
          _SectionHeader(
              title: 'Biographie', count: _result!.biographies.length),
          ..._result!.biographies
              .map((b) => _BiographieResult(
                    biographie: b,
                    onTap: () => context.push('/biographie'),
                  )),
        ],
      ],
    );
  }

  Widget _buildCount() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        '${_result!.totalCount} résultat${_result!.totalCount > 1 ? 's' : ''} pour "${_result!.query}"',
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }

  Widget _buildHint(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Future<void> _openAudio(AudioModel audio) async {
    await _playerService.playAudio(audio);
    if (mounted) context.push('/audios/lecteur', extra: audio);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Row(
        children: [
          Text(title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  )),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }
}

class _AudioResult extends StatelessWidget {
  final AudioModel audio;
  final VoidCallback onTap;
  const _AudioResult({required this.audio, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: audio.imageMiniature != null
            ? Image.network(audio.imageMiniature!,
                width: 48, height: 48, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _audioPlaceholder())
            : _audioPlaceholder(),
      ),
      title: Text(audio.titre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: audio.dureeFormatee.isNotEmpty
          ? Text(audio.dureeFormatee,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary))
          : null,
      trailing: const Icon(Icons.play_circle_outline_rounded,
          color: AppTheme.primary),
    );
  }

  Widget _audioPlaceholder() => Container(
        width: 48, height: 48,
        color: AppTheme.primary.withValues(alpha: 0.08),
        child: const Icon(Icons.headphones_rounded,
            color: AppTheme.primary, size: 22),
      );
}

class _VideoResult extends StatelessWidget {
  final VideoModel video;
  final VoidCallback onTap;
  const _VideoResult({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: video.imageMiniature != null
            ? Image.network(video.imageMiniature!,
                width: 48, height: 48, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _videoPlaceholder())
            : _videoPlaceholder(),
      ),
      title: Text(video.titre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: video.dureeFormatee.isNotEmpty
          ? Text(video.dureeFormatee,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary))
          : null,
      trailing: const Icon(Icons.play_circle_outline_rounded,
          color: AppTheme.primary),
    );
  }

  Widget _videoPlaceholder() => Container(
        width: 48, height: 48,
        color: AppTheme.dark.withValues(alpha: 0.08),
        child: const Icon(Icons.videocam_rounded,
            color: AppTheme.primary, size: 22),
      );
}

class _BiographieResult extends StatelessWidget {
  final BiographieModel biographie;
  final VoidCallback onTap;
  const _BiographieResult({required this.biographie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.menu_book_rounded,
            color: AppTheme.primary, size: 22),
      ),
      title: Text(biographie.titre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          color: AppTheme.textSecondary, size: 14),
    );
  }
}
