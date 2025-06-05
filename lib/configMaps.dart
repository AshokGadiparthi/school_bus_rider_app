import 'package:firebase_auth/firebase_auth.dart';
import 'package:riders_app/Models/allUsers.dart';

String mapKey = "AIzaSyDGYmPNeQinxIs5wxPImh46UZ-s2LUqfYk";

User? firebaseUser;

Users? userCurrentInfo;

int driverRequestTimeOut = 40;

String? statusRide = "";
String? carDetailsDriver = "";
String rideStatus = "Driver is Coming";
String? driverName = "";
String? driverphone = "";

double starCounter=0.0;
String title="";

String carRideType="";

String serverToken = "key=AAAAqShEozU:APA91bGN5y5wonZBARz4KFxYnpBloLkHFOq87bMSOYcW3qGn1zW9yVT_r4SvVT-usPkCcGxlk4LmYbTOaoojkb36J32XMYgNM5_-mbkLyh5Ny5hpF_OVzDw8gPaK9rQSTXQwqn2VWfdW";