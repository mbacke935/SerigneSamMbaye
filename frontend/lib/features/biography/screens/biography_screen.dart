import 'package:flutter/material.dart';
import '../../../core/models/biographie_model.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/content_service.dart';
import '../../../core/theme/app_theme.dart';

class BiographyScreen extends StatefulWidget {
  const BiographyScreen({super.key});

  @override
  State<BiographyScreen> createState() => _BiographyScreenState();
}

class _BiographyScreenState extends State<BiographyScreen> {
  late final ContentService _service;
  List<BiographieModel> _biographies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = ContentService(ApiClient());
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.getBiographies();
    if (mounted) {
      setState(() {
        _biographies = data;
        _loading = false;
      });
    }
  }

  // First biography with a non-null image, or null
  String? get _heroImage {
    for (final b in _biographies) {
      if (b.image != null && b.image!.isNotEmpty) return b.image;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Biographie')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_biographies.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Biographie')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_rounded,
                  size: 64, color: AppTheme.textSecondary),
              const SizedBox(height: 16),
              Text('Biographie non disponible',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNameHeader(context),
                const Divider(height: 1, indent: 24, endIndent: 24),
                ..._biographies.asMap().entries.map((entry) {
                  final i = entry.key;
                  final bio = entry.value;
                  return _BiographySection(
                    biographie: bio,
                    isLast: i == _biographies.length - 1,
                  );
                }),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: _heroImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _heroImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _heroPrimaryBg(),
                  ),
                  // gradient overlay pour lisibilité
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.primary.withValues(alpha: 0.85),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              )
            : _heroPrimaryBg(),
      ),
    );
  }

  Widget _heroPrimaryBg() {
    return Container(
      color: AppTheme.primary,
      child: const Center(
        child: Icon(Icons.menu_book_rounded, color: AppTheme.gold, size: 72),
      ),
    );
  }

  Widget _buildNameHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.gold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Serigne Sam Mbaye',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                ),
                Text(
                  'Érudit · Guide spirituel · Éducateur',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.3,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BiographySection extends StatelessWidget {
  final BiographieModel biographie;
  final bool isLast;

  const _BiographySection({required this.biographie, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              const Icon(Icons.bookmark_rounded,
                  color: AppTheme.gold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  biographie.titre,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Section content
          Text(
            biographie.contenu,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  height: 1.8,
                ),
          ),
          if (!isLast) ...[
            const SizedBox(height: 24),
            const Divider(color: Color(0xFFE5E7EB)),
          ],
        ],
      ),
    );
  }
}
