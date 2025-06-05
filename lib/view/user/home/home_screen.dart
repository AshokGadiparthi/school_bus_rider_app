import 'dart:developer';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:riders_app/DataHandler/appData.dart';
import 'package:riders_app/Models/address.dart';
import 'package:riders_app/Models/address_model.dart';
import 'package:riders_app/constants/common_functions.dart';
import 'package:riders_app/controller/provider/address_provider.dart';
import 'package:riders_app/controller/provider/deal_of_the_day_provider/deal_of_the_provider.dart';
import 'package:riders_app/map/map.dart';
import 'package:riders_app/student/add_student.dart';
import 'package:riders_app/student/student_details.dart';
import 'package:riders_app/utils/colors.dart';
import 'package:riders_app/view/user/home/parent_students_home.dart';
import 'package:riders_app/view/user/schedule/schedule_screen.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CarouselController todaysDealsCarouselController = CarouselController();

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
            ParentStudentsScreenWidget(
                todaysDealsCarouselController: todaysDealsCarouselController),
          ],
        ),
      ),
    );
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
      child: Consumer<AddressProvider>(builder: (context, addressProvider, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              'Dashboard - Parent\'s App',
              style: textTheme.bodyMedium,
            )
          ],
        );
        /*if (addressProvider.fetchedCurrentSelectedAddress &&
            addressProvider.addressPresent) {
          AddressModel selectedAddress = addressProvider.currentSelectedAddress;
          return Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Dashboard - Parent\'s App',
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
              CommonFunctions.blankSpace(0, width * 0.02),
              Text('Deliver to user - City, State', style: textTheme.bodySmall)
            ],
          );
        }*/
      }),
    );
  }
}