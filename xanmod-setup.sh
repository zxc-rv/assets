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
    printf "\r${GREEN}✔${NC} %s\n" "$msg"
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

(wget -qO- --no-cache https://gitlab.com/afrd.gpg | gpg --dearmor --yes -o /usr/share/keyrings/xanmod-archive-keyring.gpg) & spinner $! "Скачивание ключа XanMod..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Ошибка скачивания ключа${NC}" >&2
    exit 1
fi

(echo "deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main" | tee /etc/apt/sources.list.d/xanmod-release.list >/dev/null) & spinner $! "Добавление репозитория XanMod..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Ошибка добавления репозитория${NC}" >&2
    exit 1
fi

(wget -qO- https://dl.xanmod.org/check_x86-64_psabi.sh | bash > /tmp/psabi_output.txt) & spinner $! "Проверка CPU PSABI..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Ошибка проверки CPU PSABI${NC}" >&2
    exit 1
fi

psabi=$(grep "CPU supports" /tmp/psabi_output.txt | awk '{print $NF}')
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

(grep -Fx "net.core.default_qdisc=fq" /etc/sysctl.conf >/dev/null || echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf) & spinner $! "Настройка sysctl: default_qdisc..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Ошибка настройки sysctl.conf для default_qdisc${NC}" >&2
    exit 1
fi

(grep -Fx "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf >/dev/null || echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf) & spinner $! "Настройка sysctl: tcp_congestion_control..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Ошибка настройки sysctl.conf для tcp_congestion_control${NC}" >&2
    exit 1
fi

(sleep 0.5 && sysctl -p >/dev/null 2>&1) & spinner $! "Применение настроек sysctl..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Ошибка применения настроек sysctl${NC}" >&2
    exit 1
fi

echo -e "\n${GREEN}XanMod успешно установлен и настроен! 🔥${NC}\n"
