import 'package:flutter/material.dart';

import '../models/tax_calculator.dart';
import '../widgets/result_row.dart';

/// Result screen: shows the Tax Deduction first, then the Net Monthly Income.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.breakdown});

  final SalaryBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Result'),
        centerTitle: true,
        backgroundColor: colors.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ResultRow(
                        label: 'Gross Salary',
                        amount: breakdown.grossSalary,
                      ),
                      const Divider(),
                      ResultRow(
                        label: 'Tax Deduction',
                        amount: breakdown.taxDeduction,
                        color: colors.error,
                      ),
                      const Divider(),
                      ResultRow(
                        label: 'Net Monthly Income',
                        amount: breakdown.netMonthlyIncome,
                        color: colors.primary,
                        highlight: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tax is calculated on the annual gross salary using the '
                'progressive income tax slabs for salaried individuals, then '
                'divided by 12 for the monthly deduction.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Back to Form'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
