const _from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
const _to   = 'aaaaaaceeeeiiiinooooouuuuyy';

/// "  Le Phare d’Orane " -> "le phare d'orane"
String normalizeCityName(String? input) {
  if (input == null) return '';
  final s = input
      .trim()
      .toLowerCase()
      .replaceAll('’', "'")
      .replaceAll('‘', "'")
      .replaceAll('œ', 'oe')
      .replaceAll('\u00A0', ' ');
  final b = StringBuffer();
  for (final r in s.runes) {
    final c = String.fromCharCode(r);
    final i = _from.indexOf(c);
    b.write(i >= 0 ? _to[i] : c);
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}