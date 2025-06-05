import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapDriverRouteScreen extends StatefulWidget {
  @override
  _MapDriverRouteScreenState createState() => _MapDriverRouteScreenState();
}

class _MapDriverRouteScreenState extends State<MapDriverRouteScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? selectedDriverId;
  String? selectedRouteId;
  List<Map<String, dynamic>> drivers = [];
  List<Map<String, dynamic>> routes = [];
  Map<String, String> schoolMapping = {}; // Store the school mapping for drivers and routes

  @override
  void initState() {
    super.initState();
    fetchDrivers();
    fetchRoutes();
  }

  void fetchDrivers() async {
    var driverSnapshot = await _db.collection('drivers').get();
    setState(() {
      drivers = driverSnapshot.docs.map((doc) {
        schoolMapping[doc.id] = doc['schoolId']; // Map driver ID to school ID
        return {
          'id': doc.id,
          'name': doc['name'],
        };
      }).toList();
    });
  }

  void fetchRoutes() async {
    var routeSnapshot = await _db.collection('routes').get();
    setState(() {
      routes = routeSnapshot.docs.map((doc) {
        schoolMapping[doc.id] = doc['school_id']; // Map route ID to school ID
        return {
          'id': doc.id,
          'name': doc['route_name'],
        };
      }).toList();
    });
  }

  void mapDriverToRoute() async {
    if (selectedDriverId == null || selectedRouteId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Please select both a driver and a route.'),
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

    // Check if both belong to the same school
    if (schoolMapping[selectedDriverId] != schoolMapping[selectedRouteId]) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Please select both driver and route from the same school.'),
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

    // Add to trip collection
    await _db.collection('trips').add({
      'driverId': selectedDriverId,
      'routeId': selectedRouteId,
      'schoolId': schoolMapping[selectedDriverId],
    });

    // Show success message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text('Driver successfully mapped to route.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );

    // Clear selections
    setState(() {
      selectedDriverId = null;
      selectedRouteId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map Driver to Route'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedDriverId,
              hint: Text('Select Driver'),
              onChanged: (newValue) {
                setState(() {
                  selectedDriverId = newValue;
                });
              },
              items: drivers.map<DropdownMenuItem<String>>((driver) {
                return DropdownMenuItem<String>(
                  value: driver['id'],
                  child: Text(driver['name']),
                );
              }).toList(),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField<String>(
              value: selectedRouteId,
              hint: Text('Select Route'),
              onChanged: (newValue) {
                setState(() {
                  selectedRouteId = newValue;
                });
              },
              items: routes.map<DropdownMenuItem<String>>((route) {
                return DropdownMenuItem<String>(
                  value: route['id'],
                  child: Text(route['name']),
                );
              }).toList(),
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: mapDriverToRoute,
              child: Text('Map Driver to Route'),
            ),
          ],
        ),
      ),
    );
  }
}