import 'package:intl/intl.dart';

class Formatter {
  static String currency(double amount) {
    final formatter = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    return formatter.format(amount);
  }

  static String chips(double value) {
    return '${value.toStringAsFixed(0)} chips';
  }

  static String date(DateTime date) {
    return DateFormat('dd MMM yyyy – hh:mm a').format(date);
  }
}
