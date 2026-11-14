#!/bin/sh
# Собрать, поставить и запустить пробное приложение на живом Apple TV; журнал — в файл.
#   scripts/device.sh <файл журнала> [аргументы сценария…]
#   scripts/device.sh /tmp/tv.log -autoplay media:KcXy8AGnf9:mp4 -seek-to 12
# Устройство — TV_DEVICE (UDID или имя), команда подписи — DEVELOPMENT_TEAM (бесплатная Personal Team
# годится: подпись живёт 7 дней). Запуск блокирует, пока приложение живо: вызывать в фоне.
set -eu
cd "$(dirname "$0")/.."
LOG=$1; shift
: "${TV_DEVICE:?укажите TV_DEVICE — UDID из xcrun devicectl list devices}"
: "${DEVELOPMENT_TEAM:?укажите DEVELOPMENT_TEAM — id команды Apple}"
xcodegen generate --quiet
xcodebuild -project DodocastTV.xcodeproj -scheme DodocastTV -destination "platform=tvOS,id=$TV_DEVICE" \
  -derivedDataPath build -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" -quiet build
xcrun devicectl device install app --device "$TV_DEVICE" build/Build/Products/Debug-appletvos/DodocastTV.app
exec xcrun devicectl device process launch --device "$TV_DEVICE" --console --terminate-existing \
  com.dodocast.tv.spike -- "$@" >"$LOG" 2>&1
