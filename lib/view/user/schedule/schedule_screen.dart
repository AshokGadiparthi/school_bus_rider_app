// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:riders_app/constants/common_functions.dart';
import 'package:riders_app/controller/provider/address_provider.dart';
import 'package:riders_app/controller/provider/deal_of_the_day_provider/deal_of_the_provider.dart';
import 'package:riders_app/services/user_data_crud_services/user_data_CRUD_services.dart';
import 'package:riders_app/student/student_details.dart';
import 'package:riders_app/utils/colors.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

class ScheduleScreen extends StatefulWidget {
  static const String idScreen = "schedule";
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  CarouselController todaysDealsCarouselController = CarouselController();



  headphoneDeals(int index) {
    switch (index) {
      case 0:
        return 'Bose';
      case 1:
        return 'boAt';
      case 2:
        return 'Sony';
      case 3:
        return 'OnePlus';
    }
  }

  clothingDeals(int index) {
    switch (index) {
      case 0:
        return 'Kurtas, sarees & more';
      case 1:
        return 'Tops, dresses & more';
      case 2:
        return 'T-Shirt, jeans & more';
      case 3:
        return 'View all';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AddressProvider>().getCurrentSelectedAddress();
      context.read<DealOfTheDayProvider>().fetchTodaysDeal();
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;
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
            HomeScreenUserAddressBar(height: height, width: width),
            CommonFunctions.blankSpace(height * 0.01, 0),
            TodaysDealHomeScreenWidget(
                todaysDealsCarouselController: todaysDealsCarouselController),


          ],
        ),
      ),
    );
  }

  Container otherOfferGridWidget(
      {required String title,
        required String textBtnName,
        required List<String> productPicNamesList,
        required String offerFor}) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;

    return Container(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.03,
          vertical: height * 0.01,
        ),
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            CommonFunctions.blankSpace(
              height * 0.01,
              0,
            ),
            GridView.builder(
                itemCount: 4,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {},
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: DecorationImage(
                                image: AssetImage(
                                    'assets/images/offersNsponcered/${productPicNamesList[index]}'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          offerFor == 'headphones'
                              ? headphoneDeals(index)
                              : clothingDeals(index),
                          style: textTheme.bodyMedium,
                        )
                      ],
                    ),
                  );
                }),
            TextButton(
              onPressed: () {},
              child: Text(
                textBtnName,
                style: textTheme.bodySmall!.copyWith(
                  color: blue,
                ),
              ),
            ),
          ],
        ));
  }
}

class TodaysDealHomeScreenWidget extends StatelessWidget {
  const TodaysDealHomeScreenWidget({
    super.key,
    required this.todaysDealsCarouselController,
  });

