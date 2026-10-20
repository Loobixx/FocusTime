// lib/utils/text_formatters.dart

String formatMinutesToHours(int totalMinutes) {
  if (totalMinutes <= 0) return '0 min';

  int hours = totalMinutes ~/ 60;
  int minutes = totalMinutes % 60;

  if (hours == 0) {
    return '$minutes min';
  } else if (minutes == 0) {
    return '${hours}h';
  } else {
    return '${hours}h${minutes.toString().padLeft(2, '0')}';
  }
}

const String _from = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
const String _to   = 'aaaaaaceeeeiiiinooooouuuuyy';

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