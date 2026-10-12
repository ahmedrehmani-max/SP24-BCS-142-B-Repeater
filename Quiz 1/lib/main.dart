// CSC303 - Mobile Application Development
// Quiz No. 1 (CLO-1): Basic Flutter UI Widgets

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Registration Form',
      home: const RegistrationScreen(),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  // 2. TextField - Student Name
  final TextEditingController nameController = TextEditingController();

  // 3. TextField - Registration Number
  final TextEditingController regNoController = TextEditingController();

  // 4. Radio Button - Gender
  String gender = 'Male';

  // 5. Checkbox - Hobbies
  bool reading = false;
  bool sports = false;

  // 6. Option List - single choice out of 3 options
  String shift = 'Morning';

  // 7. Selection List - 3 selectable items
  final List<String> courses = ['Mobile App Dev', 'Data Structures', 'Databases'];
  final List<String> selectedCourses = [];

  // 8. Dropdown List - Department
  String department = 'CS';

  // Output shown after pressing the buttons
  String result = '';

  @override
  void dispose() {
    nameController.dispose();
    regNoController.dispose();
    super.dispose();
  }

  void showButtonMessage() {
    setState(() {
      result = 'Simple Button Pressed';
    });
  }

  void submitForm() {
    final List<String> hobbies = [];
    if (reading) hobbies.add('Reading');
    if (sports) hobbies.add('Sports');

    setState(() {
      result =
          'Name: ${nameController.text}\n'
          'Registration No: ${regNoController.text}\n'
          'Gender: $gender\n'
          'Hobbies: ${hobbies.isEmpty ? 'None' : hobbies.join(', ')}\n'
          'Shift: $shift\n'
          'Courses: ${selectedCourses.isEmpty ? 'None' : selectedCourses.join(', ')}\n'
          'Department: $department';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Text
              const Text(
                'Student Registration Form',
                style: TextStyle(fontSize: 22),
              ),

              // 2. TextField - Student Name
              SizedBox(
                width: 300,
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Student Name'),
                ),
              ),

              // 3. TextField - Registration Number
              SizedBox(
                width: 300,
                child: TextField(
                  controller: regNoController,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number',
                  ),
                ),
              ),

              // 4. Radio Button - Gender
              const Text('Gender'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio<String>(
                    value: 'Male',
                    groupValue: gender,
                    onChanged: (value) => setState(() => gender = value!),
                  ),
                  const Text('Male'),
                  Radio<String>(
                    value: 'Female',
                    groupValue: gender,
                    onChanged: (value) => setState(() => gender = value!),
                  ),
                  const Text('Female'),
                ],
              ),

              // 5. Checkbox - Hobbies
              const Text('Hobbies'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: reading,
                    onChanged: (value) => setState(() => reading = value!),
                  ),
                  const Text('Reading'),
                  Checkbox(
                    value: sports,
                    onChanged: (value) => setState(() => sports = value!),
                  ),
                  const Text('Sports'),
                ],
              ),

              // 6. Option List - 3 options, only one can be selected
              const Text('Option List (Shift)'),
              SizedBox(
                width: 300,
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Morning'),
                      value: 'Morning',
                      groupValue: shift,
                      onChanged: (value) => setState(() => shift = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Afternoon'),
                      value: 'Afternoon',
                      groupValue: shift,
                      onChanged: (value) => setState(() => shift = value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Evening'),
                      value: 'Evening',
                      groupValue: shift,
                      onChanged: (value) => setState(() => shift = value!),
                    ),
                  ],
                ),
              ),

              // 7. Selection List - 3 selectable items
              const Text('Selection List (Courses)'),
              SizedBox(
                width: 300,
                child: Column(
                  children: courses.map((course) {
                    return ListTile(
                      title: Text(course),
                      selected: selectedCourses.contains(course),
                      onTap: () {
                        setState(() {
                          if (selectedCourses.contains(course)) {
                            selectedCourses.remove(course);
                          } else {
                            selectedCourses.add(course);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),

              // 8. Dropdown List - Department
              const Text('Department'),
              DropdownButton<String>(
                value: department,
                items: const [
                  DropdownMenuItem(value: 'CS', child: Text('CS')),
                  DropdownMenuItem(value: 'IT', child: Text('IT')),
                  DropdownMenuItem(value: 'SE', child: Text('SE')),
                  DropdownMenuItem(value: 'AI', child: Text('AI')),
                ],
                onChanged: (value) => setState(() => department = value!),
              ),

              // 9. Button - a simple button
              ElevatedButton(
                onPressed: showButtonMessage,
                child: const Text('Simple Button'),
              ),

              // 10. Submit Button
              ElevatedButton(
                onPressed: submitForm,
                child: const Text('Submit'),
              ),

              // Display of the selected values
              Text(result, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
