import 'dart:async';
import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:riders_app/AllScreens/HistoryScreen.dart';
import 'package:riders_app/AllScreens/aboutScreen.dart';
import 'package:riders_app/AllScreens/loginScreen.dart';
import 'package:riders_app/AllScreens/profileTabPage.dart';
import 'package:riders_app/AllScreens/ratingScreen.dart';
import 'package:riders_app/AllScreens/searchScreen.dart';
import 'package:riders_app/AllWidgets/CollectFareDialog.dart';
import 'package:riders_app/AllWidgets/Divider.dart';
import 'package:riders_app/AllWidgets/noDriverAvailableDialog.dart';
import 'package:riders_app/AllWidgets/progressDialog.dart';
import 'package:riders_app/Assistants/assistantMethods.dart';
import 'package:riders_app/Assistants/geoFireAssistant.dart';
import 'package:riders_app/Assistants/mapKitAssistant.dart';
import 'package:riders_app/DataHandler/appData.dart';
import 'package:riders_app/Models/directDetails.dart';
import 'package:riders_app/Models/nearbyAvailableDrivers.dart';
import 'package:riders_app/configMaps.dart';
import 'package:riders_app/main.dart';
import 'package:url_launcher/url_launcher.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen = "mainScreen";

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final Completer<GoogleMapController> _controllerGoogleMap =
      Completer<GoogleMapController>();
  GoogleMapController? newGoogleMapController;

  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  DirectionDetails? tripDirectionDetails;

  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};

  Position? currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingOfMap = 0;

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  double rideDetailsContainer = 0;
  double requestRideContainerHeight = 0;
  double searchContainerHeight = 300.0;
  double rideDetailsContainerHeight = 0;

  bool drawerOpen = true;
  bool nearbyAvailableDriverKeysLoaded = false;

  DatabaseReference? rideRequestRef;
  BitmapDescriptor? nearByIcon;

  List<NearbyAvailableDrivers>? availableDrivers;

  String state = "normal";

  double driverDetailsContainerHeight = 0;

  StreamSubscription<DatabaseEvent>? rideStreamSubscription;
  StreamSubscription<Position>? driverStreamSubscription;

  bool isRequestingPositionDetails = false;

  String uName="";

  bool isCurToPickDirectionFetched = false;
  bool isPickToDropDirectionFetched = false;

  Position? myPostion;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    AssistantMethods.getCurrentOnlineUserInfo();
  }

  void saveRideRequest() {
    rideRequestRef = FirebaseDatabase.instance.ref().child("Ride Requests").push();
    var pickUp = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map pickUpLocMap = {
      "latitude": pickUp?.latitude.toString(),
      "longitude": pickUp?.longitude.toString(),
    };

    Map dropOffLocMap = {
      "latitude": dropOff?.latitude.toString(),
      "longitude": dropOff?.longitude.toString(),
    };

    Map rideInfoMap = {
      "driver_id": "waiting",
      "payment_method": "cash",
      "pickup": pickUpLocMap,
      "dropff": dropOffLocMap,
      "created_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo?.name,
      "rider_phone": userCurrentInfo?.phone,
      "pickup_address": pickUp?.placeName,
      "dropoff_address": dropOff?.placeName,
      "ride_type": carRideType,
    };


    rideRequestRef?.set(rideInfoMap);

    rideStreamSubscription = rideRequestRef!.onValue.listen((event) async {
      // First ensure that the snapshot value is a Map
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if(data == null) {
        return;
      }

      final String? carDetails = data["car_details"] as String?;

      if(carDetails != null)
      {
        setState(() {
          carDetailsDriver = carDetails;
        });
      }

      final String? drivername = data["driver_name"] as String?;
      final String? driverPhone = data["driver_phone"] as String?;

      if(drivername != null)
      {
        setState(() {
          driverName = drivername;
        });
      }
      if(driverPhone != null)
      {
        setState(() {
          driverphone = driverPhone;
        });
      }
      LatLng? driverCurrentLocation;
      LatLng? riderPickUpLocation;
      LatLng? riderDropOffLocation;

      if (data != null && data["driver_location"] != null) {
        // Check if the latitude and longitude data exists and is not null
        final lat = data["driver_location"]["latitude"];
        final lng = data["driver_location"]["longitude"];
        final rlat = data["pickup"]["latitude"];
        final rlng = data["pickup"]["longitude"];
        final dlat = data["dropff"]["latitude"];
        final dlng = data["dropff"]["longitude"];



        final String? pickUpAddr = data["pickup_address"] as String?;
        final String? dropOffAddr = data["dropoff_address"] as String?;

        if (lat != null && lng != null && rlat != null && rlng != null) {
          try {
            double driverLat = double.parse(lat.toString());
            double driverLng = double.parse(lng.toString());
            double riderLat = double.parse(rlat.toString());
            double riderLng = double.parse(rlng.toString());
            double dropLat = double.parse(dlat.toString());
            double dropLng = double.parse(dlng.toString());

            // Assuming LatLng class is defined somewhere in your project or you are using a package that defines it
            driverCurrentLocation = LatLng(driverLat, driverLng);
            riderPickUpLocation = LatLng(riderLat, riderLng);
            riderDropOffLocation = LatLng(dropLat, dropLng);
            // Perform actions with driverCurrentLocation
          } catch (e) {
            print("Error parsing latitude or longitude: $e");
          }
        }

        if(statusRide == "accepted")
        {
          if (!isCurToPickDirectionFetched) {
            isCurToPickDirectionFetched = true; // Set the flag to true to prevent further calls
            await getPlaceDirection(driverCurrentLocation!, riderPickUpLocation!, "Current Loc", pickUpAddr!);
            //getRideLiveLocationUpdates(driverCurrentLocation);
          }
          updateRideTimeToPickUpLoc(driverCurrentLocation!);
        } else if(statusRide == "onride")
        {
          updateRideTimeToDropOffLoc(driverCurrentLocation!);
        } else if(statusRide == "arrived")
        {
          print("arrived arrived::");
          if (!isPickToDropDirectionFetched) {
            isPickToDropDirectionFetched = true; // Set the flag to true to prevent further calls
            await getPlaceDirection(riderPickUpLocation!, riderDropOffLocation!, pickUpAddr!, dropOffAddr!);
            //getRideLiveLocationUpdates(riderPickUpLocation!, riderDropOffLocation!);
          }
          setState(() {
            rideStatus = "Driver has Arrived.";
          });
        }

        print(rideStatus);

      }

      // Use a local variable that can accept null
      final String? status = data["status"] as String?;

      if(status != null) {
        statusRide = status; // Ensure `statusRide` can accept null or provide a default value
      }

      if(statusRide == "accepted") {
        getRideLiveLocationUpdates(driverCurrentLocation!, riderPickUpLocation!);
        displayDriverDetailsContainer();
        Geofire.stopListener();
        deleteGeofileMarkers();
      }


      final String? fares = data["fares"] as String?;
      if(statusRide == "ended")
      {
        if(fares != null)
        {
          int fare = int.parse(fares);
          var res = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context)=> CollectFareDialog(paymentMethod: "cash", fareAmount: fare,),
          );

          String driverId="";
          if(res == "close")
          {
            final String? driverid = data["driver_id"] as String?;
            if(driverid != null)
            {
              driverId = driverid;
            }

            Navigator.of(context).push(MaterialPageRoute(builder: (context) => RatingScreen(driverId: driverId)));

            rideRequestRef!.onDisconnect();
            rideRequestRef = null;
            rideStreamSubscription!.cancel();
            rideStreamSubscription = null;
            resetApp();
          }
        }
      }
    }) as StreamSubscription<DatabaseEvent>?;

  }

  void deleteGeofileMarkers()
  {
    setState(() {
      markersSet.removeWhere((element) => element.markerId.value.contains("driver"));
    });
  }

  static const colorizeColors = [
    Colors.purple,
    Colors.blue,
    Colors.yellow,
    Colors.red,
  ];

  static const colorizeTextStyle = TextStyle(
    fontSize: 30.0,
    fontFamily: 'Horizon',
  );

  void cancelRideRequest() {
    rideRequestRef?.remove();
    setState(() {
      state = "normal";
    });
  }

  void displayRequestRideContainer() {
    setState(() {
      requestRideContainerHeight = 250.0;
      rideDetailsContainer = 0;
      bottomPaddingOfMap = 230.0;
      drawerOpen = true;

    });

    saveRideRequest();
  }

  void displayDriverDetailsContainer()
  {
    setState(() {
      requestRideContainerHeight = 0.0;
      rideDetailsContainerHeight = 0.0;
      bottomPaddingOfMap = 295.0;
      driverDetailsContainerHeight = 285.0;
    });
  }

  resetApp() {
    setState(() {
      drawerOpen = true;

      searchContainerHeight = 300;
      rideDetailsContainer = 0;
      requestRideContainerHeight = 0;
      bottomPaddingOfMap = 230.0;

      polylineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
      isCurToPickDirectionFetched = false;
      isPickToDropDirectionFetched = false;

      statusRide = "";
      driverName = "";
      driverphone = "";
      carDetailsDriver = "";
      rideStatus = "Driver is Coming";
      driverDetailsContainerHeight = 0.0;

    });

    locatePosition();
  }

  void displayRideDisplayContainer() async {

    var initialPos = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    double? initialLatitude = initialPos?.latitude;
    double? initialLongitude = initialPos?.longitude;
    double? finalLatitude = finalPos?.latitude;
    double? finalLongitude = finalPos?.longitude;

    var pickUpLatLng;
    var dropOffLatLng;

    if (initialLatitude != null && initialLongitude != null && finalLatitude != null && finalLongitude != null) {
      pickUpLatLng = LatLng(initialLatitude, initialLongitude);
      dropOffLatLng = LatLng(finalLatitude, finalLongitude);
    }

    String? pickUpLocName = initialPos?.placeName;
    String? dropOffLocName = finalPos?.placeName;

    await getPlaceDirection(pickUpLatLng, dropOffLatLng, pickUpLocName!, dropOffLocName!);

    setState(() {
      searchContainerHeight = 0;
      rideDetailsContainer = 340.0;
      bottomPaddingOfMap = 360.0;
      drawerOpen = false;
    });

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

  void locatePosition() async
  {
    final hasPermission = await _handleLocationPermission();
    print("Inside locate Position");
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLatPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition = new CameraPosition(target: latLatPosition, zoom: 24);
    newGoogleMapController?.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String address = await AssistantMethods.searchCoordinateAddress(position, context);
    print("Your address is:"+address);

    initGeoFireListner();

    uName = userCurrentInfo!.name!;

    AssistantMethods.retrieveHistoryInfo(context);

  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    createIconMarker();
    return Scaffold(
      key: scaffoldKey,
      drawer: Container(
        color: Colors.white,
        width: 255.0,
        child: Drawer(
          child: ListView(
            children: [
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Image.asset(
                        "images/user_icon.png",
                        height: 65.0,
                        width: 65.0,
                      ),
                      SizedBox(
                        width: 16.0,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            uName,
                            style: TextStyle(
                                fontSize: 16.0, fontFamily: "Brand Bold"),
                          ),
                          SizedBox(
                            height: 6.0,
                          ),
                          GestureDetector(
                              onTap: ()
                              {
                                Navigator.push(context, MaterialPageRoute(builder: (context)=> ProfileTabPage()));
                              },
                              child: Text("Visit Profile")),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              DividerWidget(),
              SizedBox(
                height: 12.0,
              ),
              //Drawer Body Controllers
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context)=> HistoryScreen()));
                },
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text(
                    "History",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context)=> ProfileTabPage()));
                  },
                  child: Text(
                    "Visit Profile",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(context, AboutScreen.idScreen, (route) => false);
                },
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text(
                    "About",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(context, LoginScreen.idScreen, (route) => false);
                },
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text(
                    "Sign Out",
                    style: TextStyle(fontSize: 15.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              Future.delayed(Duration(milliseconds: 500), () {
                _controllerGoogleMap.complete(controller);
                newGoogleMapController = controller;

                setState(() {
                  bottomPaddingOfMap = 300.0;
                });

                locatePosition();
              });
            },
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap, top: 25.0),
            mapType: MapType.normal,
            initialCameraPosition: _kGooglePlex,

          ),


          //Hamburger Button for Drawer
          Positioned(
            top: 38.0,
            left: 22.0,
            child: GestureDetector(
              onTap: () {
                if(drawerOpen) {
                  scaffoldKey.currentState?.openDrawer();
                } else {
                  resetApp();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22.0),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black,
                          blurRadius: 6.0,
                          spreadRadius: 0.5,
                          offset: Offset(0.7, 0.7))
                    ]),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    ((drawerOpen) ? Icons.menu : Icons.close),
                    color: Colors.black,
                  ),
                  radius: 20.0,
                ),
              ),
            ),
          ),

          Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 0.0,
            child: AnimatedSize(
              curve: Curves.bounceIn,
              duration: new Duration(microseconds: 160),
              child: Container(
                height: searchContainerHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18.0),
                        topRight: Radius.circular(18.0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 16.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      ),
                    ]),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 6.0,
                      ),
                      Text(
                        "Hi there",
                        style: TextStyle(fontSize: 10.0),
                      ),
                      Text(
                        "Where to go?",
                        style:
                            TextStyle(fontSize: 20.0, fontFamily: "Brand Bold"),
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      GestureDetector(
                        onTap: () async
                        {
                          var res = await Navigator.push(context, MaterialPageRoute(builder: (context)=> SearchScreen()));

                          if(res == "obtainDirection") {
                            //await getPlaceDirection();
                            displayRideDisplayContainer();
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black,
                                  blurRadius: 16.0,
                                  spreadRadius: 0.5,
                                  offset: Offset(0.7, 0.7),
                                ),
                              ]),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.blueAccent,
                                ),
                                SizedBox(
                                  width: 10.0,
                                ),
                                Text("Search Drop Off")
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 24.0,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.home,
                            color: Colors.grey,
                          ),
                          SizedBox(
                            width: 12.0,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  Provider.of<AppData>(context).pickUpLocation != null
                                      ? Provider.of<AppData>(context).pickUpLocation?.placeName ?? "Add Home"
                                      : "Add Home",
                              ),

                              SizedBox(
                                height: 4.0,
                              ),
                              Text(
                                "Your living home address",
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12.0),
                              ),
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      DividerWidget(),
                      SizedBox(
                        height: 16.0,
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.work,
                            color: Colors.grey,
                          ),
                          SizedBox(
                            width: 12.0,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Add Work"),
                              SizedBox(
                                height: 4.0,
                              ),
                              Text(
                                "Your living office address",
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 12.0),
                              ),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),

          //Ride Details Ui
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              curve: Curves.bounceIn,
              duration: new Duration(microseconds: 160),
              child: Container(
                height: rideDetailsContainer,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0), topRight: Radius.circular(16.0),),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 16.0,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 17.0),
                  child: Column(
                    children: [

                      //bike ride
                      GestureDetector(
                        onTap: ()
                        {
                          displayToastMessage("searching Bike...", context);

                          setState(() {
                            state = "requesting";
                            carRideType = "bike";
                          });
                          displayRequestRideContainer();
                          availableDrivers = GeoFireAssistant.nearByAvailableDriversList;
                          searchNearestDriver();
                        },
                        child: Container(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Image.asset("images/bike.png", height: 70.0, width: 80.0,),
                                SizedBox(width: 16.0,),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Bike", style: TextStyle(fontSize: 18.0, fontFamily: "Brand Bold",),
                                    ),
                                    Text(
                                      ((tripDirectionDetails != null) ? tripDirectionDetails!.distanceText! : '') , style: TextStyle(fontSize: 16.0, color: Colors.grey,),
                                    ),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Text(
                                  ((tripDirectionDetails != null) ? '\$${(AssistantMethods.calculateFares(tripDirectionDetails))/2}' : ''), style: TextStyle(fontFamily: "Brand Bold",),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 10.0,),
                      Divider(height: 2.0, thickness: 2.0,),
                      SizedBox(height: 10.0,),

                      //uber-go ride
                      GestureDetector(
                        onTap: ()
                        {
                          displayToastMessage("searching Uber-Go...", context);

                          setState(() {
                            state = "requesting";
                            carRideType = "uber-go";
                          });
                          displayRequestRideContainer();
                          availableDrivers = GeoFireAssistant.nearByAvailableDriversList;
                          searchNearestDriver();
                        },
                        child: Container(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Image.asset("images/ubergo.png", height: 70.0, width: 80.0,),
                                SizedBox(width: 16.0,),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Uber-Go", style: TextStyle(fontSize: 18.0, fontFamily: "Brand Bold",),
                                    ),
                                    Text(
                                      ((tripDirectionDetails != null) ? tripDirectionDetails!.distanceText! : '') , style: TextStyle(fontSize: 16.0, color: Colors.grey,),
                                    ),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Text(
                                  ((tripDirectionDetails != null) ? '\$${AssistantMethods.calculateFares(tripDirectionDetails)}' : ''), style: TextStyle(fontFamily: "Brand Bold",),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 10.0,),
                      Divider(height: 2.0, thickness: 2.0,),
                      SizedBox(height: 10.0,),

                      //uber-x ride
                      GestureDetector(
                        onTap: ()
                        {
                          displayToastMessage("searching Uber-X...", context);

                          setState(() {
                            state = "requesting";
                            carRideType = "uber-x";
                          });
                          displayRequestRideContainer();
                          availableDrivers = GeoFireAssistant.nearByAvailableDriversList;
                          searchNearestDriver();
                        },
                        child: Container(
                          width: double.infinity,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Image.asset("images/uberx.png", height: 70.0, width: 80.0,),
                                SizedBox(width: 16.0,),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Uber-X", style: TextStyle(fontSize: 18.0, fontFamily: "Brand Bold",),
                                    ),
                                    Text(
                                      ((tripDirectionDetails != null) ? tripDirectionDetails!.distanceText! : '') , style: TextStyle(fontSize: 16.0, color: Colors.grey,),
                                    ),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Text(
                                  ((tripDirectionDetails != null) ? '\$${(AssistantMethods.calculateFares(tripDirectionDetails))*2}' : ''), style: TextStyle(fontFamily: "Brand Bold",),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 10.0,),
                      Divider(height: 2.0, thickness: 2.0,),
                      SizedBox(height: 10.0,),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            Icon(FontAwesomeIcons.moneyCheckAlt, size: 18.0, color: Colors.black54,),
                            SizedBox(width: 16.0,),
                            Text("Cash"),
                            SizedBox(width: 6.0,),
                            Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 16.0,),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              ),
            ),

          ),

          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0), topRight: Radius.circular(16.0),),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black54,
                    offset: Offset(0.7, 0.7),
                  ),
                ]
              ),
              height: requestRideContainerHeight,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    SizedBox(height: 12.0,),

                    SizedBox(
                      width: double.infinity,
                      child: AnimatedTextKit(
                        animatedTexts: [
                          ColorizeAnimatedText(
                            'Requesting ride',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                            textAlign: TextAlign.center,

                          ),
                          ColorizeAnimatedText(
                            'Please Wait',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                            textAlign: TextAlign.center,
                          ),
                          ColorizeAnimatedText(
                            'Finding a Driver',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                            textAlign: TextAlign.center,
                          ),
                        ],
                        isRepeatingAnimation: true,
                        onTap: () {
                          print("Tap Event");
                        },
                      ),
                    ),

                    SizedBox(height: 22.0,),

                    GestureDetector(
                      onTap: () {
                        cancelRideRequest();
                        resetApp();
                      },
                      child: Container(
                        height: 60.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26.0),
                          border: Border.all(width: 2.0, color: Colors.grey),
                        ),
                        child: Icon(Icons.close, size: 26.0,),
                      ),
                    ),

                    SizedBox(height: 12.0,),

                    Container(
                      width: double.infinity,
                      child: Text("Cancel Ride", textAlign: TextAlign.center, style: TextStyle(fontSize: 12.0),),
                    )
                  ],
                ),
              ),
            ),
          ),

          //Display Assisned Driver Info
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16.0), topRight: Radius.circular(16.0),),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 0.5,
                    blurRadius: 16.0,
                    color: Colors.black54,
                    offset: Offset(0.7, 0.7),
                  ),
                ],
              ),
              height: driverDetailsContainerHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 6.0,),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(rideStatus, textAlign: TextAlign.center, style: TextStyle(fontSize: 20.0, fontFamily: "Brand Bold"),),
                      ],
                    ),

                    SizedBox(height: 22.0,),

                    Divider(height: 2.0, thickness: 2.0,),

                    SizedBox(height: 22.0,),

                    Text(carDetailsDriver!, style: TextStyle(color: Colors.grey),),

                    Text(driverName!, style: TextStyle(fontSize: 20.0),),

                    SizedBox(height: 22.0,),

                    Divider(height: 2.0, thickness: 2.0,),

                    SizedBox(height: 22.0,),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //call button
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0),
                          child: ElevatedButton(
                            /*shape: new RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(24.0),
                            ),*/
                            onPressed: () async
                            {
                              launch(('tel://${driverphone}'));
                            },
                            style: ElevatedButton.styleFrom(foregroundColor: Colors.black87),
                            child: Padding(
                              padding: EdgeInsets.all(17.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text("Call Driver   ", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white),),
                                  Icon(Icons.call, color: Colors.white, size: 26.0,),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getPlaceDirection(LatLng pickUpLatLng, LatLng dropOffLatLng, String pickUpLocName, String dropOffLocName) async {


    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(message: "Please wait..."),
    );
    var details;

    try {


      if (pickUpLatLng != null && dropOffLatLng != null) {
        details = await AssistantMethods.obtainPlaceDirectionDetails(pickUpLatLng, dropOffLatLng);
        // Process details as needed
      }

      setState(() {
        tripDirectionDetails = details;
      });

      Navigator.pop(context);

      print("This is Encoded points ::");
      print(details);
    } catch (e) {
      Navigator.pop(context); // Ensure dialog is closed in case of an error
      print("Error fetching place direction details: $e");
    }



    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResult = polylinePoints.decodePolyline(details.encodedPoints);

    pLineCoordinates.clear();

    if(decodedPolyLinePointsResult.isNotEmpty)
    {
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polylineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.pink,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if(pickUpLatLng.latitude > dropOffLatLng.latitude  &&  pickUpLatLng.longitude > dropOffLatLng.longitude)
    {
      latLngBounds = LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    }
    else if(pickUpLatLng.longitude > dropOffLatLng.longitude)
    {
      latLngBounds = LatLngBounds(southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude), northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    }
    else if(pickUpLatLng.latitude > dropOffLatLng.latitude)
    {
      latLngBounds = LatLngBounds(southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude), northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    }
    else
    {
      latLngBounds = LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }

    newGoogleMapController?.animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      //infoWindow: InfoWindow(title: initialPos?.placeName, snippet: "my Location"),
      infoWindow: InfoWindow(title: pickUpLocName, snippet: "my Location"),
      position: pickUpLatLng,
      markerId: MarkerId("pickUpId"),
    );

    Marker dropOffLocMarker = Marker(
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      //infoWindow: InfoWindow(title: finalPos?.placeName, snippet: "DropOff Location"),
      infoWindow: InfoWindow(title: dropOffLocName, snippet: "DropOff Location"),
      position: dropOffLatLng,
      markerId: MarkerId("dropOffId"),
    );

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet.add(dropOffLocMarker);
    });

    Circle pickUpLocCircle = Circle(
      fillColor: Colors.blueAccent,
      center: pickUpLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.blueAccent,
      circleId: CircleId("pickUpId"),
    );

    Circle dropOffLocCircle = Circle(
      fillColor: Colors.deepPurple,
      center: dropOffLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.deepPurple,
      circleId: CircleId("dropOffId"),
    );

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });

  }

  void initGeoFireListner() {
    Geofire.initialize("availableDrivers");
    double? lat = currentPosition?.latitude;
    double? lon = currentPosition?.longitude;
    //comment
    Geofire.queryAtLocation(lat!, lon!, 5)?.listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:
            NearbyAvailableDrivers nearbyAvailableDrivers = new NearbyAvailableDrivers();
            nearbyAvailableDrivers.key = map["key"];
            nearbyAvailableDrivers.latitude = map["latitude"];
            nearbyAvailableDrivers.longitude = map["longitude"];
            GeoFireAssistant.nearByAvailableDriversList.add(nearbyAvailableDrivers);
            if(nearbyAvailableDriverKeysLoaded == true) {
              updateAvailableDriversOnMap();
            }
            break;

          case Geofire.onKeyExited:
            GeoFireAssistant.removeDriverFromList(map["key"]);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onKeyMoved:
            NearbyAvailableDrivers nearbyAvailableDrivers = new NearbyAvailableDrivers();
            nearbyAvailableDrivers.key = map["key"];
            nearbyAvailableDrivers.latitude = map["latitude"];
            nearbyAvailableDrivers.longitude = map["longitude"];
            GeoFireAssistant.updateDriverNearbyLocation(nearbyAvailableDrivers);
            updateAvailableDriversOnMap();
            break;

          case Geofire.onGeoQueryReady:
          // All Intial Data is loaded
            updateAvailableDriversOnMap();
            print(map['result']);

            break;
        }
      }

      setState(() {});
    });
    //comment
  }

  void updateAvailableDriversOnMap()
  {
    setState(() {
      markersSet.clear();
    });

    Set<Marker> tMakers = Set<Marker>();
    for(NearbyAvailableDrivers driver in GeoFireAssistant.nearByAvailableDriversList)
    {
      double? lat = driver?.latitude;
      double? lon = driver?.longitude;
      LatLng driverAvaiablePosition = LatLng(lat!, lon!);

      Marker marker = Marker(
        markerId: MarkerId('driver${driver.key}'),
        position: driverAvaiablePosition,
        icon: nearByIcon!,
        rotation: AssistantMethods.createRandomNumber(360),
      );

      tMakers.add(marker);
    }
    setState(() {
      markersSet = tMakers;
    });
  }

  void createIconMarker()
  {
    if(nearByIcon == null)
    {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car_ios.png")
          .then((value)
      {
        nearByIcon = value;
      });
    }
  }

  void noDriverFound()
  {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => NoDriverAvailableDialog()
    );
  }

  void searchNearestDriver()
  {
    if(availableDrivers!.length == 0)
    {
      cancelRideRequest();
      resetApp();
      noDriverFound();
      return;
    }

    var driver = availableDrivers?[0];
    driverRef.child(driver!.key!).child("car_details").child("type").once().then((DatabaseEvent databaseEvent) async
    {
      if(await databaseEvent.snapshot.value != null)
      {
        String carType = databaseEvent.snapshot.value.toString();
        if(carType == carRideType)
        {
          notifyDriver(driver);
          availableDrivers!.removeAt(0);
        }
        else
        {
          displayToastMessage(carRideType + " drivers not available. Try again.", context);
        }
      }
      else
      {
        displayToastMessage("No car found. Try again.", context);
      }
    });
  }

  void notifyDriver(NearbyAvailableDrivers? driver) {
    driverRef.child(driver!.key!).child("newRide").set(rideRequestRef!.key);

    driverRef.child(driver!.key!).child("token").once().then((DatabaseEvent databaseEvent){
      if(databaseEvent.snapshot.value != null)
      {
        String token = databaseEvent.snapshot.value.toString();
        AssistantMethods.sendNotificationToDriver(token, context, rideRequestRef!.key!);
      }
      else
      {
        return;
      }

      const oneSecondPassed = Duration(seconds: 1);
      var timer = Timer.periodic(oneSecondPassed, (timer) {
        if(state != "requesting")
        {
          driverRef.child(driver!.key!).child("newRide").set("cancelled");
          driverRef.child(driver!.key!).child("newRide").onDisconnect();
          driverRequestTimeOut = 40;
          timer.cancel();
        }

        driverRequestTimeOut = driverRequestTimeOut - 1;

        driverRef.child(driver!.key!).child("newRide").onValue.listen((event) {
          if(event.snapshot.value.toString() == "accepted")
          {
            driverRef.child(driver!.key!).child("newRide").onDisconnect();
            driverRequestTimeOut = 40;
            timer.cancel();
          }
        });

        if(driverRequestTimeOut == 0)
        {
          driverRef.child(driver!.key!).child("newRide").set("timeout");
          driverRef.child(driver!.key!).child("newRide").onDisconnect();
          driverRequestTimeOut = 40;
          timer.cancel();

          searchNearestDriver();
        }
      });
    });
  }

  void updateRideTimeToPickUpLoc(LatLng driverCurrentLocation) async
  {
    if(isRequestingPositionDetails == false)
    {
      isRequestingPositionDetails = true;

      var positionUserLatLng = LatLng(currentPosition!.latitude, currentPosition!.longitude);
      var details = await AssistantMethods.obtainPlaceDirectionDetails(driverCurrentLocation, positionUserLatLng);
      if(details == null)
      {
        return;
      }
      setState(() {
        rideStatus = "Driver is Coming - " + details!.durationText!;
      });

      isRequestingPositionDetails = false;
    }
  }

  void updateRideTimeToDropOffLoc(LatLng driverCurrentLocation) async
  {
    if(isRequestingPositionDetails == false)
    {
      isRequestingPositionDetails = true;

      var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;
      var dropOffUserLatLng = LatLng(dropOff!.latitude!, dropOff!.longitude!);

      var details = await AssistantMethods.obtainPlaceDirectionDetails(driverCurrentLocation, dropOffUserLatLng);
      if(details == null)
      {
        return;
      }
      setState(() {
        rideStatus = "Going to Destination - " + details!.durationText!;
      });

      isRequestingPositionDetails = false;
    }
  }

  displayToastMessage(message, BuildContext context) {
    Fluttertoast.showToast(msg: message);
  }

  void getRideLiveLocationUpdates(LatLng initialDriverPosition, LatLng riderPickupLocation) {
    LatLng oldPos = LatLng(0, 0);

    driverStreamSubscription = Geolocator.getPositionStream().listen((Position position) {
      LatLng newPos = LatLng(initialDriverPosition.latitude, initialDriverPosition.longitude);

      var rotation = MapKitAssistant.getMarkerRotation(oldPos.latitude, oldPos.longitude, newPos.latitude, newPos.longitude);

      Marker animatingMarker = Marker(
        markerId: MarkerId("animating"),
        position: newPos,
        icon: nearByIcon!, // This should be your car icon
        rotation: rotation.toDouble(),
        infoWindow: InfoWindow(title: "Current Location"),
      );

      setState(() {
        // Adjust the bounds only if the driver has moved significantly or on initial setup
        if (shouldUpdateBounds(newPos, oldPos)) {
          updateCameraBounds(newPos, initialDriverPosition);
        }

        markersSet.removeWhere((marker) => marker.markerId.value == "animating");
        markersSet.add(animatingMarker);

        oldPos = newPos; // Update the old position for the next update
      });
    });
  }

  bool shouldUpdateBounds(LatLng newPos, LatLng oldPos) {
    // Implement logic to determine if bounds should update, e.g., significant distance change
    return (Geolocator.distanceBetween(oldPos.latitude, oldPos.longitude, newPos.latitude, newPos.longitude) > 100); // distance in meters
  }

  void updateCameraBounds(LatLng newPos, LatLng initialDriverPosition) {
    double northLat = max(newPos.latitude, initialDriverPosition.latitude);
    double southLat = min(newPos.latitude, initialDriverPosition.latitude);
    double eastLng = max(newPos.longitude, initialDriverPosition.longitude);
    double westLng = min(newPos.longitude, initialDriverPosition.longitude);

    LatLng northeast = LatLng(northLat, eastLng);
    LatLng southwest = LatLng(southLat, westLng);

    LatLngBounds bounds = LatLngBounds(northeast: northeast, southwest: southwest);
    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 50); // 100 pixels of padding
    CameraPosition cameraPosition = CameraPosition(
        target: newPos, // newPos is the driver's current location
        zoom: 17 // Zoom level, higher numbers are closer. Adjust based on your needs
    );
    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }




}
