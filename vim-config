#!/bin/bash

if ! command -v vim &> /dev/null; then
    echo "Vim не найден, ставлю..."
    sudo apt update && sudo apt install -y vim
fi

mkdir -p ~/.vim/plugin

echo "Качаю osc52.vim..."
wget -O ~/.vim/plugin/osc52.vim https://raw.githubusercontent.com/fcpg/vim-osc52/master/plugin/osc52.vim || {
    echo "Ой, не скачалось! Проверяй инет, бро."
    exit 1
}

VIMRC=~/.vimrc
if [ ! -f "$VIMRC" ]; then
    echo "Создаю .vimrc..."
    touch "$VIMRC"
fi

if ! grep -q "osc52.vim" "$VIMRC"; then
    echo "Добавляю маппинг для 'y' в .vimrc..."
    cat <<EOL >> "$VIMRC"

" osc52.vim для копирования через y
source ~/.vim/plugin/osc52.vim
vmap y y:call SendViaOSC52(getreg('"'))<cr>
EOL
else
    echo "osc52.vim уже в .vimrc, пропускаю..."
fi

echo "Готово 😎"
