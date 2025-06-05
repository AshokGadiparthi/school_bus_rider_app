import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:riders_app/AllScreens/aboutScreen.dart';
import 'package:riders_app/AllScreens/loginScreen.dart';
import 'package:riders_app/AllScreens/mainscreen.dart';
import 'package:riders_app/AllScreens/registerationScreen.dart';
import 'package:riders_app/DataHandler/appData.dart';
import 'package:riders_app/controller/provider/address_provider.dart';
import 'package:riders_app/controller/provider/deal_of_the_day_provider/deal_of_the_provider.dart';
import 'package:riders_app/controller/provider/product_provider/product_provider.dart';
import 'package:riders_app/firebase_options.dart';
import 'package:riders_app/view/seller/add_product_screen/add_products_screen.dart';
import 'package:riders_app/view/user/user_bottom_nav_bar.dart';

void main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

DatabaseReference userRef =FirebaseDatabase.instance.ref().child("users");
DatabaseReference driverRef =FirebaseDatabase.instance.ref().child("drivers");
DatabaseReference newRequestsRef = FirebaseDatabase.instance.ref().child("Ride Requests");

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    print("Inside main: ");
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppData()),
        ChangeNotifierProvider(create: (context) => DealOfTheDayProvider()),
        ChangeNotifierProvider(create: (context) => AddressProvider()),
        ChangeNotifierProvider(create: (context) => SellerProductProvider()),
      ],
      child: MaterialApp(
        title: 'Taxi Rider App',
        theme: ThemeData(
          fontFamily: "Brand Bold",
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: FirebaseAuth.instance.currentUser == null ? LoginScreen.idScreen : UserBottomNavBar.idScreen,
        routes: {
          RegistrationScreen.idScreen: (context) => RegistrationScreen(),
          LoginScreen.idScreen: (context) => LoginScreen(),
          MainScreen.idScreen: (context) => MainScreen(),
          AboutScreen.idScreen: (context) => AboutScreen(),
          UserBottomNavBar.idScreen: (context) => UserBottomNavBar(),
          AddProductScreen.idScreen: (context) => AddProductScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}


