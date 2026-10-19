import 'package:flutter/material.dart';

import '../data/glossary_data.dart';
import '../l10n/app_localizations.dart';
import '../utils/glossary_logic.dart';

/// Searchable, grouped glossary of technical terms. [initialTermId] deep-links
/// to a term: it is scrolled into view and expanded.
class GlossaryScreen extends StatefulWidget {
  final String? initialTermId;

  const GlossaryScreen({super.key, this.initialTermId});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final _controller = TextEditingController();
  final _keys = <String, GlobalKey>{};
  String _query = '';
  late final String? _deepLinkId = glossaryTermById(widget.initialTermId)?.id;

  @override
  void initState() {
    super.initState();
    final id = _deepLinkId;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[id]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            alignment: 0.1,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final lang = glossaryLanguage(Localizations.localeOf(context).languageCode);
    final groups = groupGlossary(_query, lang);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.glossaryTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.glossarySearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_query.trim().isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        l10n.glossaryIntro,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (groups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text(l10n.glossaryNoResults)),
                    ),
                  for (final g in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                      child: Text(
                        glossaryCategoryTitles[g.key]![lang]!,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    for (final term in g.value)
                      _TermTile(
                        key: _keys.putIfAbsent(term.id, GlobalKey.new),
                        term: term,
                        lang: lang,
                        initiallyExpanded: term.id == _deepLinkId,
                      ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermTile extends StatelessWidget {
  final GlossaryTerm term;
  final String lang;
  final bool initiallyExpanded;

  const _TermTile({
    super.key,
    required this.term,
    required this.lang,
    required this.initiallyExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final entry = term.entry(lang);
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      title: Text(
        entry.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      expandedAlignment: Alignment.centerLeft,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.text, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// Opens the glossary, optionally scrolled to and expanded on [termId].
Future<void> openGlossary(BuildContext context, {String? termId}) =>
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GlossaryScreen(initialTermId: termId)),
    );
