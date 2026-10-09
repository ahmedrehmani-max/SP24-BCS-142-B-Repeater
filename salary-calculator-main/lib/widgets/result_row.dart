import 'package:flutter/material.dart';

import '../utils/currency.dart';

/// A single "label — amount" line on the result screen.
class ResultRow extends StatelessWidget {
  const ResultRow({
    super.key,
    required this.label,
    required this.amount,
    this.color,
    this.highlight = false,
  });

  final String label;
  final double amount;
  final Color? color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: textTheme.titleMedium),
          Text(
            formatCurrency(amount),
            style: (highlight ? textTheme.titleLarge : textTheme.titleMedium)
                ?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
