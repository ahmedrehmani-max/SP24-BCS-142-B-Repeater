import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable numeric text field used for every salary/allowance input.
///
/// It keeps the validation rules in one place: the value is required and must
/// be a non-negative number.
class SalaryInputField extends StatelessWidget {
  const SalaryInputField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          hintText: '0',
        ),
        validator: (String? value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          final double? amount = double.tryParse(value.trim());
          if (amount == null) {
            return 'Enter a valid number';
          }
          if (amount < 0) {
            return 'Amount cannot be negative';
          }
          return null;
        },
      ),
    );
  }
}
