#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}--- Запускаю установщик и настройщик NeoVim ---${NC}"


USER_HOME=$(eval echo "~$(logname)")
if [ "$USER_HOME" == "/root" ] && [ -n "$SUDO_USER" ]; then
    USER_HOME=$(eval echo "~$SUDO_USER")
fi

NVIM_CONFIG_DIR="$USER_HOME/.config/nvim"
NVIM_PLUGIN_DIR="$NVIM_CONFIG_DIR/plugin"
INIT_VIM_PATH="$NVIM_CONFIG_DIR/init.vim"
OSC52_PLUGIN_PATH="$NVIM_PLUGIN_DIR/osc52.vim"

echo -e "  ${YELLOW}*${NC} Рабочая директория пользователя: ${GREEN}$USER_HOME${NC}"
echo -e "  ${YELLOW}*${NC} Путь к конфигам NeoVim: ${GREEN}$NVIM_CONFIG_DIR${NC}"

echo -e "${YELLOW}--- Проверка установки NeoVim ---${NC}"
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

echo -e "${YELLOW}--- Создание необходимых директорий ---${NC}"
mkdir -p "$NVIM_PLUGIN_DIR"
if [ $? -ne 0 ]; then
    echo -e "  ${RED}Не удалось создать директорию $NVIM_PLUGIN_DIR. Проверь права.${NC}"
    exit 1
fi
echo -e "  ${GREEN}Директории созданы или уже существуют.${NC}"

echo -e "${YELLOW}--- Скачивание плагина osc52.vim ---${NC}"
curl -s -o "$OSC52_PLUGIN_PATH" https://raw.githubusercontent.com/fcpg/vim-osc52/refs/heads/master/plugin/osc52.vim
if [ $? -ne 0 ]; then
    echo -e "  ${RED}Ошибка при скачивании osc52.vim. Проверь подключение к интернету или URL.${NC}"
    exit 1
fi
echo -e "  ${GREEN}Плагин osc52.vim успешно скачан в ${OSC52_PLUGIN_PATH}${NC}"

echo -e "${YELLOW}--- Правка файла osc52.vim ---${NC}"

read -r -d '' ORIG_TEXT << EOM
function! s:rawecho(str)
  let redraw = get(g:, 'osc52_redraw', 2)
  let print  = get(g:, 'osc52_print', 'echo')
  if print == 'echo'
    exe "silent! !echo" shellescape(a:str)
  elseif print == 'printf'
    exe "silent! !printf \%s" shellescape(a:str)
  else
    exe print shellescape(a:str)
  endif
  if redraw == 2
    redraw!
  elseif redraw == 1
    redraw
  endif
endfun
EOM

read -r -d '' NEW_TEXT << EOM
function! s:rawecho(str)
  call writefile([a:str], '/dev/tty', 'b')
endfun
EOM

perl -0777 -pi -e "s{\Q$ORIG_TEXT\E}{$NEW_TEXT}s" "$OSC52_PLUGIN_PATH" 2>/dev/null

if [ $? -ne 0 ]; then
    echo -e "  ${RED}Ошибка при правке osc52.vim. Возможно, исходный текст не найден или проблема с perl.${NC}"
    exit 1
fi
echo -e "  ${GREEN}Файл osc52.vim успешно пропатчен!${NC}"


echo -e "${YELLOW}--- Добавление маппинга в init.vim ---${NC}"
if [ ! -f "$INIT_VIM_PATH" ]; then
    mkdir -p "$(dirname "$INIT_VIM_PATH")"
    touch "$INIT_VIM_PATH"
    echo -e "  ${YELLOW}Файл init.vim не найден. Создаю: ${GREEN}$INIT_VIM_PATH${NC}"
fi

if ! grep -q "vnoremap <C-C> y:call SendViaOSC52(getreg('\"'))<CR>" "$INIT_VIM_PATH" 2>/dev/null; then
    echo "vnoremap <C-C> y:call SendViaOSC52(getreg('\"'))<CR>" >> "$INIT_VIM_PATH"
    echo -e "  ${GREEN}Маппинг успешно добавлен в init.vim.${NC}"
else
    echo -e "  ${YELLOW}Маппинг уже существует в init.vim. Пропускаю.${NC}"
fi

echo -e "\n${GREEN}--- НАСТРОЙКА NeoVim ЗАВЕРШЕНА! ---${NC}"
