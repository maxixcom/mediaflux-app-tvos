#!/bin/sh
# Сценарии на симуляторе (цель DodocastTVUITests, схема DodocastTVScenarios): пульт XCUIRemote, снимки экрана.
#   scripts/ui-check.sh <каталог снимков> [Класс/тест]
#   scripts/ui-check.sh /tmp/shots SearchScenarioTests/testBackFromCardOpenedInSearch
# Нужен вход на симуляторе (сервер и сессия — в его Keychain) и живой сервер — поэтому в обычный прогон тестов
# не входят. Симулятор — SIM_DEVICE (UDID), по умолчанию загруженный Apple TV. Переменные TEST_RUNNER_* уходят в тест
# без префикса (SCENARIO_MEDIA — материал для поиска).
set -eu
cd "$(dirname "$0")/.."
OUT=$1; shift
mkdir -p "$OUT"
UDID=${SIM_DEVICE:-$(xcrun simctl list devices booted | grep "Apple TV" | grep -oE '[0-9A-F]{8}(-[0-9A-F]{4}){3}-[0-9A-F]{12}' | head -1)}
: "${UDID:?нет загруженного симулятора Apple TV — запустите его или задайте SIM_DEVICE}"
xcodegen generate --quiet
TEST_RUNNER_SCENARIO_SHOTS="$OUT" xcodebuild test -project DodocastTV.xcodeproj -scheme DodocastTVScenarios \
  -destination "platform=tvOS Simulator,id=$UDID" -derivedDataPath build -clonedSourcePackagesDirPath build/SourcePackages \
  ${1:+-only-testing:DodocastTVUITests/$1} -quiet
