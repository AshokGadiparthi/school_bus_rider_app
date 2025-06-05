class Address
{
  String? placeFormattedAddress;
  String? placeName;
  String? placeId;
  double? latitude;
  double? longitude;
  String? studentId;


  Address({this.placeFormattedAddress, this.placeName, this.placeId, this.latitude, this.longitude, this.studentId});

  // Named constructor for an empty address
  Address.empty()
      : placeName = '',
        latitude = 0.0,
        longitude = 0.0,
        studentId = null;

}