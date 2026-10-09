import 'salary.dart';

/// One slab of the progressive income tax table.
class TaxSlab {
  const TaxSlab({
    required this.upperLimit,
    required this.fixedTax,
    required this.rate,
    required this.slabStart,
  });

  /// Upper limit of the slab (annual income). `double.infinity` for the last slab.
  final double upperLimit;

  /// Fixed amount of tax payable before the percentage is applied.
  final double fixedTax;

  /// Percentage charged on the income exceeding [slabStart].
  final double rate;

  /// Income level at which this slab starts.
  final double slabStart;
}

/// The outcome of a salary calculation, shown on the result screen.
class SalaryBreakdown {
  const SalaryBreakdown({
    required this.grossSalary,
    required this.taxDeduction,
  });

  final double grossSalary;
  final double taxDeduction;

  /// Net Monthly Income = Gross Salary - Tax Deduction.
  double get netMonthlyIncome => grossSalary - taxDeduction;
}

/// Calculates income tax using the progressive slab rates for salaried
/// individuals (Pakistan, tax year 2025-26).
///
/// The slabs are defined on annual income, so the monthly gross salary is
/// annualised first and the resulting tax is divided back by 12.
class TaxCalculator {
  static const List<TaxSlab> slabs = <TaxSlab>[
    TaxSlab(upperLimit: 600000, fixedTax: 0, rate: 0, slabStart: 0),
    TaxSlab(upperLimit: 1200000, fixedTax: 0, rate: 1, slabStart: 600000),
    TaxSlab(upperLimit: 2200000, fixedTax: 6000, rate: 11, slabStart: 1200000),
    TaxSlab(upperLimit: 3200000, fixedTax: 116000, rate: 23, slabStart: 2200000),
    TaxSlab(upperLimit: 4100000, fixedTax: 346000, rate: 30, slabStart: 3200000),
    TaxSlab(
      upperLimit: double.infinity,
      fixedTax: 616000,
      rate: 35,
      slabStart: 4100000,
    ),
  ];

  /// Monthly tax deduction for the given [annualIncome].
  static double annualTax(double annualIncome) {
    final TaxSlab slab = slabs.firstWhere(
      (TaxSlab slab) => annualIncome <= slab.upperLimit,
    );
    return slab.fixedTax + (annualIncome - slab.slabStart) * slab.rate / 100;
  }

  /// Builds the full breakdown (gross, tax, net) for the entered [salary].
  static SalaryBreakdown calculate(Salary salary) {
    final double gross = salary.grossSalary;
    final double monthlyTax = annualTax(gross * 12) / 12;
    return SalaryBreakdown(grossSalary: gross, taxDeduction: monthlyTax);
  }
}
