import '../data/glossary_data.dart';

const _foldMap = {
  'ı': 'i', 'İ': 'i', 'ş': 's', 'Ş': 's', 'ğ': 'g', 'Ğ': 'g', //
  'ü': 'u', 'Ü': 'u', 'ö': 'o', 'Ö': 'o', 'ç': 'c', 'Ç': 'c',
  'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ñ': 'n',
  'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ú': 'u', 'Ñ': 'n',
};

/// Lower-cases and strips accents / Turkish dotted-dotless i so that
/// "Göreli" matches "goreli" and "İ" matches "i".
String normalizeGlossaryText(String input) {
  final b = StringBuffer();
  for (final r in input.runes) {
    final ch = String.fromCharCode(r);
    b.write(_foldMap[ch] ?? ch.toLowerCase());
  }
  return b.toString().trim();
}

String glossaryLanguage(String languageCode) =>
    glossaryLocales.contains(languageCode)
    ? languageCode
    : glossaryFallbackLocale;

/// Whether [term] matches [query] (as typed by the user). Matches the term's
/// names in every language, its aliases, and the description in
/// [languageCode]. An empty query matches everything.
bool glossaryTermMatches(GlossaryTerm term, String query, String languageCode) {
  final q = normalizeGlossaryText(query);
  if (q.isEmpty) return true;
  final lang = glossaryLanguage(languageCode);
  final haystack = <String>[
    term.id,
    for (final e in term.entries.values) e.name,
    ...term.aliases,
    term.entry(lang).text,
  ];
  return haystack.any((s) => normalizeGlossaryText(s).contains(q));
}

/// Terms grouped by category (in enum order), filtered by [query]. Categories
/// with no match are omitted.
Map<GlossaryCategory, List<GlossaryTerm>> groupGlossary(
  String query,
  String languageCode,
) {
  final out = <GlossaryCategory, List<GlossaryTerm>>{};
  for (final c in GlossaryCategory.values) {
    final list = [
      for (final t in glossaryTerms)
        if (t.category == c && glossaryTermMatches(t, query, languageCode)) t,
    ];
    if (list.isNotEmpty) out[c] = list;
  }
  return out;
}

GlossaryTerm? glossaryTermById(String? id) {
  if (id == null) return null;
  for (final t in glossaryTerms) {
    if (t.id == id) return t;
  }
  return null;
}
