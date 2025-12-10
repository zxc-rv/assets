#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BLUE='\033[1;34m'
PURPLE='\033[38;2;120;93;200m'

spinner() {
  local pid=$1
  local msg=$2
  local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  while [ -d /proc/$pid ]; do
    printf "\r${BLUE}%s${NC} %s" "${spinstr:$i:1}" "$msg"
    i=$(((i + 1) % ${#spinstr}))
    sleep 0.1
  done
  printf "\r${GREEN}✔ ${NC} %s\n" "$msg"
}

VERSION=""
URL=""

while [[ $# -gt 0 ]]; do
  case $1 in
  -v*)
    VERSION="${1#-v}"
    shift
    ;;
  *)
    echo -e "${RED}Неизвестный аргумент: $1${NC}"
    echo "Использование: $0 [-v<версия>]"
    exit 1
    ;;
  esac
done

if [ -z "$VERSION" ]; then
  URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip"
else
  URL="https://github.com/XTLS/Xray-core/releases/download/v${VERSION}/Xray-linux-64.zip"
fi

echo -e "\n${PURPLE}Запуск обновления Xray...${NC}\n"
if [ -n "$VERSION" ]; then
  echo -e "${PURPLE}Версия: v${VERSION}${NC}"
fi
sleep 0.5

if [ ! -d /opt/remnawave ]; then
  echo -e "${RED}Ошибка: директория /opt/remnawave не существует${NC}"
  exit 1
fi

if ! command -v yq &> /dev/null; then
  apt update >/dev/null 2>&1 && apt install -y yq >/dev/null 2>&1 &
  spinner $! "Установка yaml парсера..."
  if ! command -v yq &> /dev/null; then
    echo -e "${RED}Ошибка: не удалось установить yq${NC}"
    exit 1
  fi
fi

COMPOSE_FILE="/opt/remnawave/docker-compose.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
  echo -e "${RED}Ошибка: файл $COMPOSE_FILE не найден${NC}"
  exit 1
fi

if ! yq -e '.services.remnanode.volumes[] | select(. == "./xray:/usr/local/bin/xray")' "$COMPOSE_FILE" >/dev/null 2>&1; then
  yq -y '.services.remnanode.volumes += ["./xray:/usr/local/bin/xray"]' "$COMPOSE_FILE" > /tmp/docker-compose.yml.tmp && mv /tmp/docker-compose.yml.tmp "$COMPOSE_FILE" &
  spinner $! "Добавление volume в docker-compose.yml..."
fi

curl -Lso /tmp/Xray-linux-64.zip "$URL" &
spinner $! "Скачивание релиза Xray..."

unzip -q /tmp/Xray-linux-64.zip xray -d /tmp &
spinner $! "Извлечение Xray..."

mv /tmp/xray /opt/remnawave/xray &
spinner $! "Перемещение Xray в /opt/remnawave..."

rm -rf /tmp/Xray-linux-64.zip &
spinner $! "Удаление временных файлов..."

chmod +x /opt/remnawave/xray &
spinner $! "Назначение прав на запуск Xray..."

cd /opt/remnawave && docker compose up -d --force-recreate remnanode >/dev/null 2>&1 &
spinner $! "Перезапуск ноды..."

if [ $? -ne 0 ]; then
  echo -e "${RED}Не удалось выполнить перезапуск ноды.${NC}" >&2
  exit 1
fi

echo -e "\n${PURPLE}☑️ Обновление Xray завершено.${NC}\n"
