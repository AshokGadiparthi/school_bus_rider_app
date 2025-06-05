import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riders_app/AllWidgets/Divider.dart';
import 'package:riders_app/Assistants/requestAssistant.dart';
import 'package:riders_app/DataHandler/appData.dart';
import 'package:riders_app/Models/address.dart';
import 'package:riders_app/Models/placePredictions.dart';
import 'package:riders_app/configMaps.dart';
import 'package:riders_app/AllWidgets/progressDialog.dart';
import 'package:riders_app/utils/colors.dart';

class AddRoute extends StatefulWidget {
  @override
  _AddRouteState createState() => _AddRouteState();
}

class _AddRouteState extends State<AddRoute> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController dropOffTextEditingController = TextEditingController();
  TextEditingController routeNameController = TextEditingController();
  String? selectedSchoolId;
  List<PlacePredictions> placePredictionList = [];
  FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Map<String, dynamic>> schools = [];

  Address? startAddress;
  List<Address> endAddresses = [];

  @override
  void initState() {
    super.initState();
    fetchSchools();
  }

  void fetchSchools() async {
    var schoolSnapshot = await _db.collection('schools').get();
    setState(() {
      schools = schoolSnapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['name'] as String,
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        title: Text('Manage Routes'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: routeNameController,
                        decoration: InputDecoration(
                          labelText: 'Route Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(width: 10.0),
                    ElevatedButton(
                      onPressed: saveRoute,
                      child: Text('Save Route'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonFormField<String>(
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
              ),
              buildTextField(
                controller: pickUpTextEditingController,
                label: "Where to Start?",
                icon: Icons.location_on,
                onChanged: (val) {
                  if (startAddress == null) findPlace(val);
                },
                enabled: startAddress == null,
              ),
              buildTextField(
                controller: dropOffTextEditingController,
                label: "Where to?",
                icon: Icons.flag,
                onChanged: findPlace,
              ),
              if (placePredictionList.isNotEmpty)
                Expanded(
                  child: Container(),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: endAddresses.length + (startAddress != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0 && startAddress != null) {
                      return ListTile(
                        title: Text(startAddress!.placeName ?? ''),
                        subtitle: Text('Start Address'),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              startAddress = null;
                              pickUpTextEditingController.clear();
                            });
                          },
                        ),
                      );
                    }
                    final endAddress = endAddresses[index - (startAddress != null ? 1 : 0)];
                    return ListTile(
                      title: Text(endAddress.placeName ?? ''),
                      subtitle: Text('End Address ${index - (startAddress != null ? 1 : 0) + 1}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => setState(() => endAddresses.removeAt(index - (startAddress != null ? 1 : 0))),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (placePredictionList.isNotEmpty)
            Positioned(
              top: 200.0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 5,
                child: Container(
                  height: 300.0,
                  child: ListView.separated(
                    padding: EdgeInsets.all(0.0),
                    itemBuilder: (context, index) {
                      return PredictionTile(
                        placePredictions: placePredictionList[index],
                        saveAddressCallback: saveAddress,
                        onPredictionTap: () => setState(() => placePredictionList.clear()),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) => DividerWidget(),
                    itemCount: placePredictionList.length,
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void findPlace(String placeName) async {
    if (placeName.length > 1) {
      Uri autoCompleteUrl = Uri.parse(
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=1234567890&components=country:us");

      var res = await RequestAssistant.getRequest(autoCompleteUrl);

      if (res == "failed") {
        return;
      }

      if (res["status"] == "OK") {
        var predictions = res["predictions"];
        var placesList = (predictions as List).map((e) => PlacePredictions.fromJson(e)).toList();

        setState(() {
          placePredictionList = placesList;
        });
      }
    }
  }

  void saveAddress(Address address) {
    setState(() {
      if (startAddress == null) {
        startAddress = address;
        pickUpTextEditingController.clear(); // Clear the input box
      } else {
        endAddresses.add(address);
        dropOffTextEditingController.clear(); // Clear the input box
      }
    });
  }

  void saveRoute() async {
    if (routeNameController.text.isEmpty || startAddress == null || endAddresses.isEmpty || selectedSchoolId == null) {
      // Show error message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Please enter a route name, select a school, a start address, and at least one end address.'),
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

    // Check if the route name already exists (case-insensitive)
    var normalizedRouteName = routeNameController.text.toLowerCase();
    var existingRoute = await _db
        .collection('routes')
        .where('school_id', isEqualTo: selectedSchoolId)
        .get();

    bool routeExists = existingRoute.docs.any((doc) {
      var routeName = doc['route_name'] as String;
      return routeName.toLowerCase() == normalizedRouteName;
    });

    if (routeExists) {
      // Show error message
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('A route with this name already exists for the selected school.'),
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

    List<Map<String, dynamic>> endAddressesData = endAddresses.map((address) {
      return {
        'address': address.placeName,
        'latitude': address.latitude,
        'longitude': address.longitude,
      };
    }).toList();

    await _db.collection('routes').add({
      'route_name': routeNameController.text,
      'school_id': selectedSchoolId,
      'start_address': {
        'address': startAddress!.placeName,
        'latitude': startAddress!.latitude,
        'longitude': startAddress!.longitude,
      },
      'end_addresses': endAddressesData,
    });

    // Clear the form
    setState(() {
      routeNameController.clear();
      pickUpTextEditingController.clear();
      dropOffTextEditingController.clear();
      startAddress = null;
      endAddresses.clear();
      selectedSchoolId = null;
    });
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16.0),
          SizedBox(width: 18.0),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(5.0),
              ),
              child: Padding(
                padding: EdgeInsets.all(3.0),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: label,
                    fillColor: Colors.grey[400],
                    filled: true,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.only(left: 11.0, top: 8.0, bottom: 8.0),
                  ),
                  onChanged: (val) => onChanged(val),
                  enabled: enabled,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PredictionTile extends StatelessWidget {
  final PlacePredictions? placePredictions;
  final Function(Address) saveAddressCallback;
  final VoidCallback onPredictionTap;

  PredictionTile({Key? key, this.placePredictions, required this.saveAddressCallback, required this.onPredictionTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.all(0.0),
      ),
      onPressed: () {
        getPlaceAddressDetails(placePredictions?.place_id, context);
      },
      child: Container(
        child: Column(
          children: [
            SizedBox(width: 10.0),
            Row(
              children: [
                Icon(Icons.add_location),
                SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8.0),
                      Text(
                        placePredictions?.main_text ?? 'Default Text',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16.0),
                      ),
                      SizedBox(height: 2.0),
                      Text(
                        placePredictions?.secondary_text ?? 'Default Text',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.0, color: Colors.grey),
                      ),
                      SizedBox(height: 8.0),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(width: 10.0),
          ],
        ),
      ),
    );
  }

  void getPlaceAddressDetails(String? placeId, context) async {
    // Store the dialog context
    BuildContext? dialogContext;

    // Show the progress dialog and store the context
    showDialog(
      context: context,
      barrierDismissible: false,  // Prevent dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        dialogContext = context;  // Assign the dialog context here
        return ProgressDialog(message: "Setting Dropoff, please wait...");
      },
    );

    // Fetch place details
    Uri placeDetailsUrl = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$mapKey");
    var res = await RequestAssistant.getRequest(placeDetailsUrl);

    // Close the progress dialog
    if (dialogContext != null) {
      Navigator.pop(dialogContext!);  // Close the progress dialog
    }

    // Handle the response
    if (res == "failed") {
      return;
    }

    if (res["status"] == "OK") {
      Address address = Address();
      address.placeName = res["result"]["name"];
      address.placeId = placeId;
      address.latitude = res["result"]["geometry"]["location"]["lat"];
      address.longitude = res["result"]["geometry"]["location"]["lng"];

      // Update the address in AppData and save it to Firestore
      Provider.of<AppData>(context, listen: false).updateDropOffLocationAddress(address);
      saveAddressCallback(address);
      onPredictionTap();  // Clear predictions after selection
    }
  }
}