#!/bin/sh
# Прогон таблицы проверок Э0 на живом Apple TV (пробное приложение уже поставлено: TARGET=Spike scripts/device.sh).
#   TV_DEVICE=<udid> scripts/tv-matrix.sh <папка журналов>
# Каждый сценарий — отдельный запуск с консолью; ждём 25 с игры или отказа, затем следующий.
set -u
DIR=$1
run() {
  name=$1; shift
  log="$DIR/tv-$name.log"
  rm -f "$log"
  xcrun devicectl device process launch --device "$TV_DEVICE" --console --terminate-existing \
    com.dodocast.tv.spike -- "$@" >"$log" 2>&1 &
  pid=$!
  n=0
  until grep -q "+  2[0-9]с\|ОТКАЗ\|не доиграл" "$log" 2>/dev/null || [ $n -ge 90 ]; do sleep 1; n=$((n + 1)); done
  kill $pid 2>/dev/null
  echo "=== $name"
  grep '\[MF87\]' "$log" | grep -v 'старт приложения\|автозапуск\|EvaluatingBuffering\|состояние: пауза$' | cut -c8- | head -12
}
run sampleaes-ts   -autoplay media:KcXy8AGnf9:ts -seek-to 12
run aes128-mp4     -autoplay media:CjmpuxJII8:mp4 -seek-to 60
run aes128-ts      -autoplay media:CjmpuxJII8:ts -seek-to 60
run chapters-mp4   -autoplay media:9OtqBwqSF9:mp4 -seek-to 30
run plain-ts       -autoplay media:9OtqBwqSF9:ts -seek-to 30
run sintel-subs    -autoplay media:tF3ACeXqs5:mp4 -seek-to 600
run playlist-mp4   -autoplay playlist:7V3uCmRxBi:mp4
run channel-mp4    -autoplay channel:ksFeHdZjAJ:mp4
run channel-ts     -autoplay channel:ksFeHdZjAJ:ts
