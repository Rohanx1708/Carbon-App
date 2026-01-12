import 'package:flutter/foundation.dart';

class MainNavState extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void setIndex(int value) {
    if (value == _index) return;
    _index = value;
    notifyListeners();
  }
}

final MainNavState mainNavState = MainNavState();


