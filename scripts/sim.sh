#!/bin/sh
# Собрать, поставить и запустить приложение в симуляторе tvOS; журнал — в файл.
#   scripts/sim.sh <файл журнала> [аргументы запуска…]
#   scripts/sim.sh /tmp/run.log -server http://localhost:17091          # клиент на локальной среде
#   TARGET=Spike scripts/sim.sh /tmp/run.log -autoplay media:KcXy8AGnf9:mp4 -seek-to 12
# Цель — TARGET: DodocastTV (клиент, по умолчанию) или Spike (пробное Э0). Симулятор — SIM_UDID (по умолчанию первый
# «Apple TV 4K (4th generation)»). Запуск блокирует, пока приложение живо: вызывать в фоне.
set -eu
cd "$(dirname "$0")/.."
LOG=$1; shift
TARGET=${TARGET:-DodocastTV}
case $TARGET in
  DodocastTV) BUNDLE=com.dodocast.tv ;;
  Spike) BUNDLE=com.dodocast.tv.spike ;;
  *) echo "TARGET: DodocastTV или Spike"; exit 1 ;;
esac
UDID=${SIM_UDID:-$(xcrun simctl list devices available | grep 'Apple TV 4K (4th generation) (' | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')}
xcodegen generate --quiet
xcodebuild -project DodocastTV.xcodeproj -scheme "$TARGET" -destination "platform=tvOS Simulator,id=$UDID" \
  -derivedDataPath build -clonedSourcePackagesDirPath build/SourcePackages -quiet build
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null
xcrun simctl install "$UDID" "build/Build/Products/Debug-appletvsimulator/$TARGET.app"
exec xcrun simctl launch --console-pty --terminate-running-process "$UDID" "$BUNDLE" "$@" >"$LOG" 2>&1
