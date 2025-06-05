import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:riders_app/Assistants/requestAssistant.dart';
import 'package:riders_app/DataHandler/appData.dart';
import 'package:riders_app/Models/address.dart';
import 'package:riders_app/Models/allUsers.dart';
import 'package:riders_app/Models/directDetails.dart';
import 'package:riders_app/Models/history.dart';
import 'package:riders_app/configMaps.dart';
import 'package:riders_app/main.dart';
import 'package:http/http.dart' as http;

class AssistantMethods {

  static Future<DirectionDetails?> obtainPlaceDirectionDetailsWaypoint(LatLng initialPosition, LatLng finalPosition, List<LatLng> waypoints) async {
    print("obtainPlaceDirectionDetails");

    String waypointsString = waypoints.map((latLng) => '${latLng.latitude},${latLng.longitude}').join('|');
    Uri directionUrl = Uri.parse("https://maps.googleapis.com/maps/api/directions/json?origin=${initialPosition.latitude},${initialPosition.longitude}&destination=${finalPosition.latitude},${finalPosition.longitude}&waypoints=$waypointsString&key=$mapKey");

    var res = await RequestAssistant.getRequest(directionUrl);

    print("dddd");
    print(res);

    if(res == "failed") {
      return null;
    }

    DirectionDetails directionDetails = DirectionDetails();

    print("res:::");
    print(res);

    directionDetails.encodedPoints = res["routes"][0]["overview_polyline"]["points"];
    directionDetails.distanceText = res["routes"][0]["legs"][0]["distance"]["text"];
    directionDetails.distanceValue = res["routes"][0]["legs"][0]["distance"]["value"];
    directionDetails.durationText = res["routes"][0]["legs"][0]["duration"]["text"];
    directionDetails.durationValue = res["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetails;
  }


  static Future<String> searchCoordinateAddress(Position position, context) async {
    String placeAddress = "";
    String st1, st2, st3, st4;
    Uri url = Uri.parse("https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=${mapKey}");

    var response = await RequestAssistant.getRequest(url);

    if(response != "failed") {
      //placeAddress = response["results"][0]["formatted_address"];
      st1 = response["results"][0]["address_components"][2]["long_name"];
      st2 = response["results"][0]["address_components"][3]["long_name"];
      st3 = response["results"][0]["address_components"][4]["long_name"];
      st4 = response["results"][0]["address_components"][5]["long_name"];
      placeAddress = st1 + ", " + st2 + ", " + st3 + ", " + st4;

      print("placeAddress: "+placeAddress);

      Address userPickUpAddress = new Address();
      userPickUpAddress.longitude = position.longitude;
      userPickUpAddress.latitude = position.latitude;
      userPickUpAddress.placeName = placeAddress;

      Provider.of<AppData>(context, listen: false).updatePickUpLocationAddress(userPickUpAddress);
    }

    return placeAddress;
  }

  static Future<DirectionDetails?> obtainPlaceDirectionDetails(LatLng initialPosition, LatLng finalPosition) async {
    print("obtainPlaceDirectionDetails");
    Uri directionUrl = Uri.parse("https://maps.googleapis.com/maps/api/directions/json?origin=${finalPosition.latitude},${finalPosition.longitude}&destination=${initialPosition.latitude},${initialPosition.longitude}&key=$mapKey");

    var res = await RequestAssistant.getRequest(directionUrl);

    print("dddd");
    print(res);

    if(res == "failed") {
      return null;
    }

    DirectionDetails directionDetails = DirectionDetails();

    print("res:::");
    print(res);

    directionDetails.encodedPoints = res["routes"][0]["overview_polyline"]["points"];
    directionDetails.distanceText = res["routes"][0]["legs"][0]["distance"]["text"];
    directionDetails.distanceValue = res["routes"][0]["legs"][0]["distance"]["value"];
    directionDetails.durationText = res["routes"][0]["legs"][0]["duration"]["text"];
    directionDetails.durationValue = res["routes"][0]["legs"][0]["duration"]["value"];

    return directionDetails;
  }

  static int calculateFares(DirectionDetails? directionDetails) {
    if (directionDetails == null) {
      return 0; // Return 0 if directionDetails is null
    }

    //in terms USD
    double timeTraveledFare = (directionDetails.durationValue! / 60) * 0.20;
    double distancTraveledFare = (directionDetails.distanceValue! / 1000) * 0.20;
    double totalFareAmount = timeTraveledFare + distancTraveledFare;

    // Convert totalFareAmount to cents and truncate to integer
    int fareInCents = (totalFareAmount * 100).truncate();

    return fareInCents; // Return fare amount in cents
  }

  static void getCurrentOnlineUserInfo() async
  {
    firebaseUser = FirebaseAuth.instance.currentUser;
    String userId = firebaseUser!.uid!;
    DatabaseReference reference = FirebaseDatabase.instance.ref().child("users").child(userId);

    reference.once().then((DatabaseEvent databaseEvent) {
      if (databaseEvent.snapshot.value != null) {
        print("fff");
        Map<String, dynamic> dataMap = Map<String, dynamic>.from(databaseEvent.snapshot.value as Map);
        // Pass both the snapshot key and the data map to the constructor
        userCurrentInfo = Users.fromData(databaseEvent.snapshot.key, dataMap);
        print(userCurrentInfo);
        print("End...");
      } else {
        print("No user information found: ");
      }
    }).catchError((error) {
      print("An error occurred: $error");
    });
  }

  static double createRandomNumber(int num)
  {
    var random = Random();
    int radNumber = random.nextInt(num);
    return radNumber.toDouble();
  }

  static sendNotificationToDriver(String token, context, String ride_request_id) async
  {
    var destionation = Provider.of<AppData>(context, listen: false).dropOffLocation;
    Map<String, String> headerMap =
    {
      'Content-Type': 'application/json',
      'Authorization': serverToken,
    };

    Map notificationMap =
    {
      'body': 'DropOff Address, ${destionation!.placeName}',
      'title': 'New Ride Request'
    };

    Map dataMap =
    {
      'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      'id': '1',
      'status': 'done',
      'ride_request_id': ride_request_id,
    };

    Map sendNotificationMap =
    {
      "notification": notificationMap,
      "data": dataMap,
      "priority": "high",
      "to": token,
    };

    var res = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: headerMap,
      body: jsonEncode(sendNotificationMap),
    );
  }

