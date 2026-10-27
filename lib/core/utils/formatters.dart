import 'package:intl/intl.dart';

/// Formats an API-provided amount; never used to compute totals.
String formatMoney(num amount, String symbol) {
  final hasFraction = amount != amount.roundToDouble();
  final number = NumberFormat.decimalPatternDigits(
    locale: 'en',
    decimalDigits: hasFraction ? 2 : 0,
  ).format(amount);
  return symbol.isEmpty ? number : '$number $symbol';
}

String formatDate(DateTime? date, String locale, {bool withTime = false}) {
  if (date == null) return '';
  final pattern = withTime ? DateFormat.yMMMd(locale).add_jm() : DateFormat.yMMMd(locale);
  return pattern.format(date);
}
