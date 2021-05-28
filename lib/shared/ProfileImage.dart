import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

final _storage = FirebaseStorage.instance;

Widget profileImage(String userName, double radius) {
  return FutureBuilder(
    future: _storage.ref('uploads/userProfile/$userName').getDownloadURL(),
    builder: (context, image) {
      if (!image.hasData) {
        return Image.asset(
          'assets/user.png',
          width: radius,
        );
      }
      return Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            fit: BoxFit.cover,
            image: NetworkImage(image.data),
          ),
        ),
      );
    },
  );
}
