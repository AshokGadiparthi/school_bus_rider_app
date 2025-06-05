import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Users
{
  String? id;
  String? email;
  String? name;
  String? phone;

  Users({this.id, this.email, this.name, this.phone,});

  Users.fromData(String? snapshotId, Map<String, dynamic> map) {
    id = snapshotId;  // Assigning the snapshot key as ID
    email = map['email'];
    name = map['name'];
    phone = map['phone'];
  }
}