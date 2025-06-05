import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageDriversScreen extends StatefulWidget {
  @override
  _ManageDriversScreenState createState() => _ManageDriversScreenState();
}

class _ManageDriversScreenState extends State<ManageDriversScreen> {
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _drivingLicenseController = TextEditingController();
  String? _selectedSchoolId;
  String? _selectedBusId;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> schools = [];
  List<Map<String, dynamic>> buses = [];

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

  fetchBuses(String schoolId) async {
    var busSnapshot = await _db.collection('buses').where('schoolId', isEqualTo: schoolId).get();
    setState(() {
      buses = busSnapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['bus_name'] as String,
      }).toList();
    });
  }

  void addOrEditDriver([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      _driverNameController.text = documentSnapshot['name'];
      _phoneNumberController.text = documentSnapshot['phone_number'];
      _drivingLicenseController.text = documentSnapshot['driving_license'];
      _selectedSchoolId = documentSnapshot['schoolId'];
      _selectedBusId = documentSnapshot['busId'];
      if (_selectedSchoolId != null) {
        fetchBuses(_selectedSchoolId!);
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(documentSnapshot == null ? 'Add Driver' : 'Edit Driver'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _driverNameController,
                      decoration: InputDecoration(labelText: 'Driver Name'),
                    ),
                    TextField(
                      controller: _phoneNumberController,
                      decoration: InputDecoration(labelText: 'Phone Number'),
                    ),
                    TextField(
                      controller: _drivingLicenseController,
                      decoration: InputDecoration(labelText: 'Driving License ID'),
                    ),
                    DropdownButton<String>(
                      value: _selectedSchoolId,
                      hint: Text('Select School'),
                      onChanged: (newValue) async {
                        setState(() {
                          _selectedSchoolId = newValue;
                          _selectedBusId = null;
                        });
                        if (_selectedSchoolId != null) {
                          await fetchBuses(_selectedSchoolId!);
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
                      value: _selectedBusId,
                      hint: Text('Select Bus'),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedBusId = newValue;
                        });
                      },
                      items: buses.map<DropdownMenuItem<String>>((bus) {
                        return DropdownMenuItem<String>(
                          value: bus['id'],
                          child: Text(bus['name']),
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
                    _driverNameController.clear();
                    _phoneNumberController.clear();
                    _drivingLicenseController.clear();
                    _selectedSchoolId = null;
                    _selectedBusId = null;
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text(documentSnapshot == null ? 'Add' : 'Update'),
                  onPressed: () async {
                    if (_driverNameController.text.isNotEmpty && _phoneNumberController.text.isNotEmpty && _drivingLicenseController.text.isNotEmpty) {
                      if (documentSnapshot == null) {
                        await _db.collection('drivers').add({
                          'name': _driverNameController.text,
                          'phone_number': _phoneNumberController.text,
                          'driving_license': _drivingLicenseController.text,
                          'schoolId': _selectedSchoolId,
                          'busId': _selectedBusId,
                        });
                      } else {
                        await documentSnapshot.reference.update({
                          'name': _driverNameController.text,
                          'phone_number': _phoneNumberController.text,
                          'driving_license': _drivingLicenseController.text,
                          'schoolId': _selectedSchoolId,
                          'busId': _selectedBusId,
                        });
                      }
                      _driverNameController.clear();
                      _phoneNumberController.clear();
                      _drivingLicenseController.clear();
                      _selectedSchoolId = null;
                      _selectedBusId = null;
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

  Future<String> getBusName(String? busId) async {
    if (busId == null) return 'No Bus Assigned';
    var doc = await _db.collection('buses').doc(busId).get();
    return doc.exists ? doc['bus_name'] : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Drivers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _driverNameController,
              decoration: InputDecoration(
                labelText: 'Driver Name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => addOrEditDriver(),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _db.collection('drivers').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    return FutureBuilder(
                      future: getBusName(doc['busId']),
                      builder: (context, AsyncSnapshot<String> nameSnapshot) {
                        if (!nameSnapshot.hasData) return CircularProgressIndicator();
                        return ListTile(
                          title: Text(doc['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Phone Number: ${doc['phone_number']}'),
                              Text('Driving License: ${doc['driving_license']}'),
                              Text('Bus: ${nameSnapshot.data}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => addOrEditDriver(doc),
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