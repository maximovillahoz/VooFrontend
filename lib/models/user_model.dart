import 'package:flutter/material.dart';

class UserModel {
  final String id;
  final String name;
  final int age;
  final Color statusColor;

  const UserModel({
    required this.id,
    required this.name,
    required this.age,
    required this.statusColor,
  });
}