  final CarouselController todaysDealsCarouselController;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Consumer<DealOfTheDayProvider>(
          builder: (context, dealOfTheDayProvider, child) {
            if (dealOfTheDayProvider.dealsFetched == false) {
              return Container(
                height: height * 0.2,
                width: width,
                alignment: Alignment.center,
                child: Text(
                  'Loading Latest Deals',
                  style: textTheme.bodyMedium,
                ),
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Column(
                    children: List.generate(dealOfTheDayProvider.deals.length, (index) {
                      final deal = dealOfTheDayProvider.deals[index];  // Get the current deal item
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16.0),  // Adds space below each container
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,  // Specify the color of the border
                              width: 1.0,  // Specify the thickness of the border
                            ),
                            borderRadius: BorderRadius.circular(10),  // Rounded corners
                          ),
                          height: height * 0.20,  // Adjust height as needed
                          width: width,  // Adjust width as needed
                          child: Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min, // Use the minimum space that content needs
                                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          // Action to perform on tap, e.g., navigate to another page
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => StudentAllDetailsScreen(),
                                            ),
                                          );
                                        },
                                        child: Column(  // Using Column to contain multiple children
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              '${deal.name}',  // Use the name from the deal
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),

                                          ],
                                        ),
                                      ),

                                      SizedBox(height: 8),  // Space after trip status before the divider

                                      CommonFunctions.divider(),

                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () {},
                                            icon: Icon(
                                              Icons.access_time,
                                              color: black,
                                              size: height * 0.035,
                                            ),
                                          ),
                                          Text(" 8:15 AM ----------"),
                                          IconButton(
                                            onPressed: () {},
                                            icon: Icon(
                                              Icons.bus_alert_rounded,
                                              color: black,
                                              size: height * 0.035,
                                            ),
                                          ),
                                          Text(" ---------- 8:30 AM"),
                                        ],


                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            height: 2,
                                            width: width*0.80,
                                            decoration: BoxDecoration(
                                                gradient: LinearGradient(colors: [white, teal, white])),
                                          ),
                                          CommonFunctions.blankSpace(
                                            height * 0.02,
                                            0,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () {},
                                            icon: Icon(
                                              Icons.access_time,
                                              color: black,
                                              size: height * 0.035,
                                            ),
                                          ),
                                          Text(" 4:20 PM ----------"),
                                          IconButton(
                                            onPressed: () {},
                                            icon: Icon(
                                              Icons.bus_alert_rounded,
                                              color: black,
                                              size: height * 0.035,
                                            ),
                                          ),
                                          Text(" ---------- 4:30 PM"),
                                        ],


                                      )


                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: -5,
                                child: IconButton(
                                  icon: Icon(Icons.info_outline, color: Colors.teal, size: 22),
                                  onPressed: () => showAddressDialog(context),
                                  tooltip: 'Share',
                                ),
                              ),

                            ],
                          ),
                        ),
                      );
                    }
                    ),
                  )

                  ,


                ],
              );
            }
          }),
    );
  }

  void showAddressDialog(BuildContext context) {
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
                Row(
                  children: [
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'School and Home address details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),  // Space after trip status before the divider

                CommonFunctions.divider(),

                SizedBox(height: 8),

                Row(
                  children: [
                    Icon(Icons.home, color: Colors.teal),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '123 Main St, Hometown, HT',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.school, color: Colors.teal),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '456 School St, Schooltown, ST',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.teal, // Background color
                  ),
                  child: Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteItem() {
    // Implement your item deletion logic here
    print('Item has been deleted');
    // Optionally, set state or inform the user
  }

  void showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)), // This makes the dialog rounded.
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // To make the dialog compact
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
    // Construct the message
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
}



class HomeScreenUserAddressBar extends StatelessWidget {
  const HomeScreenUserAddressBar({
    super.key,
    required this.height,
    required this.width,
  });

  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      height: height * 0.06,
      width: width,
      padding: EdgeInsets.symmetric(horizontal: width * 0.02),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: addressBarGradientColor,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child:
      Consumer<AddressProvider>(builder: (context, addressProvider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [

            Text(
              'Bus Schedule Details',
              style: textTheme.bodyMedium,
            )
          ],
        );
        /*if (addressProvider.fetchedCurrentSelectedAddress &&
            addressProvider.addressPresent) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [

              Text(
                'Bus Schedule Details',
                style: textTheme.bodyMedium,
              )
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.location_pin,
                color: black,
              ),
              CommonFunctions.blankSpace(
                0,
                width * 0.02,
              ),
              Text('Deliver to user - City, State', style: textTheme.bodySmall)
            ],
          );
        }*/
      }),
    );
  }

}

class HomePageAppBar extends StatelessWidget {
  const HomePageAppBar({
    super.key,
    required this.width,
    required this.height,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      // margin: EdgeInsets.symmetric(),

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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(
            onTap: () {
              /*Navigator.push(
                context,
                PageTransition(
                  child: const SearchedProductScreen(),
                  type: PageTransitionType.rightToLeft,
                ),
              );*/
            },
            child: Container(
              width: width * 0.81,
              height: height * 0.04,
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.04,
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image(
                    image: AssetImage('assets/images/busway_logo.png'),
                    height: height * 0.04,
                  )
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }


}
