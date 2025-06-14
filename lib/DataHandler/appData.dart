import 'package:flutter/cupertino.dart';
import 'package:riders_app/Models/address.dart';
import 'package:riders_app/Models/history.dart';

class AppData extends ChangeNotifier {
  Address? pickUpLocation, dropOffLocation;
  List<Address> dropOffAddresses = [];

  String earnings = "0";
  int countTrips = 0;
  List<String> tripHistoryKeys = [];
  List<History> tripHistoryDataList = [];

  void updateDropOffLocationAddresses(List<Address> dropOffAddresses) { // Updated to handle multiple addresses
    this.dropOffAddresses = dropOffAddresses;
    notifyListeners();
  }


  void updatePickUpLocationAddress(Address pickUpAddress)
  {
    pickUpLocation = pickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Address dropOffAddress)
  {
    dropOffLocation = dropOffAddress;
    notifyListeners();
  }

  //history
  void updateEarnings(String updatedEarnings)
  {
    earnings = updatedEarnings;
    notifyListeners();
  }

  void updateTripsCounter(int tripCounter)
  {
    countTrips = tripCounter;
    notifyListeners();
  }

  void updateTripKeys(List<String> newKeys)
  {
    tripHistoryKeys = newKeys;
    notifyListeners();
  }

  void updateTripHistoryData(History eachHistory)
  {
    tripHistoryDataList.add(eachHistory);
    notifyListeners();
  }


}