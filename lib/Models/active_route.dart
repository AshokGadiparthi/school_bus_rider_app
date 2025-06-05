class ActiveRoute {
  String? id;
  String? createdAt;
  String? driverId;
  List<AddressDetails>? endAddresses;
  String? routeId;
  String? routeName;
  String? schoolId;
  AddressDetails? startAddress;
  String? status;

  ActiveRoute({
    this.id,
    this.createdAt,
    this.driverId,
    this.endAddresses,
    this.routeId,
    this.routeName,
    this.schoolId,
    this.startAddress,
    this.status,
  });

  factory ActiveRoute.fromJson(Map<String, dynamic> json) {
    var endAddressesFromJson = json['end_addresses'] as List;
    List<AddressDetails> endAddressList = endAddressesFromJson.map((i) => AddressDetails.fromJson(Map<String, dynamic>.from(i))).toList();

    return ActiveRoute(
      id: json['id'],
      createdAt: json['created_at'],
      driverId: json['driver_id'],
      endAddresses: endAddressList,
      routeId: json['route_id'],
      routeName: json['route_name'],
      schoolId: json['school_id'],
      startAddress: AddressDetails.fromJson(Map<String, dynamic>.from(json['start_address'])),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt,
      'driver_id': driverId,
      'end_addresses': endAddresses?.map((e) => e.toJson()).toList(),
      'route_id': routeId,
      'route_name': routeName,
      'school_id': schoolId,
      'start_address': startAddress?.toJson(),
      'status': status,
    };
  }
}

class AddressDetails {
  String? address;
  double? latitude;
  double? longitude;

  AddressDetails({this.address, this.latitude, this.longitude});

  factory AddressDetails.fromJson(Map<String, dynamic> json) {
    return AddressDetails(
      address: json['address'],
      latitude: double.tryParse(json['latitude'].toString()),
      longitude: double.tryParse(json['longitude'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
    };
  }
}
