import 'package:intl/intl.dart';

final NumberFormat _formatMontant = NumberFormat.currency(
  locale: 'fr_FR',
  symbol: 'FCFA',
  decimalDigits: 0,
);

final DateFormat _formatDate = DateFormat('d MMM yyyy', 'fr_FR');
final DateFormat _formatDateHeure = DateFormat('d MMM yyyy, HH:mm', 'fr_FR');

String formaterMontant(num montant) => _formatMontant.format(montant);

String formaterDate(DateTime date) => _formatDate.format(date);

String formaterDateHeure(DateTime date) => _formatDateHeure.format(date);
