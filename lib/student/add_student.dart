import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:riders_app/constants/common_functions.dart';
import 'package:riders_app/utils/colors.dart';

class AddStudentScreen extends StatefulWidget {
  final String loggedInUserId;

  const AddStudentScreen({super.key, required this.loggedInUserId});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController studentIdController = TextEditingController();
  String? selectedSchoolId;
  List<Map<String, dynamic>> schools = [];
  final DatabaseReference _db = FirebaseDatabase.instance.reference();

  @override
  void initState() {
    super.initState();
    fetchSchools();
  }

  void fetchSchools() async {
    DatabaseEvent schoolEvent = await _db.child('schools').once();
    DataSnapshot schoolSnapshot = schoolEvent.snapshot;
    Map<dynamic, dynamic> schoolData = schoolSnapshot.value as Map<dynamic, dynamic>;
    setState(() {
      schools = schoolData.entries.map((entry) {
        return {
          'id': entry.key,
          'name': entry.value['name'] as String,
        };
      }).toList();
    });
  }

  void saveStudent() async {
    if (studentIdController.text.isEmpty || selectedSchoolId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Please fill out all fields and select a school.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Check if the student ID exists in the selected school
    DatabaseEvent studentEvent = await _db
        .child('students')
        .orderByChild('studentId')
        .equalTo(studentIdController.text)
        .once();

    DataSnapshot studentSnapshot = studentEvent.snapshot;
    Map<dynamic, dynamic>? students = studentSnapshot.value as Map<dynamic, dynamic>?;
    bool studentExistsInSchool = false;
    String? uniqueStudentId;

    if (students != null) {
      students.forEach((key, value) {
        if (value['schoolId'] == selectedSchoolId) {
          studentExistsInSchool = true;
          uniqueStudentId = key;
        }
      });
    }

    if (!studentExistsInSchool) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Student ID not found in the selected school.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Save parent and student details to Realtime Database
    await _db.child('parent_students').push().set({
      'studentId': uniqueStudentId,
      'loggedInUserId': widget.loggedInUserId,
    });

    // Show success message and navigate back
    Fluttertoast.showToast(
      msg: "Student added successfully",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Image(
          image: AssetImage('assets/images/busway_logo.png'),
          height: height * 0.04,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: height,
            width: width,
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.03,
              vertical: height * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Student',
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                ),
                CommonFunctions.blankSpace(height * 0.02, 0),
                Builder(builder: (context) {
                  return CreateAccount(width, height, textTheme, context);
                }),
                CommonFunctions.blankSpace(height * 0.05, 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Container CreateAccount(double width, double height, TextTheme textTheme, BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border.all(color: greyShade3),
      ),
      child: Column(
        children: [
          Container(
            height: height * 0.06,
            width: width,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: greyShade3)),
              color: greyShade1,
            ),
            padding: EdgeInsets.symmetric(horizontal: width * 0.03),
            child: Row(
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Student - ',
                        style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: 'App Register Form',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: width,
            padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.01),
            child: Column(
              children: [
                CommonFunctions.blankSpace(height * 0.01, 0),
                buildTextField(firstNameController, 'First Name', textTheme),
                CommonFunctions.blankSpace(height * 0.01, 0),
                buildTextField(lastNameController, 'Last Name', textTheme),
                CommonFunctions.blankSpace(height * 0.01, 0),
                buildTextField(studentIdController, 'Student ID', textTheme),
                CommonFunctions.blankSpace(height * 0.01, 0),
                DropdownButtonFormField<String>(
                  value: selectedSchoolId,
                  hint: Text('Select School'),
                  onChanged: (newValue) {
                    setState(() {
                      selectedSchoolId = newValue;
                    });
                  },
                  items: schools.map<DropdownMenuItem<String>>((school) {
                    return DropdownMenuItem<String>(
                      value: school['id'],
                      child: Text(school['name']),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                CommonFunctions.blankSpace(height * 0.04, 0),
                ButtonAdd(
                  title: 'Continue',
                  btnWidth: 0.88,
                  onPressed: saveStudent,
                ),
                CommonFunctions.blankSpace(height * 0.02, 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SizedBox buildTextField(TextEditingController controller, String hintText, TextTheme textTheme) {
    return SizedBox(
      height: 60.0,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: textTheme.bodySmall,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(color: grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(color: secondaryColor),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(color: grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(color: grey),
          ),
        ),
      ),
    );
  }
}

class ButtonAdd extends StatelessWidget {
  ButtonAdd({
    Key? key,
    required this.title,
    required this.onPressed,
    required this.btnWidth,
  }) : super(key: key);

  final String title;
  final VoidCallback onPressed;
  final double btnWidth;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(width * btnWidth, height * 0.06),
        backgroundColor: amber,
      ),
      child: Text(
        title,
        style: textTheme.labelLarge?.copyWith(
          color: Colors.black,
          fontSize: 16,
        ),
      ),
    );
  }
}