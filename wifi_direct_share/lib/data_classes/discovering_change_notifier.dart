import 'package:flutter/cupertino.dart';

class DiscoveringChangeNotifier extends ChangeNotifier {
  bool _isdiscovering = false;

  bool get value => _isdiscovering;

  set value(bool value) {
    _isdiscovering = value;
    notifyListeners();
  }
}
