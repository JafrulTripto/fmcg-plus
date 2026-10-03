import 'package:flutter/foundation.dart';

class NotificationViewModel extends ChangeNotifier {
  int _unreadGroceryCount = 0;

  int get unreadGroceryCount => _unreadGroceryCount;
  bool get hasUnread => _unreadGroceryCount > 0;

  void incrementUnread() {
    _unreadGroceryCount++;
    notifyListeners();
  }

  void markAllRead() {
    _unreadGroceryCount = 0;
    notifyListeners();
  }
}
