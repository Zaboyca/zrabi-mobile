import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/api_client.dart';
import 'core/push_notifications.dart';
import 'core/token_storage.dart';
import 'services/auth_service.dart';
import 'services/calendar_service.dart';
import 'services/chat_service.dart';
import 'services/device_token_service.dart';
import 'services/marketplace_service.dart';
import 'services/notification_service.dart';
import 'services/order_service.dart';
import 'services/pages_service.dart';
import 'services/specialist_cabinet_service.dart';
import 'state/auth_controller.dart';
import 'state/notification_controller.dart';
import 'tooling/auth_smoke_runner.dart';
import 'tooling/auto_login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final authService = AuthService(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );
  final orderService = OrderService(apiClient);
  final calendarService = CalendarService(apiClient);
  final chatService = ChatService(apiClient);
  final marketplaceService = MarketplaceService(apiClient);
  final pagesService = PagesService(apiClient);
  final specialistCabinetService = SpecialistCabinetService(apiClient);
  final notificationService = NotificationService(apiClient);
  final deviceTokenService = DeviceTokenService(apiClient);
  final notificationController = NotificationController(notificationService);
  await PushNotifications.bootstrap(deviceTokenService);
  final authController = AuthController(
    authService,
    onAuthenticated: () async {
      await notificationController.refreshUnreadCount();
      await PushNotifications.syncForSignedInUser();
    },
    onLoggedOut: () {
      notificationController.reset();
      PushNotifications.clearForSignedOutUser();
    },
  );

  // Optional device smoke: flutter run --dart-define=AUTH_SMOKE=true
  await runAuthSmokeIfEnabled(authService);
  // Optional: --dart-define=AUTO_LOGIN_EMAIL=... --dart-define=AUTO_LOGIN_PASSWORD=...
  await runAutoLoginIfEnabled(authService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authController),
        ChangeNotifierProvider.value(value: notificationController),
        Provider.value(value: orderService),
        Provider.value(value: calendarService),
        Provider.value(value: chatService),
        Provider.value(value: marketplaceService),
        Provider.value(value: pagesService),
        Provider.value(value: specialistCabinetService),
        Provider.value(value: notificationService),
        Provider.value(value: apiClient),
      ],
      child: const ZrabiApp(),
    ),
  );

  await authController.bootstrap();
}
