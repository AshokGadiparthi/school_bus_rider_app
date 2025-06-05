import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageBusesScreen extends StatefulWidget {
  @override
  _ManageBusesScreenState createState() => _ManageBusesScreenState();
}

class _ManageBusesScreenState extends State<ManageBusesScreen> {
  final TextEditingController _busNameController = TextEditingController();
  final TextEditingController _busNumberPlateController = TextEditingController();
  String? _selectedSchoolId;
  String? _selectedStudentId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> schools = [];
  List<Map<String, dynamic>> students = [];

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

  fetchStudents(String schoolId) async {
    var studentSnapshot = await _db.collection('students').where('schoolId', isEqualTo: schoolId).get();
    setState(() {
      students = studentSnapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['name'] as String,
      }).toList();
    });
  }

  void addOrEditBus([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _busNameController.text = documentSnapshot['bus_name'];
      _busNumberPlateController.text = documentSnapshot['bus_number_plate'];
      _selectedSchoolId = documentSnapshot['schoolId'];
      _selectedStudentId = documentSnapshot['studentId'];
      if (_selectedSchoolId != null) {
        fetchStudents(_selectedSchoolId!);
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(documentSnapshot == null ? 'Add Bus' : 'Edit Bus'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _busNameController,
                      decoration: InputDecoration(labelText: 'Bus Name'),
                    ),
                    TextField(
                      controller: _busNumberPlateController,
                      decoration: InputDecoration(labelText: 'Bus Number Plate'),
                    ),
                    DropdownButton<String>(
                      value: _selectedSchoolId,
                      hint: Text('Select School'),
                      onChanged: (newValue) async {
                        setState(() {
                          _selectedSchoolId = newValue;
                          _selectedStudentId = null;
                        });
                        if (_selectedSchoolId != null) {
                          await fetchStudents(_selectedSchoolId!);
                          setState(() {});
                        }
                      },
                      items: schools.map<DropdownMenuItem<String>>((school) {
                        return DropdownMenuItem<String>(
                          value: school['id'],
                          child: Text(school['name']),
                        );
                      }).toList(),
                    ),
                    DropdownButton<String>(
                      value: _selectedStudentId,
                      hint: Text('Select Student'),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedStudentId = newValue;
                        });
                      },
                      items: students.map<DropdownMenuItem<String>>((student) {
                        return DropdownMenuItem<String>(
                          value: student['id'],
                          child: Text(student['name']),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    _busNameController.clear();
                    _busNumberPlateController.clear();
                    _selectedSchoolId = null;
                    _selectedStudentId = null;
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text(documentSnapshot == null ? 'Add' : 'Update'),
                  onPressed: () async {
                    if (_busNameController.text.isNotEmpty && _busNumberPlateController.text.isNotEmpty) {
                      if (documentSnapshot == null) {
                        await _db.collection('buses').add({
                          'bus_name': _busNameController.text,
                          'bus_number_plate': _busNumberPlateController.text,
                          'schoolId': _selectedSchoolId,
                          'studentId': _selectedStudentId,
                        });
                      } else {
                        await documentSnapshot.reference.update({
                          'bus_name': _busNameController.text,
                          'bus_number_plate': _busNumberPlateController.text,
                          'schoolId': _selectedSchoolId,
                          'studentId': _selectedStudentId,
                        });
                      }
                      _busNameController.clear();
                      _busNumberPlateController.clear();
                      _selectedSchoolId = null;
                      _selectedStudentId = null;
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

  Future<String> getSchoolName(String? schoolId) async {
    if (schoolId == null) return 'Unknown';
    var doc = await _db.collection('schools').doc(schoolId).get();
    return doc.exists ? doc['name'] : 'Unknown';
  }

  Future<String> getStudentName(String? studentId) async {
    if (studentId == null) return 'Unknown';
    var doc = await _db.collection('students').doc(studentId).get();
    return doc.exists ? doc['name'] : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Buses'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _busNameController,
              decoration: InputDecoration(
                labelText: 'Bus Name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => addOrEditBus(),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _db.collection('buses').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    return FutureBuilder(
                      future: Future.wait([
                        getSchoolName(doc['schoolId']),
                        getStudentName(doc['studentId'])
                      ]),
                      builder: (context, AsyncSnapshot<List<String>> nameSnapshot) {
                        if (!nameSnapshot.hasData) return CircularProgressIndicator();
                        return ListTile(
                          title: Text(doc['bus_name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Number Plate: ${doc['bus_number_plate']}'),
                              Text('School: ${nameSnapshot.data![0]}'),
                              Text('Student: ${nameSnapshot.data![1]}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => addOrEditBus(doc),
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
                );
              },
            ),
          )
        ],
      ),
    );
  }
}