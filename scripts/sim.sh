#!/bin/sh
# Собрать, поставить и запустить пробное приложение в симуляторе tvOS; журнал — в файл.
#   scripts/sim.sh <файл журнала> [аргументы сценария…]
#   scripts/sim.sh /tmp/run.log -autoplay media:KcXy8AGnf9:mp4 -seek-to 12
# Симулятор — SIM_UDID (по умолчанию первый «Apple TV 4K (4th generation)»). Запуск блокирует, пока
# приложение живо: вызывать в фоне и завершать `xcrun simctl terminate booted com.dodocast.tv.spike`.
set -eu
cd "$(dirname "$0")/.."
LOG=$1; shift
UDID=${SIM_UDID:-$(xcrun simctl list devices available | grep 'Apple TV 4K (4th generation) (' | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')}
xcodegen generate --quiet
xcodebuild -project DodocastTV.xcodeproj -scheme DodocastTV -destination "platform=tvOS Simulator,id=$UDID" \
  -derivedDataPath build -quiet build
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl install "$UDID" build/Build/Products/Debug-appletvsimulator/DodocastTV.app
exec xcrun simctl launch --console-pty --terminate-running-process "$UDID" com.dodocast.tv.spike "$@" >"$LOG" 2>&1
