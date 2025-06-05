import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageSchoolsScreen extends StatefulWidget {
  @override
  _ManageSchoolsScreenState createState() => _ManageSchoolsScreenState();
}

class _ManageSchoolsScreenState extends State<ManageSchoolsScreen> {
  final TextEditingController _schoolNameController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void addOrEditSchool([DocumentSnapshot? documentSnapshot]) async {
    if (documentSnapshot != null) {
      // Editing an existing school
      _schoolNameController.text = documentSnapshot['name'];
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(documentSnapshot == null ? 'Add School' : 'Edit School'),
          content: TextField(
            controller: _schoolNameController,
            decoration: InputDecoration(
              labelText: 'School Name',
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Cancel'),
              onPressed: () {
                _schoolNameController.clear();
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              child: Text(documentSnapshot == null ? 'Add' : 'Update'),
              onPressed: () async {
                final String name = _schoolNameController.text;
                if (name.isNotEmpty) {
                  if (documentSnapshot == null) {
                    // Add new school
                    await _db.collection('schools').add({'name': name});
                  } else {
                    // Update existing school
                    await documentSnapshot.reference.update({'name': name});
                  }
                }

                _schoolNameController.clear();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Schools'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _schoolNameController,
              decoration: InputDecoration(
                labelText: 'School Name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => addOrEditSchool(),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _db.collection('schools').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot doc = snapshot.data!.docs[index];
                    return ListTile(
                      title: Text(doc['name']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => addOrEditSchool(doc),
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
          ),
        ],
      ),
    );
  }
}