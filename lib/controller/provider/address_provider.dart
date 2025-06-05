import 'package:flutter/material.dart';
import 'package:riders_app/Models/address_model.dart';
import 'package:riders_app/services/user_data_crud_services/user_data_CRUD_services.dart';


class AddressProvider extends ChangeNotifier {
  List<AddressModel> allAdressModel = [];
  AddressModel currentSelectedAddress = AddressModel();
  bool fetchedCurrentSelectedAddress = false;
  bool fetchedAllAddress = false;
  bool addressPresent = false;

  getAllAddress() async {
    allAdressModel = await UserDataCRUD.getAllAddress();
    fetchedAllAddress = true;
    notifyListeners();
  }

  getCurrentSelectedAddress() async {
    currentSelectedAddress = await UserDataCRUD.getCurrentSelectedAddress();
    addressPresent = await UserDataCRUD.checkUsersAddress();
    fetchedCurrentSelectedAddress = true;
    
    notifyListeners();
  }
}
