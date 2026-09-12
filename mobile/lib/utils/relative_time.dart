import 'package:intl/intl.dart';

/// Formate une date en temps relatif ("il y a 5 min", "hier"), comme dans
/// la plupart des apps de presse — plus rapide à lire qu'une date complète.
/// Au-delà d'une semaine, retombe sur une date courte.
String formatRelativeTime(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inSeconds < 0) {
    // Horloge légèrement désynchronisée ou article "à venir" : affichage neutre.
    return DateFormat('d MMM', 'fr_FR').format(date);
  }
  if (diff.inSeconds < 60) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays == 1) return 'hier';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';

  final sameYear = date.year == now.year;
  return DateFormat(sameYear ? 'd MMM' : 'd MMM yyyy', 'fr_FR').format(date);
}
