import 'package:flutter/cupertino.dart';

class PercentageOfIO extends ChangeNotifier {
  double _value = 0;

  PercentageOfIO(this._value);

  double get value => _value;

  set value(newValue) {
    if (newValue is int) {
      newValue = newValue.toDouble();
    }
    _value = newValue;
    notifyListeners();
  }
}
