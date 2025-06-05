import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:riders_app/configMaps.dart';
import 'package:smooth_star_rating_null_safety/smooth_star_rating_null_safety.dart';

class RatingScreen extends StatefulWidget {
  final String? driverId;

  RatingScreen({this.driverId});

  @override
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double starCounter = 0.0; // Ensure this is initialized properly
  String title = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.all(5.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 22.0),
              Text(
                "Rate this Driver",
                style: TextStyle(fontSize: 20.0, fontFamily: "Brand Bold", color: Colors.black54),
              ),
              SizedBox(height: 22.0),
              Divider(height: 2.0, thickness: 2.0),
              SizedBox(height: 16.0),
              SmoothStarRating(
                rating: starCounter,
                color: Colors.green,
                allowHalfRating: false,
                starCount: 5,
                size: 45,
                onRatingChanged: (value) {
                  setState(() {
                    starCounter = value;
                    switch (starCounter.round()) {
                      case 1:
                        title = "Very Bad";
                        break;
                      case 2:
                        title = "Bad";
                        break;
                      case 3:
                        title = "Good";
                        break;
                      case 4:
                        title = "Very Good";
                        break;
                      case 5:
                        title = "Excellent";
                        break;
                      default:
                        title = ""; // Handle unexpected cases
                    }
                  });
                },
              ),
              SizedBox(height: 14.0),
              Text(title, style: TextStyle(fontSize: 55.0, fontFamily: "Signatra", color: Colors.green)),
              SizedBox(height: 16.0),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.0),
                    ),
                    padding: EdgeInsets.all(16.0),
                  ),
                  onPressed: () async {
                    DatabaseReference driverRatingRef = FirebaseDatabase.instance.ref()
                        .child("drivers")
                        .child(widget.driverId!)
                        .child("ratings");

                    DataSnapshot snap = await driverRatingRef.get();
                    if (snap.exists) {
                      double oldRatings = double.parse(snap.value.toString());
                      double addRatings = oldRatings + starCounter;
                      double averageRatings = addRatings / 2;
                      driverRatingRef.set(averageRatings.toString());
                    } else {
                      driverRatingRef.set(starCounter.toString());
                    }

                    Navigator.pop(context);
                  },
                  child: Text("Submit", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              SizedBox(height: 30.0),
            ],
          ),
        ),
      ),
    );
  }
}