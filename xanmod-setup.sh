#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BLUE='\033[1;34m'

spinner() {
    local pid=$1
    local msg=$2
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while [ -d /proc/$pid ]; do
        printf "\r${BLUE}%s${NC} %s" "${spinstr:$i:1}" "$msg"
        i=$(( (i+1) % ${#spinstr} ))
        sleep 0.1
    done
    printf "\r${GREEN}✔ ${NC} %s\n" "$msg"
}

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Требуются права root${NC}" >&2
    exit 1
fi

echo ""

(apt update -qq >/dev/null 2>&1 && apt install -y gpg -qq >/dev/null 2>&1) & spinner $! "Установка gpg..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Ошибка установки gpg${NC}" >&2
    exit 1
fi

(wget -qO- --no-cache https://gitlab.com/afrd.gpg | gpg --dearmor --yes -o /usr/share/keyrings/xanmod-archive-keyring.gpg) & spinner $! "Установка ключа Xanmod..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Ошибка скачивания ключа${NC}" >&2
    exit 1
fi

(echo "deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main" | tee /etc/apt/sources.list.d/xanmod-release.list >/dev/null) & spinner $! "Добавление репозитория Xanmod..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Ошибка добавления репозитория${NC}" >&2
    exit 1
fi

psabi_output=$(wget -qO- https://dl.xanmod.org/check_x86-64_psabi.sh | awk -f - 2>/dev/null)
psabi_status=$?
psabi=$(echo "$psabi_output" | grep -o 'x86-64-v[1-4]' || true)
if [ $psabi_status -lt 2 ] || [ -z "$psabi" ]; then
    echo -e "${RED}Ошибка определения уровня PSABI${NC}" >&2
    exit 1
fi

echo -e "${BLUE}ℹ️ Обнаружен уровень PSABI: $psabi${NC}"

case "$psabi" in
    x86-64-v1)
        kernel_pkg="linux-xanmod-x64v1"
        ;;
    x86-64-v2)
        kernel_pkg="linux-xanmod-x64v2"
        ;;
    x86-64-v3|x86-64-v4)
        kernel_pkg="linux-xanmod-x64v3"
        ;;
    *)
        echo -e "${RED}Неизвестный уровень PSABI: $psabi${NC}" >&2
        exit 1
        ;;
esac

(apt update -qq >/dev/null 2>&1 && apt install -y "$kernel_pkg" -qq >/dev/null 2>&1) & spinner $! "Установка ядра $kernel_pkg..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Ошибка установки ядра $kernel_pkg${NC}" >&2
    exit 1
fi

(sleep 0.5 && grep -Fx "net.core.default_qdisc=fq" /etc/sysctl.conf >/dev/null || echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf; grep -Fx "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf >/dev/null || echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf; sysctl -p >/dev/null 2>&1) & spinner $! "Применение настроек sysctl..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Ошибка настройки и применения sysctl${NC}" >&2
    exit 1
fi

echo -e "\n${GREEN}Xanmod успешно установлен.${NC}"
echo -e "\n${RED}❗ Перезагрузка системы через 5 секунд...${NC}\n"
sleep 5
reboot
