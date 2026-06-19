import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/citation_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/content_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/app_states.dart';
import '../../../widgets/citation_list_card.dart';
import '../../../widgets/fade_slide_in.dart';
import '../../../widgets/search_field.dart';
import '../../../widgets/skeleton.dart';
import 'citation_reader_screen.dart';

class CitationsScreen extends StatefulWidget {
  const CitationsScreen({super.key});

  @override
  State<CitationsScreen> createState() => _CitationsScreenState();
}

class _CitationsScreenState extends State<CitationsScreen> {
  late final ContentService _service;
  final _searchCtrl = TextEditingController();

  List<CitationModel> _allCitations = [];
  List<CitationModel> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = ContentService(ApiClient());
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.getAllCitations();
    if (mounted) {
      setState(() {
        _allCitations = data;
        _filtered = data;
        _loading = false;
      });
    }
  }

  void _search(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? _allCitations
          : _allCitations
              .where((c) =>
                  c.texte.toLowerCase().contains(query.toLowerCase()) ||
                  (c.source?.toLowerCase().contains(query.toLowerCase()) ?? false))
              .toList();
    });
  }

  void _openReader(int index) {
    context.push('/citations/lecture',
        extra: CitationReaderArgs(_filtered, index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Citations')),
      body: Column(
        children: [
          SearchField(controller: _searchCtrl, hint: 'Rechercher une citation…', onChanged: _search),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const SkeletonList();

    if (_filtered.isEmpty) {
      return EmptyState(
        icon: Icons.format_quote_outlined,
        message: _searchCtrl.text.isEmpty ? 'Aucune citation disponible' : 'Aucun résultat',
        hint: _searchCtrl.text.isEmpty ? null : 'pour « ${_searchCtrl.text} »',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
        itemCount: _filtered.length,
        itemBuilder: (context, i) => FadeSlideIn(
          delay: Duration(milliseconds: 30 * (i % 8)),
          child: CitationListCard(
            citation: _filtered[i],
            onTap: () => _openReader(i),
          ),
        ),
      ),
    );
  }
}
