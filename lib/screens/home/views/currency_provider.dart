import 'package:flutter/material.dart';

class CurrencyProvider extends ChangeNotifier {
  String _selectedCurrency = 'INR';
  double _conversionRate = 1.0; // Default: INR to INR

  String get selectedCurrency => _selectedCurrency;
  double get conversionRate => _conversionRate;

  void setCurrency(String currency, double rate) {
    _selectedCurrency = currency;
    _conversionRate = rate;
    notifyListeners();
  }
}