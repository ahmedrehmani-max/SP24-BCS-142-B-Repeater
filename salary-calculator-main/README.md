# Salary Calculator — Assignment 1

CSC303 Mobile Application Development (CLO-2)

A Flutter application that collects monthly salary details, calculates the
income tax deduction and shows the net monthly income.

## Features

- Form with four inputs: Basic Salary, House Rent Allowance, Medical Allowance,
  Travel Allowance.
- Input validation (required, numeric, non-negative) with error messages.
- **Calculate** button — opens the result screen showing the **Tax Deduction**
  first, then the **Net Monthly Income** (`Gross Salary − Tax Deduction`).
- **Reset** button — clears all fields and validation messages.
- Material 3 UI.

## Project structure

```
lib/
├── main.dart                        # App entry point and theme
├── models/
│   ├── salary.dart                  # Salary data model (gross salary)
│   └── tax_calculator.dart          # Tax slabs and the calculation logic
├── screens/
│   ├── salary_form_screen.dart      # Input screen (Form + validation)
│   └── result_screen.dart           # Result screen
├── widgets/
│   ├── salary_input_field.dart      # Reusable validated number field
│   └── result_row.dart              # "label — amount" row
└── utils/
    └── currency.dart                # PKR amount formatting
test/
└── tax_calculator_test.dart         # Unit tests for the tax logic
```

## Tax calculation

Tax is computed with the progressive slabs for salaried individuals
(tax year 2025-26). The monthly gross salary is annualised, the annual tax is
taken from the slab table, and the result is divided by 12:

| Annual income (PKR)     | Tax                                  |
| ----------------------- | ------------------------------------ |
| up to 600,000           | 0%                                   |
| 600,001 – 1,200,000     | 1% of the amount over 600,000        |
| 1,200,001 – 2,200,000   | 6,000 + 11% of the amount over 1.2M  |
| 2,200,001 – 3,200,000   | 116,000 + 23% of the amount over 2.2M |
| 3,200,001 – 4,100,000   | 346,000 + 30% of the amount over 3.2M |
| above 4,100,000         | 616,000 + 35% of the amount over 4.1M |

## Running the app

```bash
flutter pub get
flutter run          # device or emulator
flutter run -d chrome  # browser
flutter test         # unit tests
```

## Screenshots

| Input Screen | Result Screen |
| ------------ | ------------- |
| ![Input Screen](Screenshots/input_screen.png) | ![Result Screen](Screenshots/result_screen.png) |
