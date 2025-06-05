// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:riders_app/constants/common_functions.dart';
import 'package:riders_app/school/add_driver.dart';
import 'package:riders_app/school/add_map_driver_route.dart';
import 'package:riders_app/school/add_route.dart';
import 'package:riders_app/school/add_school.dart';
import 'package:riders_app/school/add_school_bus.dart';
import 'package:riders_app/school/add_student.dart';
import 'package:riders_app/student/add_student.dart';
import 'package:riders_app/utils/colors.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  CarouselController todaysDealsCarouselController = CarouselController();

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery
        .of(context)
        .size
        .height;
    final width = MediaQuery
        .of(context)
        .size
        .width;
    final textTheme = Theme
        .of(context)
        .textTheme;
    return Scaffold(
      backgroundColor: white,
      appBar: PreferredSize(
        preferredSize: Size(width, height * 0.1),
        child: Container(
          padding: EdgeInsets.only(
              left: width * 0.03,
              right: width * 0.03,
              bottom: height * 0.012,
              top: height * 0.045),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: appBarGradientColor,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            children: [
              Image(
                image: const AssetImage(
                  'assets/images/busway_logo.png',
                ),
                height: height * 0.035,
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.notifications_none,
                  color: black,
                  size: height * 0.035,
                ),
              ),

            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CommonFunctions.blankSpace(height * 0.02, 0),
            YouGridBtons(width: width, textTheme: textTheme),
            Column(
              children: [
                Container(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teal,  // Background color of the button
                      foregroundColor: Colors.white,  // Color of the text
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)  // Rounded corners
                      ),
                      elevation: 4.0,  // Shadow elevation
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),  // Padding around the text
                      textStyle: TextStyle(
                        fontSize: 12,  // Font size for the text
                      ),
                      minimumSize: Size(80, 30),  // Minimum size of the button
                    ),
                    child: Text(
                      'Add School',  // Text displayed on the button
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      // Action to perform on button press
                      print('Add button pressed');
                      Navigator.push(
                        context,
                        PageTransition(
                          child: ManageSchoolsScreen(),
                          type: PageTransitionType.rightToLeft,
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teal,  // Background color of the button
                      foregroundColor: Colors.white,  // Color of the text
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)  // Rounded corners
                      ),
                      elevation: 4.0,  // Shadow elevation
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),  // Padding around the text
                      textStyle: TextStyle(
                        fontSize: 12,  // Font size for the text
                      ),
                      minimumSize: Size(80, 30),  // Minimum size of the button
                    ),
                    child: Text(
                      'Add Student',  // Text displayed on the button
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      // Action to perform on button press
                      print('Add button pressed');
                      Navigator.push(
                        context,
                        PageTransition(
                          child: ManageStudentsScreen(),
                          type: PageTransitionType.rightToLeft,
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teal,  // Background color of the button
                      foregroundColor: Colors.white,  // Color of the text
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)  // Rounded corners
                      ),
                      elevation: 4.0,  // Shadow elevation
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),  // Padding around the text
                      textStyle: TextStyle(
                        fontSize: 12,  // Font size for the text
                      ),
                      minimumSize: Size(80, 30),  // Minimum size of the button
                    ),
                    child: Text(
                      'Add Bus',  // Text displayed on the button
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      // Action to perform on button press
                      print('Add button pressed');
                      Navigator.push(
                        context,
                        PageTransition(
                          child: ManageBusesScreen(),
                          type: PageTransitionType.rightToLeft,
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teal,  // Background color of the button
                      foregroundColor: Colors.white,  // Color of the text
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)  // Rounded corners
                      ),
                      elevation: 4.0,  // Shadow elevation
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),  // Padding around the text
                      textStyle: TextStyle(
                        fontSize: 12,  // Font size for the text
                      ),
                      minimumSize: Size(80, 30),  // Minimum size of the button
                    ),
                    child: Text(
                      'Add Driver',  // Text displayed on the button
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      // Action to perform on button press
                      print('Add button pressed');
                      Navigator.push(
                        context,
                        PageTransition(
                          child: ManageDriversScreen(),
                          type: PageTransitionType.rightToLeft,
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teal,  // Background color of the button
                      foregroundColor: Colors.white,  // Color of the text
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)  // Rounded corners
                      ),
                      elevation: 4.0,  // Shadow elevation
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),  // Padding around the text
                      textStyle: TextStyle(
                        fontSize: 12,  // Font size for the text
                      ),
                      minimumSize: Size(80, 30),  // Minimum size of the button
                    ),
                    child: Text(
                      'Add Route',  // Text displayed on the button
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      // Action to perform on button press
                      print('Add button pressed');
                      Navigator.push(
                        context,
                        PageTransition(
                          child: AddRoute(),
                          type: PageTransitionType.rightToLeft,
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teal,  // Background color of the button
                      foregroundColor: Colors.white,  // Color of the text
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)  // Rounded corners
                      ),
                      elevation: 4.0,  // Shadow elevation
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),  // Padding around the text
                      textStyle: TextStyle(
                        fontSize: 12,  // Font size for the text
                      ),
                      minimumSize: Size(80, 30),  // Minimum size of the button
                    ),
                    child: Text(
                      'Map Driver Route',  // Text displayed on the button
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      // Action to perform on button press
                      print('Add button pressed');
                      Navigator.push(
                        context,
                        PageTransition(
                          child: MapDriverRouteScreen(),
                          type: PageTransitionType.rightToLeft,
                        ),
                      );
                    },
                  ),
                )
              ],
            )



          ],
        ),
      ),
    );
  }

}


class YouGridBtons extends StatelessWidget {
  const YouGridBtons({
    super.key,
    required this.width,
    required this.textTheme,
  });

  final double width;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: 6,
      padding: EdgeInsets.symmetric(horizontal: width * 0.04),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3.4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {

          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: grey,
              ),
              borderRadius: BorderRadius.circular(50),
              color: greyShade2,
            ),
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), // Adjust padding as needed
            alignment: Alignment.centerLeft,
            child: Builder(builder: (context) {
              IconData iconData;
              String textLabel;


              switch (index) {
                case 0:
                  iconData = Icons.person; // Profile icon
                  textLabel = 'Profile';
                  break;
                case 1:
                  iconData = Icons.settings; // Settings icon
                  textLabel = 'Settings';
                  break;
                case 2:
                  iconData = Icons.history; // Bus history icon
                  textLabel = 'Bus History';
                  break;
                case 3:
                  iconData = Icons.support_agent; // Support icon
                  textLabel = 'Support';
                  break;
                case 4:
                  iconData = Icons.feedback; // Feedback icon
                  textLabel = 'Feed Back';
                  break;
                default:
                  iconData = Icons.exit_to_app; // Logout icon
                  textLabel = 'Logout';
              }



              return Row(
                mainAxisSize: MainAxisSize.min, // Ensure the row takes only needed space
                children: [
                  Icon(iconData, color: Colors.black54), // You can choose a different color
                  SizedBox(width: 10), // Space between the icon and text
                  Text(
                    textLabel,
                    style: textTheme.bodyMedium,
                  ),
                ],
              );
            }),
          ),

        );
      },

    );
  }
}



