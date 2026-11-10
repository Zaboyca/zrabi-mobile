# Google Play: пакет zrabi

- Application ID: `by.zrabi.zrabi`
- Отображаемое имя: `zrabi`
- Текущая версия: `1.0.0+2` (versionCode `2`)
- Сборка: `flutter build appbundle --release`
- AAB: `mobile/build/app/outputs/bundle/release/app-release.aab`

## Подпись

Release AAB подписывается постоянным upload key из локального `android/key.properties`.
Сам keystore и пароль хранятся вне репозитория; сделайте резервную копию keystore в двух местах.
При включённой Play App Signing Google заменит финальную подпись своим ключом, но upload key терять нельзя.

## Перед первой загрузкой

1. Создать Google Play Console developer account и приложение `by.zrabi.zrabi`.
2. Загрузить AAB сначала во внутренний тест (Internal testing).
3. Указать политику конфиденциальности: `https://zrabi.by/privacy` (страница должна быть публично доступна при публикации).
4. Заполнить Data safety, возрастной рейтинг, категорию, контактный email и декларации Play Console.
5. Подготовить графику магазина: иконку 512×512, feature graphic 1024×500 и минимум два скриншота телефона.
6. После проверки на реальном Android-устройстве переносить релиз в закрытое или открытое тестирование.

## Примечания

- Push/FCM в текущей сборке намеренно выключен, пока в проекте стоят placeholder-значения Firebase.
- `versionCode` нужно увеличивать перед каждой новой загрузкой в Play Console.
