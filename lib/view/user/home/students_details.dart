import 'package:flutter/material.dart';

class StudentDetailScreen extends StatelessWidget {
  final String studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    // Fetch detailed student information from Firestore using the studentId
    // Display the detailed information here

    return Scaffold(
      appBar: AppBar(
        title: Text('Student Details'),
      ),
      body: Center(
        child: Text('Detailed information for student ID: $studentId'),
      ),
    );
  }
}