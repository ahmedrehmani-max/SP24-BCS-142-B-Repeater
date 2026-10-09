/// The salary details entered by the user on the input screen.
///
/// All amounts are monthly figures in PKR.
class Salary {
  const Salary({
    required this.basicSalary,
    required this.houseRentAllowance,
    required this.medicalAllowance,
    required this.travelAllowance,
  });

  final double basicSalary;
  final double houseRentAllowance;
  final double medicalAllowance;
  final double travelAllowance;

  /// Gross monthly salary = basic salary + all allowances.
  double get grossSalary =>
      basicSalary + houseRentAllowance + medicalAllowance + travelAllowance;
}
