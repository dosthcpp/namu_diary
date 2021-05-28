import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int mainPageIdx = 4;
  int arItemIdx = 0;
  int arIconIdx = 0;
  bool initFlag = false;

  setMainPageIdx(_idx) {
    mainPageIdx = _idx;
    notifyListeners();
  }

  setARItemIdx(_idx) {
    arItemIdx = _idx;
    notifyListeners();
  }

  setIconIdx(_idx) {
    arIconIdx = 0;
    notifyListeners();
  }

  setInitFlag() {
    initFlag = true;
    notifyListeners();
  }

  increaseIndex() {
    if (arItemIdx == 0 && arIconIdx < 40 ||
        arItemIdx == 1 && arIconIdx < 275 ||
        arItemIdx == 2 && arIconIdx < 10 ||
        arItemIdx == 3 && arIconIdx < 20 ||
        arItemIdx == 4 && arIconIdx < 15 ||
        arItemIdx == 5 && arIconIdx < 15) {
      arIconIdx = arIconIdx + 5;
    }
    notifyListeners();
  }

  decreaseIndex() {
    if (arIconIdx > 0) {
      arIconIdx = arIconIdx - 5;
    }
    notifyListeners();
  }
}
