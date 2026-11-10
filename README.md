# zrabi.by mobile

Flutter client for `https://zrabi.by/api/v1`.

## Stages

1. Auth: register / login / me / logout + Sanctum token
2. Orders: list (`scope` + pagination), detail, chat stub by `conversation_id`
3. Android first (iOS project included, not verified yet)

## Tooling (all on D:, not C:)

Everything lives under `D:\Web\zrabi.by\`:

| Path | What |
|------|------|
| `dev\flutter` | Flutter SDK |
| `Android\sdk` | Android SDK |
| `jdk-17` | JDK |
| `.gradle` | Gradle cache (`GRADLE_USER_HOME`) |
| `.android` | AVD / emulator data (`ANDROID_USER_HOME`) |
| `.pub-cache` | Dart packages (`PUB_CACHE`) |

After changing env vars: restart Cursor / terminals.

## Emulator

AVD: `zrabi_phone` (lives in `D:\Web\zrabi.by\.android`)

```bash
flutter emulators --launch zrabi_phone
flutter pub get
flutter run -d emulator-5554
```

Device auth smoke against production API:

```bash
flutter run -d emulator-5554 --dart-define=AUTH_SMOKE=true
```

Look for `AUTH_SMOKE_OK` in the Flutter console.

API base URL: `lib/config/api_config.dart`
