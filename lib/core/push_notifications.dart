import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import '../services/device_token_service.dart';
import '../ui/calendar/calendar_screen.dart';
import '../ui/orders/order_detail_screen.dart';

/// Day-before CRM reminders (FCM). No-ops until a real Firebase project is configured.
class PushNotifications {
  PushNotifications._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static String? _token;
  static DeviceTokenService? _tokens;
  static bool _ready = false;

  static bool get isPlaceholderProject =>
      DefaultFirebaseOptions.android.projectId == 'zrabi-placeholder';

  static Future<void> bootstrap(DeviceTokenService tokens) async {
    _tokens = tokens;
    if (kIsWeb || isPlaceholderProject) {
      return;
    }

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      FirebaseMessaging.onMessageOpenedApp.listen(_openFromMessage);
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        _openFromMessage(initial);
      }

      messaging.onTokenRefresh.listen((token) async {
        _token = token;
        await _register(token);
      });

      _ready = true;
    } catch (error, stack) {
      debugPrint('Push bootstrap skipped: $error\n$stack');
      _ready = false;
    }
  }

  static Future<void> syncForSignedInUser() async {
    if (!_ready || _tokens == null || isPlaceholderProject) {
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        return;
      }
      _token = token;
      await _register(token);
    } catch (error) {
      debugPrint('Push token sync failed: $error');
    }
  }

  static Future<void> clearForSignedOutUser() async {
    final token = _token;
    final tokens = _tokens;
    if (token == null || tokens == null) {
      return;
    }
    try {
      await tokens.unregister(token);
    } catch (_) {}
    _token = null;
  }

  static Future<void> _register(String token) async {
    final tokens = _tokens;
    if (tokens == null) return;
    await tokens.register(
      token,
      platform: Platform.isIOS ? 'ios' : 'android',
    );
  }

  static void _openFromMessage(RemoteMessage message) {
    final data = message.data;
    final nav = navigatorKey.currentState;
    if (nav == null) return;

    final orderId = int.tryParse('${data['order_id'] ?? ''}');
    if (orderId != null) {
      nav.push(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
      );
      return;
    }

    nav.push(
      MaterialPageRoute(builder: (_) => const CalendarScreen()),
    );
  }
}
