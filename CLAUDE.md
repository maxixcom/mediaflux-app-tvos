# CLAUDE.md

Приложение dodocast для Apple TV — клиент бэкенда `mediaflux-app-api` (MF-86, этап Э3 — MF-90). Устройство и решения —
`mediaflux-docs/docs/APPS.md` (ветка `feature/mf-86-apps`): §4 экраны, §5 вход, §5.1 выбор сервера, §6 устройства,
§7 позиция, §8 воспроизведение, §10 ограничения GraphQL, §12 платформы.

## Цели (`project.yml`, XcodeGen; `.xcodeproj` в git не лежит)

- **`DodocastTV`** — клиент: SwiftUI, Swift 6, tvOS 18+, bundle `com.dodocast.tv`, Apollo iOS 2.5.
- **`DodocastTVTests`** — юнит-тесты без сети.
- **`DodocastTVUITests`** — сценарии на симуляторе с пультом (`XCUIRemote`): фокус, переходы, «Назад», снимки экрана.
  Своя схема `DodocastTVScenarios`: нужны вход на симуляторе и живой сервер, в обычный прогон тестов не входят.
- **`Spike`** — пробное приложение Э0 (MF-87, MF-97) без изменений, для замеров плеера (`scripts/tv-matrix.sh`).

## Устройство клиента

```
DodocastTV/
  App/        точка входа, AppModel — экран по состоянию: сервер → вход → устройство → главный
  Brand/      имя, логотип, цвета, список серверов, иконка и полка — бренд ТОЛЬКО здесь
  Core/       Server (сведения о сервере, версия), Auth (вход по коду, токены, Keychain), API (Apollo + ошибки),
              Catalog (модели экранов), Player (главы, «Инфо», playbackStart), Progress (позиция и досылка), Images
  Features/   Server, Login, Devices, Home, Catalog (вкладки, ленты, карточки), Player, Search, Settings
  GraphQL/    Operations/*.graphql (пишем руками), Generated/ (кодогенерация, в git), operation-manifest.json
  Resources/  Localizable.xcstrings (ru — исходный, en — перевод)
```

## Правила, которые легко нарушить

- **Бренд — только в `Brand/`.** Код имени продукта не знает. Второй продукт на платформе — вторая цель со своим
  `Brand/` (решение 18.11.2026). Иконку и полку рисует `scripts/brand-icon.swift` из логотипа брендбука.
- **Цвета.** Маджента бренда в интерфейсе не используется (на телевизоре кричит, решение владельца): полоса
  просмотренного — белая (`Brand.progressFill`), акцент приложения (`AccentColor`) — системный красный, как «В эфире».
  Плашку «Трансляция» в плеере рисует AVKit своим цветом — она не перекрашивается.
- **Новая GraphQL-операция:** `.graphql` в `GraphQL/Operations` → `scripts/codegen.sh` → сгенерированный код и
  манифест в git → копия манифеста в `mediaflux-app-api/src/main/resources/operations/tvos-<версия>.json`. Сервер в
  режиме `registered` (прод) принимает только операции из манифестов; на tst пока `open`.
- **Apollo 2 шлёт `Accept: application/graphql-response+json`**, и по GraphQL over HTTP ответ без `data` (отказ
  привратника: `RATE_LIMITED`, `OPERATION_NOT_REGISTERED`) приходит **400**. `AuthInterceptor` отдаёт 4xx с `errors`
  разбору Apollo — иначе код ошибки теряется и человек видит «сервер недоступен».
- **Регистрацию устройства на каждом старте не звать:** у неё лимит 5 в час на пользователя. Старт с сохранённым
  входом — `me`: устройство подключено и версия та же — сразу главный экран (`AppModel.resumeSession`).
- **Ошибки — `AppError(code, params)`**: фраза по коду в `AppError.message`, текст — в `Localizable.xcstrings`.
  Ключ каталога — РОВНО строка из `String(localized:)` / `Text(...)` с `%@` / `%lld` на месте подстановок; множественное
  число — вариациями `plural` (см. `%lld материалов`).
- **Позиция (§7):** раз в 15 с во время игры, `final` на паузе, конце, выходе и уходе в фон; у канала позиции нет;
  недосланное — `ProgressOutbox` (переживает перезапуск), досылается на старте, после удачного отчёта, перед выходом
  и сменой сервера.
- **Keychain:** `installation-id` не стирается никогда (с ним повторный вход не тратит слот устройства); refresh-токен
  — у каждого сервера свой (`refresh:<host:port>`).
- **Скаляр `Long` — `Int`:** файл `Generated/Schema/CustomScalars/Long.swift` свой, генератор его не перезаписывает.
- **Навигация — боковое меню, как у приложения Apple TV** (tvOS 18+, решение 19.11.2026): `TabView` с `Tab` и
  `.tabViewStyle(.sidebarAdaptable)`, поиск — первым пунктом с `role: .search`. Меню сворачивается в плашку раздела,
  карточки — на весь экран; «Назад» — на шаг, с корня раздела — меню, из меню — из приложения. Повторный выбор раздела
  в меню SwiftUI сообщает привязкой выбора — по нему раздел возвращается к началу (`MainView.tabSelection`).
  - Прежняя полоса вкладок (tvOS 17, `.tabItem`) не годилась: над карточкой висела полоса, Select на вкладке уводил
    фокус в содержимое (документация `UITabBarController`, «Differences between iOS and tvOS»), повторного выбора
    SwiftUI не сообщал — владелец «застревал» в карточке поиска.
  - Шапка меню (`tabViewSidebarHeader`) — только с tvOS 27, на 18–26 меню без неё.
