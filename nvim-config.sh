#!/bin/bash

USER_HOME=$(eval echo "~$(logname)")
NVIM_CONFIG_DIR="$USER_HOME/.config/nvim"
NVIM_PLUGIN_DIR="$NVIM_CONFIG_DIR/plugin"
INIT_VIM_PATH="$NVIM_CONFIG_DIR/init.vim"
OSC52_PLUGIN_PATH="$NVIM_PLUGIN_DIR/osc52.vim"

echo "Домашняя директория пользователя: $USER_HOME"
echo "Путь к конфигам NeoVim: $NVIM_CONFIG_DIR"


mkdir -p "$NVIM_PLUGIN_DIR"
if [ $? -ne 0 ]; then
    echo "Не удалось создать директорию $NVIM_PLUGIN_DIR. Проверь права."
    exit 1
fi


echo "Скачиваю плагин osc52.vim..."
curl -o "$OSC52_PLUGIN_PATH" https://raw.githubusercontent.com/fcpg/vim-osc52/refs/heads/master/plugin/osc52.vim
if [ $? -ne 0 ]; then
    echo "Ошибка при скачивании osc52.vim. Проверь подключение к интернету или URL."
    exit 1
fi
echo "Плагин osc52.vim скачан в $OSC52_PLUGIN_PATH."


echo "Правлю файл osc52.vim..."


ORIG_TEXT="function! s:rawecho(str)\n  let redraw = get(g:, 'osc52_redraw', 2)\n  let print  = get(g:, 'osc52_print', 'echo')\n  if print == 'echo'\n    exe \"silent! !echo\" shellescape(a:str)\n  elseif print == 'printf'\n    exe \"silent! !printf \\\\%s\" shellescape(a:str)\n  else\n    exe print shellescape(a:str)\n  endif\n  if redraw == 2\n    redraw!\n  elseif redraw == 1\n    redraw\n  endif\nendfun"


NEW_TEXT="function! s:rawecho(str)\n  call writefile([a:str], '\/dev\/tty', 'b')\nendfun"


printf '%s' "$ORIG_TEXT" | sed -z 's/\n/\\n/g' | xargs -0 -I {} sed -i "s@{}$@$NEW_TEXT@g" "$OSC52_PLUGIN_PATH"

if [ $? -ne 0 ]; then
    echo "Ошибка при правке osc52.vim. Возможно, исходный текст не найден или синтаксис sed неверен."
    exit 1
fi
echo "Файл osc52.vim успешно пропатчен."

echo "Добавляю маппинг в $INIT_VIM_PATH..."
if ! grep -q "vnoremap <C-C> y:call SendViaOSC52(getreg('\"'))<CR>" "$INIT_VIM_PATH" 2>/dev/null; then
    echo "vnoremap <C-C> y:call SendViaOSC52(getreg('\"'))<CR>" >> "$INIT_VIM_PATH"
    echo "Маппинг добавлен в init.vim."
else
    echo "Маппинг уже существует в init.vim. Пропускаю."
fi
