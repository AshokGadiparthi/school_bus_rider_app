import 'package:flutter/material.dart';
import 'package:riders_app/utils/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<String> messages = [
    "Welcome to the BusWay app! We're glad to have you.",
    "Your child has safely boarded the bus. Have a great day!",
    "Reminder: Tomorrow is a holiday. No bus service will be available.",
    "Update: The bus is running 10 minutes late due to traffic.",
    "Update: The bus is running 10 minutes late due to traffic.",
    "Update: The bus is running 10 minutes late due to traffic.",
    "Update: The bus is running 10 minutes late due to traffic.",
    "Update: The bus is running 10 minutes late due to traffic.",
    "Update: The bus is running 10 minutes late due to traffic.",
    "Update: The bus is running 10 minutes late due to traffic.",
    "Update: The bus is running 10 minutes late due to traffic.",
    "This is a very long message to demonstrate the truncation and popup feature. This message should be truncated when displayed in the grid and a full version should be shown in the popup dialog.",
  ];

  void showFullMessage(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Full Message'),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
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
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          physics: ClampingScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            crossAxisSpacing: 12.0,
            mainAxisSpacing: 12.0,
            childAspectRatio: 4, // Adjusted to make the height similar to home screen
          ),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            String message = messages[index];
            return GestureDetector(
              onTap: () => showFullMessage(message),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.length > 100
                          ? "${message.substring(0, 97)}..."
                          : message,
                      style: textTheme.bodyText1!.copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}