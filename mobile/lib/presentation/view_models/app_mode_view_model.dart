import 'package:flutter/material.dart';

enum AppUserType { shopkeeper, customer }
typedef UserType = AppUserType;

class AppModeViewModel extends ChangeNotifier {
  AppUserType _userType = AppUserType.shopkeeper;
  bool _isDarkMode = false;
  bool _isOnline = true;
  int _offlineQueuedCount = 0;
  Locale _locale = const Locale('bn'); // Default to Bangla with instant toggle to English

  AppUserType get userType => _userType;
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  bool get isOnline => _isOnline;
  int get offlineQueuedCount => _offlineQueuedCount;
  Locale get locale => _locale;
  bool get isBangla => _locale.languageCode == 'bn';

  bool get isShopkeeper => _userType == AppUserType.shopkeeper;
  bool get isCustomer => _userType == AppUserType.customer;

  void setUserType(AppUserType type) {
    _userType = type;
    notifyListeners();
  }

  void toggleUserType() {
    _userType = (_userType == AppUserType.shopkeeper) ? AppUserType.customer : AppUserType.shopkeeper;
    notifyListeners();
  }

  void setLocale(Locale loc) {
    _locale = loc;
    notifyListeners();
  }

  void toggleLanguage() {
    _locale = _locale.languageCode == 'bn' ? const Locale('en') : const Locale('bn');
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void toggleOnline() {
    _isOnline = !_isOnline;
    if (_isOnline) {
      _offlineQueuedCount = 0;
    }
    notifyListeners();
  }

  void incrementOfflineQueue() {
    _offlineQueuedCount++;
    notifyListeners();
  }
}
