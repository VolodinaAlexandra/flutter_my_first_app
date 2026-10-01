# Калькулятор индекса массы тела

Flutter-приложение с регистрацией и входом через Supabase Auth, расчётом ИМТ, рекомендациями и историей расчётов в `public.body_mass_index_calculations`. Android настроен на 10+, iOS deployment target установлен на 15.0.

## Подключение Supabase

В корне проекта находится локальный `supabase.local.json` с URL проекта и клиентским `anon` key. Файл исключён из Git. Для другого проекта создайте такой же JSON:

```json
{
  "SUPABASE_URL": "https://YOUR_PROJECT.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "YOUR_PUBLISHABLE_OR_ANON_KEY"
}
```

Используйте только publishable/anon key. `service_role` key в мобильное приложение добавлять нельзя.

1. В Supabase Dashboard откройте **SQL Editor** и выполните [supabase_policies.sql](supabase_policies.sql). Он включает RLS и разрешает пользователю читать и добавлять только свои записи. Если RLS уже настроен, проверьте существующие политики перед выполнением.
2. В **Authentication → Providers → Email** оставьте регистрацию по email включённой и отключите **Confirm Email**. Тогда после создания аккаунта Supabase сразу выдаст сессию и приложение откроет калькулятор без письма.
3. Запустите приложение:

```powershell
flutter pub get
flutter run --dart-define-from-file=supabase.local.json
```

Сборка APK:

```powershell
flutter build apk --dart-define-from-file=supabase.local.json
```

Рост можно ввести в сантиметрах (`185`) или метрах (`1,85`). Вес вводится целым числом килограммов, поскольку поля `height` и `weight` в существующей таблице имеют тип `bigint`. Если нужны дробные килограммы, понадобится изменить тип `weight` в Supabase и затем валидацию приложения.

ИМТ рассчитывается по формуле `вес (кг) / рост (м)²`. В карточках он показывается с точностью до двух знаков после запятой. История загружается по `user_id` в порядке от новых записей к старым.

## Установка на iPhone без Mac и App Store

В проекте есть [GitHub Actions workflow](.github/workflows/ios-unsigned-ipa.yml), который собирает нативное iOS-приложение на удалённом macOS и выдаёт неподписанный IPA. Для установки с Windows можно подписать его своей учётной записью Apple через [Sideloadly](https://sideloadly.io/). Физический iPhone нужен для завершающей проверки.

1. Проект уже загружен в [GitHub](https://github.com/VolodinaAlexandra/flutter_my_first_app). `supabase.local.json` исключён из Git; не добавляйте его принудительно. Workflow запускается из ветки `main`.
2. Секреты GitHub Actions `SUPABASE_URL` и `SUPABASE_PUBLISHABLE_KEY` уже настроены. При смене проекта Supabase обновите их в **Settings → Secrets and variables → Actions**. Нужен клиентский publishable/anon key, не `service_role`.
3. Откройте **Actions → Build iPhone test IPA → Run workflow**. Дождитесь успешного завершения, откройте запуск и скачайте артефакт `bmi-unsigned-ipa`. Распакуйте скачанный ZIP: внутри находится `bmi-unsigned.ipa`. IPA из первой успешной сборки также сохранён на этом компьютере в `build/ios/bmi-unsigned.ipa`.
4. Установите на Windows [Sideloadly](https://sideloadly.io/) и необходимые ему компоненты Apple по [официальной инструкции](https://sideloadly.io/faq). Подключите разблокированный iPhone по USB, выберите его и передайте `bmi-unsigned.ipa` в Sideloadly. Для подписи используйте свой Apple ID. Пароль Apple ID вводите только в Sideloadly; в GitHub или в проект его добавлять не нужно.
5. На iPhone разрешите профиль разработчика в **Настройки → Основные → VPN и управление устройством**. На iOS 16 и новее также включите **Режим разработчика** в **Настройки → Конфиденциальность и безопасность**, если устройство его запросит. Запустите приложение, зарегистрируйтесь, рассчитайте ИМТ и проверьте запись в истории.

Бесплатная подпись Apple действует примерно 7 дней: затем приложение нужно подписать и установить заново. Это тестовая установка без публикации в App Store. GitHub может расходовать минуты macOS runner для закрытого репозитория. Для работы истории предварительно выполните `supabase_policies.sql` в Supabase SQL Editor. На Windows нельзя проверить сборку Xcode или установку на физический iPhone; результат подтверждается после запуска workflow и проверки на устройстве.

Установленный Flutter официально поддерживает iOS 15 и новее. Поэтому цель iOS 14 из ТЗ заменена на 15.0; для iOS 14 потребуется более старая совместимая версия Flutter и отдельная проверка сборки.
