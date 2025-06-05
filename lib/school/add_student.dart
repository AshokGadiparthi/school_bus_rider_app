import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riders_app/constants/common_functions.dart';
import 'package:riders_app/utils/colors.dart';

class ManageStudentsScreen extends StatefulWidget {
  @override
  _ManageStudentsScreenState createState() => _ManageStudentsScreenState();
}

class _ManageStudentsScreenState extends State<ManageStudentsScreen> {
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _parentFirstNameController = TextEditingController();
  final TextEditingController _parentLastNameController = TextEditingController();
  final TextEditingController _parentContactController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  String? _selectedSchoolId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> schools = [];

  @override
  void initState() {
    super.initState();
    fetchSchools();
  }

  fetchSchools() async {
    var schoolSnapshot = await _db.collection('schools').get();
    setState(() {
      schools = schoolSnapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['name'] as String,
      }).toList();
    });
  }

  void addOrEditStudent([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _studentNameController.text = documentSnapshot['name'] ?? '';
      _studentIdController.text = documentSnapshot['studentId'] ?? '';
      _parentFirstNameController.text = documentSnapshot['parentFirstName'] ?? '';
      _parentLastNameController.text = documentSnapshot['parentLastName'] ?? '';
      _parentContactController.text = documentSnapshot['contactNo'] ?? '';
      _addressController.text = documentSnapshot['address'] ?? '';
      _selectedSchoolId = documentSnapshot['schoolId'] ?? '';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(documentSnapshot == null ? 'Add Student' : 'Edit Student'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _studentNameController,
                    decoration: InputDecoration(labelText: 'Student Name'),
                  ),
                  TextField(
                    controller: _studentIdController,
                    decoration: InputDecoration(labelText: 'Student ID'),
                  ),
                  TextField(
                    controller: _parentFirstNameController,
                    decoration: InputDecoration(labelText: 'Parent First Name'),
                  ),
                  TextField(
                    controller: _parentLastNameController,
                    decoration: InputDecoration(labelText: 'Parent Last Name'),
                  ),
                  TextField(
                    controller: _parentContactController,
                    decoration: InputDecoration(labelText: 'Contact Number'),
                  ),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(labelText: 'Student Address'),
                  ),
                  DropdownButton<String>(
                    value: _selectedSchoolId,
                    hint: Text('Select School'),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedSchoolId = newValue;
                      });
                    },
                    items: schools.map<DropdownMenuItem<String>>((school) {
                      return DropdownMenuItem<String>(
                        value: school['id'],
                        child: Text(school['name']),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    _studentNameController.clear();
                    _studentIdController.clear();
                    _parentFirstNameController.clear();
                    _parentLastNameController.clear();
                    _parentContactController.clear();
                    _addressController.clear();
                    _selectedSchoolId = null;
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text(documentSnapshot == null ? 'Add' : 'Update'),
                  onPressed: () async {
                    if (_studentNameController.text.isNotEmpty && _studentIdController.text.isNotEmpty && _selectedSchoolId != null) {
                      // Check if the student ID already exists in the selected school
                      var studentSnapshot = await _db.collection('students')
                          .where('studentId', isEqualTo: _studentIdController.text)
                          .where('schoolId', isEqualTo: _selectedSchoolId)
                          .get();

                      if (studentSnapshot.docs.isNotEmpty && documentSnapshot == null) {
                        // Show error message
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Error'),
                            content: Text('Student ID already exists in the selected school.'),
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

                      if (documentSnapshot == null) {
                        await _db.collection('students').add({
                          'name': _studentNameController.text,
                          'studentId': _studentIdController.text,
                          'parentFirstName': _parentFirstNameController.text,
                          'parentLastName': _parentLastNameController.text,
                          'contactNo': _parentContactController.text,
                          'address': _addressController.text,
                          'schoolId': _selectedSchoolId
                        });
                      } else {
                        await documentSnapshot.reference.update({
                          'name': _studentNameController.text,
                          'studentId': _studentIdController.text,
                          'parentFirstName': _parentFirstNameController.text,
                          'parentLastName': _parentLastNameController.text,
                          'contactNo': _parentContactController.text,
                          'address': _addressController.text,
                          'schoolId': _selectedSchoolId
                        });
                      }
                      _studentNameController.clear();
                      _studentIdController.clear();
                      _parentFirstNameController.clear();
                      _parentLastNameController.clear();
                      _parentContactController.clear();
                      _addressController.clear();
                      _selectedSchoolId = null;
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
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
            padding: EdgeInsets.symmetric(horizontal: width * 0.03, vertical: height * 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Students',
                  style: textTheme.labelLarge?.copyWith(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                ),
                CommonFunctions.blankSpace(height * 0.02, 0),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _studentNameController,
                    decoration: InputDecoration(
                      labelText: 'Student Name',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () => addOrEditStudent(),
                      ),
                    ),
                  ),
                ),
                CommonFunctions.blankSpace(height * 0.02, 0),
                Expanded(
                  child: StreamBuilder(
                    stream: _db.collection('students').snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator();
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot doc = snapshot.data!.docs[index];
                          return ListTile(
                            title: Text(doc['name'] ?? 'Unnamed'),
                            subtitle: Text(schools.firstWhere(
                                    (school) => school['id'].toString() == doc['schoolId'].toString(),
                                orElse: () => {'id': '', 'name': 'Unknown'} as Map<String, String>
                            )['name']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => addOrEditStudent(doc),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => doc.reference.delete(),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                )
              ],
            ),
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