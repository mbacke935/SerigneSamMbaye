import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/citation_model.dart';
import '../../../core/theme/app_theme.dart';

/// Arguments passés via `GoRouter.extra` à l'écran de lecture de citations.
class CitationReaderArgs {
  final List<CitationModel> citations;
  final int initialIndex;
  const CitationReaderArgs(this.citations, this.initialIndex);
}

/// Lecture plein écran des citations : grand texte serif, fond vert apaisant,
/// navigation par glissement vertical, copie dans le presse-papiers.
class CitationReaderScreen extends StatefulWidget {
  final List<CitationModel> citations;
  final int initialIndex;

  const CitationReaderScreen({
    super.key,
    required this.citations,
    this.initialIndex = 0,
  });

  @override
  State<CitationReaderScreen> createState() => _CitationReaderScreenState();
}

class _CitationReaderScreenState extends State<CitationReaderScreen> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _copy() {
    final c = widget.citations[_index];
    final text = c.source != null && c.source!.isNotEmpty
        ? '« ${c.texte} »\n— ${c.source}'
        : '« ${c.texte} »';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Citation copiée.')),
    );
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
        title: Text(
          '${_index + 1} / ${widget.citations.length}',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Copier',
            onPressed: _copy,
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
        child: PageView.builder(
          controller: _controller,
          scrollDirection: Axis.vertical,
          onPageChanged: (i) => setState(() => _index = i),
          itemCount: widget.citations.length,
          itemBuilder: (context, i) => _CitationPage(citation: widget.citations[i]),
        ),
      ),
    );
  }
}

class _CitationPage extends StatelessWidget {
  final CitationModel citation;
  const _CitationPage({required this.citation});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.format_quote_rounded, color: AppTheme.gold, size: 44),
            const SizedBox(height: AppSpacing.lg),
            Text(
              citation.texte,
              textAlign: TextAlign.center,
              style: AppTheme.serif(
                fontSize: 24,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                height: 1.6,
              ),
            ),
            if (citation.source != null && citation.source!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(width: 32, height: 1.5, color: AppTheme.gold.withValues(alpha: 0.6)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                citation.source!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppTheme.gold, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Glissez vers le haut',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
