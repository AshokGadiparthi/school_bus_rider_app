import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:riders_app/Models/active_route.dart';
import 'package:riders_app/configMaps.dart';
import 'package:riders_app/constants/common_functions.dart';
import 'package:riders_app/student/add_student.dart';
import 'package:riders_app/student/student_details.dart';
import 'package:riders_app/utils/colors.dart';
import 'package:riders_app/DataHandler/appData.dart';
import 'package:riders_app/Models/address.dart';
import 'package:riders_app/map/map.dart';
import 'package:riders_app/view/user/home/students_details.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

class ParentStudentsScreenWidget extends StatelessWidget {
  final CarouselController todaysDealsCarouselController;

  final List<Color> avatarColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.cyan,
    Colors.indigo,
    Colors.amber,
  ];

  ParentStudentsScreenWidget({
    super.key,
    required this.todaysDealsCarouselController,
  });

  Color getAvatarColor(String name) {
    final int index = name.hashCode % avatarColors.length;
    return avatarColors[index];
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;
    String? loggedInUserId = FirebaseAuth.instance.currentUser?.uid;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Container(
            height: height * 0.06,
            width: width,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: greyShade3),
              ),
              color: greyShade1,
            ),
            padding: EdgeInsets.symmetric(horizontal: width * 0.03),
            child: Row(
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Students List ',
                        style: textTheme.bodyMedium!
                            .copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    elevation: 4.0,
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    textStyle: TextStyle(
                      fontSize: 12,
                    ),
                    minimumSize: Size(80, 30),
                  ),
                  child: Text(
                    'Add Student',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        child: AddStudentScreen(loggedInUserId: loggedInUserId!),
                        type: PageTransitionType.rightToLeft,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          CommonFunctions.blankSpace(height * 0.01, 0),
          StreamBuilder(
            stream: FirebaseDatabase.instance.reference().child('parent_students').onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return Container(
                  height: height * 0.2,
                  width: width,
                  alignment: Alignment.center,
                  child: Text(
                    'Loading Students',
                    style: textTheme.bodyMedium,
                  ),
                );
              } else {
                Map<dynamic, dynamic>? parentStudentsData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>?;
                if (parentStudentsData == null) {
                  return Container(
                    height: height * 0.2,
                    width: width,
                    alignment: Alignment.center,
                    child: Text(
                      'No students available',
                      style: textTheme.bodyMedium,
                    ),
                  );
                }
                List<Map<String, dynamic>> parentStudents = parentStudentsData.entries.map((entry) {

                  String studentId = entry.value['studentId'];
                  return {
                    'id': entry.key,
                    'studentId': studentId,
                  };
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: parentStudents.length,
                  itemBuilder: (context, index) {
                    var parent = parentStudents[index];
                    print("parent: $parent");
                    String studentId = parent['studentId'];
                    print("studentId: $studentId");

                    return FutureBuilder(
                      future: FirebaseDatabase.instance.reference().child('students').child(studentId).once(),
                      builder: (context, AsyncSnapshot<DatabaseEvent> studentSnapshot) {
                        if (!studentSnapshot.hasData || studentSnapshot.data!.snapshot.value == null) {
                          print("studentSnapshot: $studentSnapshot");
                          return Container(
                            height: height * 0.2,
                            width: width,
                            alignment: Alignment.center,
                            child: Text(
                              'Loading Student Details',
                              style: textTheme.bodyMedium,
                            ),
                          );
                        } else {

                          Map<dynamic, dynamic> studentData = studentSnapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                          print("studentData: $studentData");
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudentDetailScreen(studentId: studentData['studentId']),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                height: height * 0.20,
                                width: width,
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SingleChildScrollView(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 30,
                                                  backgroundColor: getAvatarColor(studentData['name'] + studentData['parentLastName']),
                                                  child: Text(
                                                    '${studentData['name'][0]}${studentData['parentLastName'][0]}',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      '${studentData['name']} ${studentData['parentLastName']}',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    Text(
                                                      'Student ID: ${studentData['studentId']}',
                                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            CommonFunctions.blankSpace(height * 0.01, 0),
                                            CommonFunctions.divider(),
                                            CommonFunctions.blankSpace(height * 0.01, 0),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: teal,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                                    elevation: 3.0,
                                                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                                                    textStyle: TextStyle(fontSize: 16),
                                                    minimumSize: Size(120, 30),
                                                  ),
                                                  icon: Icon(Icons.map_outlined, color: Colors.white, size: 24),
                                                  label: Text('Map'),
                                                  onPressed: () {
                                                    print('Map button pressed');

                                                    var activeRouteRef = FirebaseDatabase.instance.ref().child('Active Routes');
                                                    activeRouteRef.once().then((DatabaseEvent event) async {
                                                      var activeRouteData = event.snapshot.value as Map<dynamic, dynamic>;
                                                      var firstRoute = activeRouteData.entries.first.value;

                                                      var startAddress = Address(
                                                        placeName: firstRoute['start_address']['address'],
                                                        latitude: double.parse(firstRoute['start_address']['latitude']),
                                                        longitude: double.parse(firstRoute['start_address']['longitude']),
                                                      );

                                                      var endAddresses = (firstRoute['end_addresses'] as List<dynamic>).map((endAddr) {
                                                        return Address(
                                                          placeName: endAddr['address'],
                                                          latitude: double.parse(endAddr['latitude']),
                                                          longitude: double.parse(endAddr['longitude']),
                                                          studentId: endAddr['studentId'],
                                                        );
                                                      }).toList();

                                                      // Fetch the parent_students data
                                                      var parentStudentsRef = FirebaseDatabase.instance.ref().child('parent_students');
                                                      var parentStudentsSnapshot = await parentStudentsRef.once();
                                                      var parentStudentsData = parentStudentsSnapshot.snapshot.value as Map<dynamic, dynamic>;

                                                      // Find the matching studentId for the loggedInUserId
                                                      String? matchingStudentId;
                                                      parentStudentsData.forEach((key, value) {
                                                        if (value['loggedInUserId'] == loggedInUserId) {
                                                          matchingStudentId = value['studentId'];
                                                        }
                                                      });

                                                      if (matchingStudentId != null) {
                                                        // Find the matching end address for the studentId
                                                        print("endAddresses: $endAddresses");
                                                        print("matchingStudentId: $matchingStudentId");
                                                        var matchingEndAddress = endAddresses.firstWhere(
                                                                (address) => address.studentId == matchingStudentId,
                                                            orElse: () => Address.empty()
                                                        );
                                                        print("matchingEndAddress: $matchingEndAddress");
                                                        print("matchingEndAddress.placeName: $matchingEndAddress.placeName");
                                                        if (matchingEndAddress != null ) {
                                                          Provider.of<AppData>(context, listen: false).updateDropOffLocationAddress(matchingEndAddress);
                                                        } else {
                                                          // Handle the case where no matching address is found
                                                          print('No matching end address found for studentId: $matchingStudentId');
                                                        }
                                                      } else {
                                                        // Handle the case where no matching studentId is found
                                                        print('No matching studentId found for loggedInUserId: $loggedInUserId');
                                                      }

                                                      Provider.of<AppData>(context, listen: false).updatePickUpLocationAddress(startAddress);

                                                      Provider.of<AppData>(context, listen: false).updateDropOffLocationAddresses(endAddresses);


                                                      var routeDetailsMap = await getRouteDetailsForLoggedInUser(FirebaseAuth.instance.currentUser!.uid);

                                                      if (routeDetailsMap != null) {
                                                        ActiveRoute activeRoute = ActiveRoute.fromJson(Map<String, dynamic>.from(routeDetailsMap));
                                                        Navigator.push(
                                                          context,
                                                          PageTransition(
                                                            child: MapDetailsScreen(activeRoutes: activeRoute),
                                                            type: PageTransitionType.rightToLeft,
                                                          ),
                                                        );
                                                      } else {
                                                        // Handle the case where route details are not found
                                                        print('No route details found for the logged-in user.');
                                                      }

                                                    });
                                                  },
                                                ),
                                                SizedBox(width: 10),
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: teal,
                                                    foregroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                                    elevation: 3.0,
                                                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                                                    textStyle: TextStyle(fontSize: 16),
                                                    minimumSize: Size(120, 30),
                                                  ),
                                                  icon: Icon(Icons.remove_circle_outline, color: Colors.white, size: 24),
                                                  label: Text('Delete'),
                                                  onPressed: () => _showDeleteConfirmationDialog(context, parent['id']),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: IconButton(
                                        icon: Icon(Icons.share_outlined, color: Colors.teal, size: 22),
                                        onPressed: () => showShareDialog(context),
                                        tooltip: 'Share',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String parentId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this student?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                await FirebaseDatabase.instance.reference().child('parent_students').child(parentId).remove();
                Navigator.of(dialogContext).pop();

                Fluttertoast.showToast(
                  msg: "Student deleted successfully",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Share Student Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.phone_android, color: Colors.teal),
                  title: Text('Share via Phone'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareViaPhone(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.chat, color: Colors.teal),
                  title: Text('Share via WhatsApp'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareViaWhatsApp(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.email, color: Colors.teal),
                  title: Text('Share via Email'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareViaEmail();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.share, color: Colors.teal),
                  title: Text('More options'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _shareMoreOptions();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _shareViaWhatsApp(BuildContext context) async {
    final Uri uri = Uri.parse("https://api.whatsapp.com/send?phone=&text=YourMessageHere");

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch $uri';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open WhatsApp.'))
      );
    }
  }

  void _shareViaEmail() async {
    final Uri uri = Uri.parse("mailto:?subject=Student Details&body=Here are the student details you requested...");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Handle the error
    }
  }

  void _shareViaPhone(BuildContext context) async {
    final String message = "Here are the student details you requested...";
    final Uri uri = Uri.parse("https://api.whatsapp.com/send?phone=&text=$message");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('WhatsApp is not installed')));
    }
  }

  void _shareMoreOptions() {
    Share.share('Here are the student details you requested...');
  }

  Future<Map<String, dynamic>?> getRouteDetailsForLoggedInUser(String loggedInUserId) async {
    // Reference to the parent_students collection in Realtime Database
    DatabaseReference parentStudentsRef = FirebaseDatabase.instance.ref().child('parent_students');

    // Query to get the route for the specified logged-in user ID
    DatabaseEvent parentStudentEvent = await parentStudentsRef.orderByChild('loggedInUserId').equalTo(loggedInUserId).once();
    print("parentStudentEvent: $parentStudentEvent");
    DataSnapshot parentStudentSnapshot = parentStudentEvent.snapshot;

    if (parentStudentSnapshot.value != null) {
      Map<dynamic, dynamic> parentStudents = parentStudentSnapshot.value as Map<dynamic, dynamic>;

      // Iterate over parent_students to find the route ID
      for (var studentId in parentStudents.keys) {
        String routeId = parentStudents[studentId]['routeId'];
        print("routeId: $routeId");

        // Fetch the active route details using the route ID
        DatabaseReference activeRoutesRef = FirebaseDatabase.instance.ref().child('Active Routes').child(routeId);
        DataSnapshot activeRouteSnapshot = await activeRoutesRef.once().then((event) => event.snapshot);

        if (activeRouteSnapshot.value != null) {
          Map<dynamic, dynamic> activeRouteData = activeRouteSnapshot.value as Map<dynamic, dynamic>;

          return {
            "route_id": routeId,
            "route_name": activeRouteData['route_name'],
            "start_address": activeRouteData['start_address'],
            "end_addresses": activeRouteData['end_addresses'],
            "school_id": activeRouteData['school_id'],
            "status": activeRouteData['status'],
            "created_at": activeRouteData['created_at'],
            "driver_id": activeRouteData['driver_id'],
            "driver_location": activeRouteData['driver_location'],
          };
        }
      }
    }

    return null; // Return null if no route is found
  }
}