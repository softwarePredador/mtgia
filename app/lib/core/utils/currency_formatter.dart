/// Small dependency-free formatter for the Portuguese ManaLoom interface.
///
/// The API stores deck prices as USD today, but the formatter keeps the
/// currency code explicit so a future BRL/EUR source does not inherit a
/// misleading dollar sign.
abstract final class CurrencyFormatter {
  static String format(
    num value, {
    String currencyCode = 'USD',
    bool compact = false,
  }) {
    final requestedCode = currencyCode.trim().toUpperCase();
    final normalizedCode = requestedCode.isEmpty ? 'USD' : requestedCode;
    final prefix = switch (normalizedCode) {
      'USD' => 'US\$',
      'BRL' => 'R\$',
      'R\$' => 'R\$',
      'EUR' => '€',
      _ => normalizedCode,
    };
    final amount = value.toDouble();

    if (compact && amount.abs() >= 1000000) {
      return '$prefix ${_decimal(amount / 1000000, 1)} mi';
    }
    if (compact && amount.abs() >= 1000) {
      return '$prefix ${_decimal(amount / 1000, 1)} mil';
    }
    return '$prefix ${_decimal(amount, 2, groupThousands: true)}';
  }

  static String _decimal(
    double value,
    int decimals, {
    bool groupThousands = false,
  }) {
    final fixed = value.toStringAsFixed(decimals);
    final parts = fixed.split('.');
    var integer = parts.first;
    if (groupThousands) {
      final negative = integer.startsWith('-');
      final digits = negative ? integer.substring(1) : integer;
      final grouped = digits.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
      integer = negative ? '-$grouped' : grouped;
    }
    if (decimals == 0) return integer;
    return '$integer,${parts.last}';
  }
}
