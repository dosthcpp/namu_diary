import 'package:flutter/material.dart';

class ARGardenProvider extends ChangeNotifier {
  String photonNickname = '';

  setPhotonNickname(String name) {
    photonNickname = name;
  }
}