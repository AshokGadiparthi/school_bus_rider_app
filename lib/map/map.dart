import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:riders_app/Assistants/assistantMethods.dart';
import 'package:riders_app/Assistants/mapKitAssistant.dart';
import 'package:riders_app/Models/active_route.dart';
import 'package:riders_app/Models/address.dart';
import 'package:riders_app/constants/common_functions.dart';
import 'package:riders_app/utils/colors.dart';

class MapDetailsScreen extends StatefulWidget {
  final ActiveRoute? activeRoutes;
  MapDetailsScreen({this.activeRoutes});

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  _MapDetailsScreenState createState() => _MapDetailsScreenState();
}

class _MapDetailsScreenState extends State<MapDetailsScreen> {
  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newRideGoogleMapController;
  Set<Marker> markersSet = Set<Marker>();
  Set<Circle> circleSet = Set<Circle>();
  Set<Polyline> polyLineSet = Set<Polyline>();
  List<LatLng> polylineCorOrdinates = [];
  PolylinePoints polylinePoints = PolylinePoints();
  double mapPaddingFromBottom = 0;
  var geoLocator = Geolocator();
  BitmapDescriptor? animatingMarkerIcon;
  Position? currentPosition;
  String status = "accepted";
  String durationRide = "";
  bool isRequestingDirection = false;
  String btnTitle = "Arrived";
  Color? btnColor = Colors.lightBlue;
  Timer? timer;
  int durationCounter = 0;
  StreamSubscription<DatabaseEvent>? rideStreamSubscription;
  String? carDetailsDriver;
  String? driverName;
  String? driverphone;
  String? rideStatus = "Trip Not Yet Started";
  String? statusRide;
  bool isRequestingPositionDetails = false;
  String? studentHomeAddress="";

  @override
  void initState() {
    super.initState();
    locatePosition();
    //acceptRideRequest();
  }

  @override
  void dispose() {
    rideStreamSubscription?.cancel();
    timer?.cancel();
    super.dispose();
  }

