import 'package:flutter/cupertino.dart';

class ShowPercentageOfIO extends ChangeNotifier {
  bool _value = false;

  ShowPercentageOfIO(this._value);

  bool get value => _value;

  set value(newValue) {
    _value = newValue;
    notifyListeners();
  }
}