- **Свежесть экранов — по изменению данных или видимости, не «при появлении».** С боковым меню (`.sidebarAdaptable`)
  при возврате из стека раздела `onAppear` у экрана под карточкой не приходит (MF-114, MF-116; с полосой вкладок
  приходил). Поэтому:
  - своё изменение состояния зрителя (избранное, «просмотрено», закрытие плеера) — `app.viewerChanged()`; экраны с
    карточками перечитываются по `.task(id: app.viewerRevision)` (`Loadable(reloadOnViewerChange:)`, сетка библиотеки
    `reloadLoaded`, результаты поиска);
  - ряд «Недавние поиски» — по видимости: `.task(id:)` от «строка пуста и стек раздела пуст», чтение ждёт своей записи.
- **Сценарии, меняющие данные аккаунта на tst** (избранное, позиция, история): `continueAfterFailure = false`, нужную
  карточку проверять по `media-detail-title` на её экране (главная остаётся в дереве под карточкой), отметки
  возвращать как было. Состояние карточки в ленте — `accessibilityValue` (`В избранном`, `Просмотрено`).
- **Правку интерфейса сначала проверяю сценарием на симуляторе** (`scripts/ui-check.sh`, снимки смотрю), потом —
  телевизор. Жалобу на поведение — сначала воспроизвести сценарием по пути владельца, потом менять.

## Сборка и запуск

```bash
xcodegen generate                         # проект из project.yml
scripts/codegen.sh                        # после правки .graphql или схемы app-api
scripts/sim.sh /tmp/run.log -server https://app.tst.media-flux.ru     # симулятор, клиент
TARGET=Spike scripts/sim.sh /tmp/run.log -autoplay media:KcXy8AGnf9:mp4
TV_DEVICE=<udid> DEVELOPMENT_TEAM=<team> scripts/device.sh /tmp/tv.log  # живой Apple TV
scripts/ui-check.sh /tmp/shots SearchScenarioTests     # сценарии с пультом на загруженном симуляторе, снимки в каталог
xcodebuild test -project DodocastTV.xcodeproj -scheme DodocastTV \
  -destination "platform=tvOS Simulator,name=Apple TV 4K (4th generation)" \
  -clonedSourcePackagesDirPath build/SourcePackages
```

- **Аргументы запуска для проверок без пульта:** `-server <адрес>`, `-tab home | search | library | settings`,
  `-search <текст>`, `-route media:<id> | library:<id> | playlist:<id>`, `-play media:<id>[:beginning] | channel:<id>`. Журнал — строки `[DCTV]`; токены, коды входа и текст поиска в него
  не пишутся.
- **Локальная среда — только симулятор:** сведения о сервере отдают адреса `localhost` (Keycloak, GraphQL), на живом
  телевизоре `localhost` — он сам. Адрес Mac в сети (`http://192.168.x.x:17091`) в симуляторе работает так же.
- **Симулятор SAMPLE-AES не играет** (`-12155`) — шифрованное проверять на телевизоре.

## Грабли окружения

- **SPM не скачивает `apollo-ios`:** репозиторий большой, `fetch` рвётся («unexpected disconnect while reading
  sideband packet»), Xcode висит на «Fetching … (cached)». Докачать кэш SPM руками и повторить разрешение:
  `git -C ~/Library/Caches/org.swift.swiftpm/repositories/apollo-ios-* -c http.version=HTTP/1.1 fetch --tags origin`.
  Из песочницы Claude Code — только вне её (SPM пишет кэш в `~/Library`).
- **Симулятор вдруг не играет ничего: «Не удалось воспроизвести», в журнале `-12746` «Could not create render
  pipeline» от `FAQRP`** — сломался вывод звука симулятора (бывает после смены звукового устройства Mac). Лечится
  перезагрузкой симулятора (`simctl shutdown` / `boot`), вход в Keychain сохраняется (20.11.2026).
- **Симулятор в Xcode 27 — приложение Device Hub.** Ввод с клавиатуры Mac: Device → Keyboard → **Keyboard Capture
  (⌘K)**, повторное ⌘K отпускает. Выбор буквы на экранной клавиатуре кнопкой «◎» Device Hub не срабатывает.
- **Xcode при сборке переписывает `Localizable.xcstrings`** — свой формат (` : `) и отметки `stale`. Если ключи и
  переводы не менялись (сверка без `extractionState`), дифф откатить перед коммитом, а не тащить в историю.
- **CLI кодогенерации** — `apollo-ios-cli` той же версии, что пакет (2.5.0): `scripts/codegen.sh` скачивает его из
  релиза apollographql/apollo-ios в `.build/` (вне git).
