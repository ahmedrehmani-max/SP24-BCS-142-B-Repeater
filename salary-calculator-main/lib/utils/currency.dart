/// Formats an [amount] as a PKR string with thousands separators,
/// e.g. `157350.5` becomes `PKR 157,350.50`.
String formatCurrency(double amount) {
  final String fixed = amount.toStringAsFixed(2);
  final List<String> parts = fixed.split('.');
  final String digits = parts[0];

  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }

  return 'PKR ${buffer.toString()}.${parts[1]}';
}