  void createIconMarker() {
    if (animatingMarkerIcon == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car_android.png").then((value) {
        animatingMarkerIcon = value;
      });
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  Future<void> locatePosition() async {
    final hasPermission = await _handleLocationPermission();
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLngPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition = new CameraPosition(target: latLngPosition, zoom: 14);
    newRideGoogleMapController?.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  void getRideLiveLocationUpdates(LatLng pickUpLatLng) {
    LatLng oldPos = LatLng(0, 0);
    final DatabaseReference rideRequestRef = FirebaseDatabase.instance.ref().child("Active Routes");

    rideStreamSubscription = rideRequestRef.onValue.listen((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        return;
      }
      //currentPosition = position;
      //LatLng mPosition = LatLng(position.latitude, position.longitude);
      for (var key in data.keys) {
        var routeData = data[key] as Map<dynamic, dynamic>?;
        if (routeData != null) {
          final String? carDetails = routeData["car_details"] as String?;
          if (carDetails != null) {
            setState(() {
              carDetailsDriver = carDetails;
            });
          }

          final String? name = routeData["driver_name"] as String?;
          final String? phone = routeData["driver_phone"] as String?;
          if (name != null) {
            setState(() {
              driverName = name;
            });
          }

          if (phone != null) {
            setState(() {
              driverphone = phone;
            });
          }

          if (routeData?["driver_location"] != null) {
            final lat = routeData?["driver_location"]["latitude"];
            final lng = routeData?["driver_location"]["longitude"];

            LatLng? mPosition;

            if (lat != null && lng != null) {
              try {
                double driverLat = double.parse(lat.toString());
                double driverLng = double.parse(lng.toString());

                mPosition = LatLng(driverLat, driverLng);

              } catch (e) {
                print("Error parsing latitude or longitude: $e");
              }
            }

            String? loggedInUserId = FirebaseAuth.instance.currentUser?.uid;
            var studentSnapshot = await FirebaseDatabase.instance
                .ref()
                .child("parent_students")
                .orderByChild("loggedInUserId")
                .equalTo(loggedInUserId)
                .once();

            if (studentSnapshot.snapshot.value != null) {
              var studentDetails = studentSnapshot.snapshot.value as Map<
                  dynamic,
                  dynamic>;
              String studentId = studentDetails.values.first["studentId"];

              List<dynamic> endAddresses = routeData["end_addresses"] as List<dynamic>;

              double? studentLat;
              double? studentLng;
              for (var address in endAddresses) {
                if (address["studentId"] == studentId) {
                  studentLat = double.tryParse(address["latitude"].toString());
                  studentLng = double.tryParse(address["longitude"].toString());
                  setState(() {
                    studentHomeAddress = address["address"];
                  });
                  break;
                }
              }
              print("studentHomeAddress: $studentHomeAddress");

              if (studentLat != null && studentLng != null) {
                final String? status = routeData["status"] as String?;
                if (status != null) {
                  statusRide = status;
                }

                if (statusRide == "started") {
                  updateRideTimeToDropOffLoc(mPosition!, LatLng(studentLat, studentLng));
                } else if (statusRide == "ended") {
                  setState(() {
                    rideStatus = "Trip completed..";
                  });
                } else  {
                  setState(() {
                    rideStatus = "Trip Not yet started..";
                  });
                }
              }
            }


            var rot = MapKitAssistant.getMarkerRotation(
                oldPos.latitude, oldPos.longitude, currentPosition!.latitude,
                currentPosition!.longitude);

            Marker animatingMarker = Marker(
              markerId: MarkerId("animating"),
              position: mPosition!,
              icon: animatingMarkerIcon!,
              rotation: rot.toDouble(),
              infoWindow: InfoWindow(title: "Current Location"),
            );

            if (mounted) {
              setState(() {
                CameraPosition cameraPosition = new CameraPosition(
                    target: mPosition!, zoom: 17);
                newRideGoogleMapController!.animateCamera(
                    CameraUpdate.newCameraPosition(cameraPosition));

                markersSet.removeWhere((marker) =>
                marker.markerId.value == "animating");
                markersSet.add(animatingMarker);
              });
            }

            oldPos = mPosition;
            updateRideDetails();

            String rideRequestId = widget.activeRoutes!.routeId!;
            Map locMap = {
              "latitude": currentPosition!.latitude.toString(),
              "longitude": currentPosition!.longitude.toString(),
            };
            print("locMap: $locMap");
            //newRouteRequestRef.child(rideRequestId).child("driver_location").set(locMap);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;
    createIconMarker();

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: mapPaddingFromBottom),
            onMapCreated: (GoogleMapController controller) async {
              _controllerGoogleMap.complete(controller);
              newRideGoogleMapController = controller;
              setState(() {
                mapPaddingFromBottom = 265.0;
              });

              await locatePosition();

              if (currentPosition == null) {
                print("Current position is null");
                return;
              }

              var currentLatLng = LatLng(currentPosition!.latitude, currentPosition!.longitude);
              var pickUpLatLng = LatLng(
                widget.activeRoutes!.startAddress!.latitude!,
                widget.activeRoutes!.startAddress!.longitude!,
              );

              getPlaceDirectionsWithWaypoints(
                pickUpLatLng,
                widget.activeRoutes!.endAddresses!.map((e) => LatLng(e.latitude!, e.longitude!)).toList(),
                widget.activeRoutes!.endAddresses!.map((e) => Address(
                  placeName: e.address,
                  latitude: e.latitude,
                  longitude: e.longitude,
                )).toList(),
                Address(
                  placeName: widget.activeRoutes!.startAddress!.address,
                  latitude: widget.activeRoutes!.startAddress!.latitude,
                  longitude: widget.activeRoutes!.startAddress!.longitude,
                ),
              );

              getRideLiveLocationUpdates(pickUpLatLng);
            },
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            markers: markersSet,
            circles: circleSet,
            polylines: polyLineSet,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            initialCameraPosition: MapDetailsScreen._kGooglePlex,
          ),

          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0), topRight: Radius.circular(16.0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 16.0,
                    spreadRadius: 0.5,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: 270.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  text: rideStatus,
                                  style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
                    ),
                    CommonFunctions.blankSpace(height * 0.01, 0),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey, // Specify the color of the border
                          width: 1.0, // Specify the thickness of the border
                        ),
                        borderRadius: BorderRadius.circular(10), // Rounded corners
                      ),
                      height: height * 0.15, // Adjust height as needed
                      width: width, // Adjust width as needed
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min, // Use the minimum space that content needs
                                crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(
                                        "images/pickicon.png",
                                        height: 16.0,
                                        width: 16.0,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        widget.activeRoutes!.startAddress!.address!,
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        height: 2,
                                        width: width * 0.80,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(colors: [white, teal, white]),
                                        ),
                                      ),
                                      CommonFunctions.blankSpace(
                                        height * 0.02,
                                        0,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Image.asset(
                                            "images/desticon.png",
                                            height: 16.0,
                                            width: 16.0,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: studentHomeAddress == null
                                                ? Text(
                                              'loading...',
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                            )
                                                : Text(
                                              studentHomeAddress!,
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> getPlaceDirectionsWithWaypoints(LatLng pickUpLatLng, List<LatLng> dropOffLatLngs, List<Address> dropOffAddresses, Address initialPos) async {
    LatLngBounds latLngBounds;
    List<LatLng> allPoints = [pickUpLatLng, ...dropOffLatLngs];

    double southWestLat = allPoints.map((p) => p.latitude).reduce(min);
    double southWestLng = allPoints.map((p) => p.longitude).reduce(min);
    double northEastLat = allPoints.map((p) => p.latitude).reduce(max);
    double northEastLng = allPoints.map((p) => p.longitude).reduce(max);

    latLngBounds = LatLngBounds(
      southwest: LatLng(southWestLat, southWestLng),
      northeast: LatLng(northEastLat, northEastLng),
    );

    newRideGoogleMapController?.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: InfoWindow(title: initialPos.placeName, snippet: "Pickup Location"),
      position: pickUpLatLng,
      markerId: MarkerId("pickUpId"),
    );

    if (mounted) {
      setState(() {
        markersSet.add(pickUpLocMarker);
      });
    }

    for (var i = 0; i < dropOffLatLngs.length; i++) {
      var dropOffLatLng = dropOffLatLngs[i];
      var address = dropOffAddresses[i];

      Marker dropOffLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: address.placeName ?? '', snippet: "Stop ${i + 1}"),
        position: dropOffLatLng,
        markerId: MarkerId("dropOffId_$i"),
      );

      if (mounted) {
        setState(() {
          markersSet.add(dropOffLocMarker);
        });
      }

      Circle dropOffLocCircle = Circle(
        fillColor: Colors.deepPurple,
        center: dropOffLatLng,
        radius: 12,
        strokeWidth: 4,
        strokeColor: Colors.deepPurple,
        circleId: CircleId("dropOffId_$i"),
      );

      if (mounted) {
        setState(() {
          circleSet.add(dropOffLocCircle);
        });
      }

      // Calculate travel time for each segment
      LatLng start = i == 0 ? pickUpLatLng : dropOffLatLngs[i - 1];
      String? travelTime = await getTravelTime(start, dropOffLatLng);
      if (travelTime != null && mounted) {
        setState(() {
          durationRide = "Time to reach stop ${i + 1}: $travelTime";
        });
      }
    }

    // Get directions and draw polylines
    polylineCorOrdinates.clear();
    LatLng previousLatLng = pickUpLatLng;

    List<LatLng> waypoints = [];
    for (int i = 0; i < dropOffLatLngs.length; i++) {
      waypoints.add(dropOffLatLngs[i]);
    }

    var details = await AssistantMethods.obtainPlaceDirectionDetailsWaypoint(previousLatLng, dropOffLatLngs.last, waypoints);

    if (details != null && details.encodedPoints != null) {
      List<PointLatLng> decodedPolyLinePointsResult = PolylinePoints().decodePolyline(details.encodedPoints!);

      if (decodedPolyLinePointsResult.isNotEmpty) {
        decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
          polylineCorOrdinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
        });
      }
    }

    if (mounted) {
      setState(() {
        Polyline polyline = Polyline(
          color: Colors.pink,
          polylineId: PolylineId("PolylineID"),
          jointType: JointType.round,
          points: polylineCorOrdinates,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true,
        );

        polyLineSet.add(polyline);
      });
    }
  }

  Future<String?> getTravelTime(LatLng startLatLng, LatLng endLatLng) async {
    var details = await AssistantMethods.obtainPlaceDirectionDetails(startLatLng, endLatLng);
    if (details == null) {
      return null;
    }
    return details.durationText;
  }

  void updateRideDetails() async {
    if (isRequestingDirection == false) {
      print("step1..");
      isRequestingDirection = true;

      if (currentPosition == null) {
        return;
      }
      print("step2..");
      var posLatLng = LatLng(currentPosition!.latitude, currentPosition!.longitude);
      LatLng destinationLatLng;
      print("step3..");

      if (status == "started") {
        destinationLatLng = LatLng(
          widget.activeRoutes!.startAddress!.latitude!,
          widget.activeRoutes!.startAddress!.longitude!,
        );
        print("step4..");
      } else {
        destinationLatLng = LatLng(
          widget.activeRoutes!.endAddresses!.last.latitude!,
          widget.activeRoutes!.endAddresses!.last.longitude!,
        );
        print("step5..");
      }

      var directionDetails = await AssistantMethods.obtainPlaceDirectionDetails(posLatLng, destinationLatLng);
      if (directionDetails != null && mounted) {
        setState(() {
          durationRide = directionDetails.durationText!;
        });
      }
      print("step6..");

      isRequestingDirection = false;
    }
  }

  void initTimer() {
    const interval = Duration(seconds: 1);
    timer = Timer.periodic(interval, (timer) {
      if (mounted) {
        setState(() {
          durationCounter += 1;
        });
      }
    });
  }

  void updateRideTimeToDropOffLoc(LatLng driverCurrentLocation, LatLng studentLocation) async {
    if (!isRequestingPositionDetails) {
      isRequestingPositionDetails = true;

      var details = await AssistantMethods.obtainPlaceDirectionDetails(driverCurrentLocation, studentLocation);
      if (details == null) {
        return;
      }
      setState(() {
        rideStatus = "Bus is coming to your place in - " + details.durationText!;
      });

      isRequestingPositionDetails = false;
    }
  }

}