import 'package:flutter/material.dart';
import 'package:riders_app/Models/product_model.dart';
import 'package:riders_app/controller/services/users_product_services/users_product_services.dart';

class DealOfTheDayProvider extends ChangeNotifier {
  List<ProductModel> deals = [];
  bool dealsFetched = false;

  fetchTodaysDeal() async {
    deals = [];
    deals = await UsersProductService.featchDealOfTheDay();
    dealsFetched = true;
    notifyListeners();
  }
}
