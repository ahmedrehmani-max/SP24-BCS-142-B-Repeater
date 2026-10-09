import 'package:flutter/material.dart';

import '../models/salary.dart';
import '../models/tax_calculator.dart';
import '../widgets/salary_input_field.dart';
import 'result_screen.dart';

/// Input screen: collects the salary details and validates them.
class SalaryFormScreen extends StatefulWidget {
  const SalaryFormScreen({super.key});

  @override
  State<SalaryFormScreen> createState() => _SalaryFormScreenState();
}

class _SalaryFormScreenState extends State<SalaryFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _basicSalaryController = TextEditingController();
  final TextEditingController _houseRentController = TextEditingController();
  final TextEditingController _medicalController = TextEditingController();
  final TextEditingController _travelController = TextEditingController();

  @override
  void dispose() {
    _basicSalaryController.dispose();
    _houseRentController.dispose();
    _medicalController.dispose();
    _travelController.dispose();
    super.dispose();
  }

  double _amountOf(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  /// Validates the form and, if valid, opens the result screen.
  void _calculate() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final Salary salary = Salary(
      basicSalary: _amountOf(_basicSalaryController),
      houseRentAllowance: _amountOf(_houseRentController),
      medicalAllowance: _amountOf(_medicalController),
      travelAllowance: _amountOf(_travelController),
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            ResultScreen(breakdown: TaxCalculator.calculate(salary)),
      ),
    );
  }

  /// Clears every field and removes the validation messages.
  void _reset() {
    _formKey.currentState!.reset();
    _basicSalaryController.clear();
    _houseRentController.clear();
    _medicalController.clear();
    _travelController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salary Calculator'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Enter your monthly salary details',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                SalaryInputField(
                  label: 'Basic Salary',
                  icon: Icons.account_balance_wallet,
                  controller: _basicSalaryController,
                ),
                SalaryInputField(
                  label: 'House Rent Allowance',
                  icon: Icons.home,
                  controller: _houseRentController,
                ),
                SalaryInputField(
                  label: 'Medical Allowance',
                  icon: Icons.medical_services,
                  controller: _medicalController,
                ),
                SalaryInputField(
                  label: 'Travel Allowance',
                  icon: Icons.directions_car,
                  controller: _travelController,
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Calculate'),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Reset'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
