import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../services/notification_service.dart';

class NotificationController extends ChangeNotifier {
  NotificationController(this._service);

  final NotificationService _service;

  int unreadCount = 0;
  bool loading = false;
  String? errorMessage;

  Future<void> refreshUnreadCount() async {
    try {
      unreadCount = await _service.unreadCount();
      errorMessage = null;
      notifyListeners();
    } on ApiException catch (e) {
      // After logout/delete the token is gone — don't surface 401 as an error.
      if (e.statusCode == 401) {
        unreadCount = 0;
        errorMessage = null;
      } else {
        errorMessage = e.displayMessage;
      }
      notifyListeners();
    } catch (_) {
      // Keep last known count on transient network errors.
    }
  }

  void setUnreadCount(int count) {
    if (unreadCount == count) {
      return;
    }
    unreadCount = count < 0 ? 0 : count;
    notifyListeners();
  }

  void decrementUnread([int by = 1]) {
    if (by <= 0 || unreadCount == 0) {
      return;
    }
    unreadCount = (unreadCount - by).clamp(0, unreadCount);
    notifyListeners();
  }

  void reset() {
    unreadCount = 0;
    errorMessage = null;
    loading = false;
    notifyListeners();
  }
}