  static String formatTripDate(String date)
  {
    DateTime dateTime = DateTime.parse(date);
    String formattedDate = "${DateFormat.MMMd().format(dateTime)}, ${DateFormat.y().format(dateTime)} - ${DateFormat.jm().format(dateTime)}";

    return formattedDate;
  }

  static void retrieveHistoryInfo(context)
  {

    print("inside retrieveHistoryInfo::");
    //retrieve and display Trip History
    newRequestsRef.orderByChild("rider_name").once().then((DatabaseEvent databaseEvent)
    {
      final data = databaseEvent.snapshot.value;

      // Check if the snapshot value is a Map before proceeding
      if (data != null && data is Map) {
        // Safely cast the data now that we've checked it
        Map<dynamic, dynamic> keys = data;

        // Update total number of trip counts to provider
        int tripCounter = keys.length;
        Provider.of<AppData>(context, listen: false).updateTripsCounter(tripCounter);

        // Update trip keys to provider
        List<String> tripHistoryKeys = [];
        keys.forEach((key, value) {
          tripHistoryKeys.add(key);
        });
        Provider.of<AppData>(context, listen: false).updateTripKeys(tripHistoryKeys);
        obtainTripRequestsHistoryData(context);
      }
    });


  }

  static void obtainTripRequestsHistoryData(context)
  {
    print("obtainTripRequestsHistoryData");
    var keys = Provider.of<AppData>(context, listen: false).tripHistoryKeys;

    for(String key in keys)
    {
      newRequestsRef.child(key).once().then((DatabaseEvent databaseEvent) {
        if(databaseEvent.snapshot.value != null)
        {
          newRequestsRef.child(key).child("rider_name").once().then((DatabaseEvent databaseEvent) {

            String name = databaseEvent.snapshot.value.toString();
            if(name == userCurrentInfo!.name!) {
              print("ddddd");
              print(databaseEvent.snapshot);
              var history = History.fromSnapshot(databaseEvent.snapshot);
              Provider.of<AppData>(context, listen: false).updateTripHistoryData(history);
            }

          });

        }
      });
    }
  }
}