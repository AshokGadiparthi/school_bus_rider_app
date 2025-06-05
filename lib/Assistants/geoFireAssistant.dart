import 'package:riders_app/Models/nearbyAvailableDrivers.dart';

class GeoFireAssistant
{
  static List<NearbyAvailableDrivers> nearByAvailableDriversList = [];

  static NearbyAvailableDrivers? availableDriver;

  static void setDriverLocation(NearbyAvailableDrivers driver) {
    availableDriver = driver;
  }

  static void removeDriverFromList(String key)
  {
    int index = nearByAvailableDriversList.indexWhere((element) => element.key == key);
    nearByAvailableDriversList.removeAt(index);
  }

  static void updateAvailableDriverLocation(NearbyAvailableDrivers driver) {
    if (availableDriver != null && availableDriver!.key == driver.key) {
      availableDriver!.latitude = driver.latitude;
      availableDriver!.longitude = driver.longitude;
    } else {
      // Optionally, you can set the availableDriver if it's not the same driver
      availableDriver = driver;
    }
  }

  static void updateDriverNearbyLocation(NearbyAvailableDrivers driver)
  {
    int index = nearByAvailableDriversList.indexWhere((element) => element.key == driver.key);

    nearByAvailableDriversList[index].latitude = driver.latitude;
    nearByAvailableDriversList[index].longitude = driver.longitude;
  }
}