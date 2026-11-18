#!/bin/sh
# Кодогенерация Apollo: типы Swift и манифест операций клиента DodocastTV из схемы app-api.
#   scripts/codegen.sh
#
# Схема — SDL сервиса рядом: ../mediaflux-app-api/src/main/resources/graphql/*.graphqls (ветка feature/mf-86-apps).
# Операции — DodocastTV/GraphQL/Operations/*.graphql. Результат лежит в git: сборке кодогенерация не нужна.
#
# CLI — из официального релиза apollographql/apollo-ios той же версии, что пакет в project.yml (код и библиотека
# обязаны совпадать). Скачивается один раз в .build/apollo-ios-cli-<версия>/ (вне git).
#
# Манифест операций (DodocastTV/GraphQL/operation-manifest.json) — для режима `registered` app-api: его копия кладётся
# в mediaflux-app-api/src/main/resources/operations/tvos-<версия>.json (APPS.md §10).
set -eu
cd "$(dirname "$0")/.."
VERSION=2.5.0
DIR=.build/apollo-ios-cli-$VERSION
CLI=$DIR/apollo-ios-cli
if [ ! -x "$CLI" ]; then
  mkdir -p "$DIR"
  curl -fsSL -o "$DIR/apollo-ios-cli.tar.gz" \
    "https://github.com/apollographql/apollo-ios/releases/download/$VERSION/apollo-ios-cli.tar.gz"
  tar -xzf "$DIR/apollo-ios-cli.tar.gz" -C "$DIR"
fi
test -d ../mediaflux-app-api/src/main/resources/graphql || { echo "нет схемы app-api рядом: ../mediaflux-app-api"; exit 1; }
"$CLI" generate --path apollo-codegen-config.json
echo ">>> сгенерировано: DodocastTV/GraphQL/Generated, манифест DodocastTV/GraphQL/operation-manifest.json"
