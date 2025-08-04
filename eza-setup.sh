#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BLUE='\033[1;34m'

# Функция для спиннера с заменой на галочку
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
    printf "\r${GREEN}✔${NC} %s\n" "$msg" # Заменяем спиннер на галочку и оставляем строку
}

# Проверка на sudo
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Бери sudo!${NC}" >&2
    exit 1
fi

echo "" # Пропуск строки перед первым спиннером

# Установка gpg
(apt update -qq >/dev/null 2>&1 && apt install -y gpg -qq >/dev/null 2>&1) & spinner $! "Установка gpg..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Не смог поставить gpg, чекни логи!${NC}" >&2
    exit 1
fi

# Создание директории для keyrings
(mkdir -p /etc/apt/keyrings) & spinner $! "Создаю директорию keyrings..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Не смог создать директорию /etc/apt/keyrings, что-то не так!${NC}" >&2
    exit 1
fi

# Скачивание и установка ключа с авто-перезаписью
(wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg) & spinner $! "Скачиваю и устанавливаю ключ..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Не смог скачать или установить ключ, проверь инет!${NC}" >&2
    exit 1
fi

# Добавление репозитория
(echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list >/dev/null) & spinner $! "Добавляю репозиторий eza..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Не смог добавить репозиторий, что-то пошло не так!${NC}" >&2
    exit 1
fi

# Установка прав на файлы
(chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list) & spinner $! "Устанавливаю права на файлы..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Не смог установить права, проверь доступ!${NC}" >&2
    exit 1
fi

# Обновление и установка eza
(apt update -qq >/dev/null 2>&1 && apt install -y eza -qq >/dev/null 2>&1) & spinner $! "Установка eza..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Не смог установить eza, чекни логи!${NC}" >&2
    exit 1
fi

# Добавление alias для ls
(echo "alias ls='eza --icons=always'" >> ~/.bashrc) & spinner $! "Добавляю alias для ls..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Не смог добавить alias в .bashrc, проверь права!${NC}" >&2
    exit 1
fi

echo -e "\n${GREEN}eza успешно установлен и настроен! 🔥${NC}\n"
