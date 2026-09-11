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