#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'




USER_HOME=$(eval echo "~$(logname)")
if [ "$USER_HOME" == "/root" ] && [ -n "$SUDO_USER" ]; then
    USER_HOME=$(eval echo "~$SUDO_USER")
fi

NVIM_CONFIG_DIR="$USER_HOME/.config/nvim"
NVIM_PLUGIN_DIR="$NVIM_CONFIG_DIR/plugin"
INIT_VIM_PATH="$NVIM_CONFIG_DIR/init.vim"
OSC52_PLUGIN_PATH="$NVIM_PLUGIN_DIR/osc52.vim"

if ! command -v nvim &> /dev/null
then
    echo -e "  ${RED}NeoVim не найден. Начинаю установку...${NC}"
    apt update -y > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "  ${RED}Ошибка при обновлении пакетов. Проверь подключение или репозитории.${NC}"
        exit 1
    fi
    apt install -y neovim > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "  ${RED}Ошибка при установке NeoVim. Выхожу.${NC}"
        exit 1
    fi
    echo -e "  ${GREEN}NeoVim успешно установлен!${NC}"
else
    echo -e "  ${GREEN}NeoVim уже установлен. Пропускаю установку.${NC}"
fi

mkdir -p "$NVIM_PLUGIN_DIR"
if [ $? -ne 0 ]; then
    echo -e "  ${RED}Не удалось создать директорию $NVIM_PLUGIN_DIR. Проверь права.${NC}"
    exit 1
fi
echo -e "  ${GREEN}Директории созданы.${NC}"

curl -s -o "$OSC52_PLUGIN_PATH" https://raw.githubusercontent.com/fcpg/vim-osc52/refs/heads/master/plugin/osc52.vim
if [ $? -ne 0 ]; then
    echo -e "  ${RED}Ошибка при скачивании osc52.vim. Проверь подключение к интернету или URL.${NC}"
    exit 1
fi
echo -e "  ${GREEN}Плагин osc52.vim успешно скачан в ${OSC52_PLUGIN_PATH}${NC}"

read -r -d '' ORIGINAL_TEXT_START_MARKER << 'EOF_ORIG_START'
function! s:rawecho(str)
EOF_ORIG_START

read -r -d '' ORIGINAL_TEXT_END_MARKER << 'EOF_ORIG_END'
endfun
EOF_ORIG_END

read -r -d '' NEW_TEXT_BLOCK << 'EOF_NEW_BLOCK'
function! s:rawecho(str)
  call writefile([a:str], '/dev/tty', 'b')
endfun
EOF_NEW_BLOCK

if [ ! -f "$OSC52_PLUGIN_PATH" ]; then
    echo -e "  ${RED}Ошибка: Файл плагина ${OSC52_PLUGIN_PATH} не найден. Не могу выполнить правку.${NC}"
    exit 1
fi

awk -v start_marker="$ORIGINAL_TEXT_START_MARKER" -v end_marker="$ORIGINAL_TEXT_END_MARKER" -v new_block="$NEW_TEXT_BLOCK" '
BEGIN {
    in_target_block = 0;
    substituted = 0;
}

$0 == start_marker && !substituted {
    print new_block; # Печатаем новый блок целиком
    in_target_block = 1; # Устанавливаем флаг, что мы внутри блока
    substituted = 1; # Отмечаем, что замена произошла, чтобы не повторять
    next; # Пропускаем текущую строку и переходим к следующей
}

$0 == end_marker && in_target_block {
    in_target_block = 0; # Выходим из блока
    next; # Пропускаем текущую строку ("endfun" старого блока), т.к. она уже в новом
}

!in_target_block {
    print $0;
}
' "$OSC52_PLUGIN_PATH" > "${OSC52_PLUGIN_PATH}.tmp"


if [ ! -s "${OSC52_PLUGIN_PATH}.tmp" ]; then
    echo -e "  ${RED}Ошибка: Временный файл после обработки AWK пуст или не создан. Это странно. Проверь логику AWK или исходный файл.${NC}"
    rm -f "${OSC52_PLUGIN_PATH}.tmp"
    exit 1
fi

if grep -q "$NEW_TEXT_BLOCK" "${OSC52_PLUGIN_PATH}.tmp"; then
    echo -e "  ${GREEN}Файл osc52.vim успешно пропатчен!${NC}"
    mv "${OSC52_PLUGIN_PATH}.tmp" "$OSC52_PLUGIN_PATH"
    if [ $? -ne 0 ]; then
        echo -e "  ${RED}Ошибка при перемещении временного файла. Проверь права или место назначения.${NC}"
        rm -f "${OSC52_PLUGIN_PATH}.tmp"
        exit 1
    fi
else
    echo -e "  ${RED}Ошибка: Новый блок кода НЕ найден во временном файле после обработки AWK. Замена не удалась.${NC}"
    echo -e "  ${YELLOW}Содержимое временного файла (${OSC52_PLUGIN_PATH}.tmp):${NC}"
    cat "${OSC52_PLUGIN_PATH}.tmp"
    rm -f "${OSC52_PLUGIN_PATH}.tmp"
    exit 1
fi


if [ ! -f "$INIT_VIM_PATH" ]; then
    mkdir -p "$(dirname "$INIT_VIM_PATH")"
    touch "$INIT_VIM_PATH"
    echo -e "  ${YELLOW}Файл init.vim не найден. Создаю: ${GREEN}$INIT_VIM_PATH${NC}"
fi

if ! grep -q "vnoremap <C-C> y:call SendViaOSC52(getreg('\"'))<CR>" "$INIT_VIM_PATH" 2>/dev/null; then
    echo "vnoremap <C-C> y:call SendViaOSC52(getreg('\"'))<CR>" >> "$INIT_VIM_PATH"
    echo "vim.o.swapfile = false" >> "$INIT_VIM_PATH"
    echo -e "  ${GREEN}Маппинг успешно добавлен в init.vim.${NC}"
else
    echo -e "  ${YELLOW}Маппинг уже существует в init.vim. Пропускаю.${NC}"
fi

echo -e "\n${GREEN} НАСТРОЙКА NeoVim ЗАВЕРШЕНА!${NC}"

