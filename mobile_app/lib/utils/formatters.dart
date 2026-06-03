import 'package:intl/intl.dart';

String formatCurrency(dynamic amount) {
  int value = 0;
  if (amount is num) {
    value = amount.toInt();
  } else if (amount is String) {
    value = int.tryParse(amount.replaceAll('.', '').replaceAll(',', '')) ?? 0;
  }

  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp. ',
    decimalDigits: 0,
  ).format(value);
}