import 'package:flutter/material.dart';
import '../../../core/models/citation_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/content_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../widgets/citation_list_card.dart';

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
                  (c.source?.toLowerCase().contains(query.toLowerCase()) ??
                      false))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Citations')),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildList()),
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
          hintText: 'Rechercher une citation...',
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

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.format_quote_outlined,
                size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isEmpty
                  ? 'Aucune citation disponible'
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
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _filtered.length,
        itemBuilder: (context, i) =>
            CitationListCard(citation: _filtered[i]),
      ),
    );
  }
}
