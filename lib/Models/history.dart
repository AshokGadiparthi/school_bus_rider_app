import 'package:firebase_database/firebase_database.dart';

class History {
  String? paymentMethod;
  String? createdAt;
  String? status;
  String? fares;
  String? dropOff;
  String? pickup;

  History({
    this.paymentMethod,
    this.createdAt,
    this.status,
    this.fares,
    this.dropOff,
    this.pickup,
  });

  History.fromSnapshot(DataSnapshot snapshot) {
    // Use a dynamic check and cast to handle potential type issues safely
    if (snapshot.value is Map<dynamic, dynamic>) {
      Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
      paymentMethod = data?["payment_method"];
      createdAt = data?["created_at"];
      status = data?["status"];
      fares = data?["fares"];
      dropOff = data?["dropoff_address"];
      pickup = data?["pickup_address"];
    }
  }
}