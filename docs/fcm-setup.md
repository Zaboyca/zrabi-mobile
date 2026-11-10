# FCM: напоминания CRM за сутки

Пуши уходят только в приложение и только если пользователь **исполнитель** (своя запись с ролью «я делаю» или заказ zrabi, где он выбран специалистом).

Пока `projectId == zrabi-placeholder` в `lib/firebase_options.dart`, регистрация токена **намеренно выключена**.

## Сервер

В `.env` на zrabi.by:

```
FCM_PROJECT_ID=...
FCM_CLIENT_EMAIL=...@....iam.gserviceaccount.com
FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

Ключ — из Firebase service account (Cloud Messaging).

Scheduler: контейнер `zrabi_scheduler` (`calendar:send-day-before-reminders`).

## Приложение

### Общее

1. Создай Firebase-проект.
2. Добавь Android `by.zrabi.zrabi` и iOS `by.zrabi.zrabi`.
3. В `mobile/`: `dart run flutterfire_cli:flutterfire configure`  
   или вручную замени:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - `lib/firebase_options.dart`
4. Добавь `GoogleService-Info.plist` в target Runner в Xcode (Copy Bundle Resources), если файл кладёшь руками.

### iOS (APNs)

1. [developer.apple.com](https://developer.apple.com) → Certificates, Identifiers & Profiles → Keys → создать **Apple Push Notifications service (APNs)** key.
2. В Firebase → Project settings → Cloud Messaging → Apple app configuration → загрузить `.p8`, Key ID, Team ID.
3. Capability Push Notifications уже заложена в `Runner/Runner.entitlements`.
4. Для релиза App Store: в Release entitlements обычно `aps-environment = production` (Xcode часто переключает сам при Archive с distribution profile).

### Проверка

1. Собери на реальный iPhone / TestFlight.
2. Войди исполнителем, дождись регистрации токена (см. логи / таблица `device_tokens`).
3. Создай событие CRM на завтра → дождись scheduler.
