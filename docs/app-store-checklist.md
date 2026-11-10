# App Store: чеклист zrabi iOS

Bundle ID: `by.zrabi.zrabi`  
Отображаемое имя под иконкой: `zrabi`

## Уже в коде

- Privacy: доступ к фото (галерея для анкеты специалиста)
- OAuth callback scheme: `zrabi://`
- Push capability: `Runner/Runner.entitlements` (`aps-environment`)
- Background modes: `remote-notification`
- Export compliance: `ITSAppUsesNonExemptEncryption = false`
- Иконки / native splash: `flutter_launcher_icons` + `flutter_native_splash`
- Overflow карточек специалистов поправлен

## Нужно с вашей стороны

1. **Apple Developer Program** (~$99/год).
2. В Xcode → Signing: Team + Automatic для `by.zrabi.zrabi`.
3. **Firebase**
   - создать проект;
   - добавить iOS app с bundle `by.zrabi.zrabi`;
   - положить `ios/Runner/GoogleService-Info.plist`;
   - Android: `android/app/google-services.json`;
   - `dart run flutterfire_cli:flutterfire configure` (или руками заменить `lib/firebase_options.dart`);
   - в Apple Developer → Keys → APNs Auth Key → загрузить в Firebase Cloud Messaging;
   - на сервере заполнить `FCM_*` в `.env` (см. `docs/fcm-setup.md`);
   - для TestFlight/Store в entitlements сменить `aps-environment` на `production` (или через Xcode Release).
4. **App Store Connect**: скрины, описание, политика конфиденциальности URL, возрастной рейтинг.
5. Сборка: `flutter build ipa` или Archive в Xcode → TestFlight → Review.

## Перегенерация иконок/splash после смены логотипа

```bash
cd mobile
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Источник: `assets/zrabi_launcher_source.png`
