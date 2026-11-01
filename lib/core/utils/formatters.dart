import 'package:intl/intl.dart';

/// Formats numbers with thousand separators, e.g. 7850 -> "7,850".
class Fmt {
  Fmt._();

  static final NumberFormat _number = NumberFormat.decimalPattern();

  static String number(num value) => _number.format(value);
}
