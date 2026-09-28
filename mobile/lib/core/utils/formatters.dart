import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');

  static String formatCurrency(double amount) {
    return '${AppConstants.currencySymbol}${_currencyFormat.format(amount)}';
  }

  static String formatCurrencyWithDecimals(double amount) {
    final format = NumberFormat('#,##0.00', 'en_US');
    return '${AppConstants.currencySymbol}${format.format(amount)}';
  }

  static String formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  static String formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }

  static String formatTime(DateTime dt) {
    return DateFormat('hh:mm a').format(dt);
  }
}
