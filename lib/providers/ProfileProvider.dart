import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';

class ProfileProvider extends ChangeNotifier {
  Map<String, String> profiles = {};

  Future init() async {
    // get profile
    final ref = await FirebaseFirestore.instance.collection('/userList').get();
    for(var i = 0 ; i < ref.docs.length; ++i) {
      final _ref = FirebaseStorage.instance
          .ref()
          .child('uploads/userProfile/${ref.docs[i].get('username')}');
      try {
        final profileUrl = await _ref.getDownloadURL();
        profiles[ref.docs[i].get('username')] = profileUrl;
      } catch(e) {
        continue;
      }
    }
    notifyListeners();
  }
}