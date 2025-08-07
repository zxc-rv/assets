#!/bin/bash

NVIM='\033[38;2;88;147;61m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BLUE='\033[1;34m'
PURPLE='\033[38;2;120;93;200m'

clear

echo -e "${NVIM}███╗   ██╗██╗   ██╗██╗███╗   ███╗    ███████╗███████╗████████╗██╗   ██╗██████╗ ${NC}"
echo -e "${NVIM}████╗  ██║██║   ██║██║████╗ ████║    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗${NC}"
echo -e "${NVIM}██╔██╗ ██║██║   ██║██║██╔████╔██║    ███████╗█████╗     ██║   ██║   ██║██████╔╝${NC}"
echo -e "${NVIM}██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ ${NC}"
echo -e "${NVIM}██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║    ███████║███████╗   ██║   ╚██████╔╝██║     ${NC}"
echo -e "${NVIM}╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝    ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     ${NC}"
echo ""

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
    echo -e "${RED}Бери sudo!${NC}" >&2
    exit 1
fi
echo ""
(apt update -qq >/dev/null 2>&1 && apt install -y fuse3 fd-find ripgrep git -qq >/dev/null 2>&1) & spinner $! "Установка зависимостей..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Не смог поставить fuse3, чекни логи!${NC}" >&2
    exit 1
fi
(wget -q -O nvim-linux-x86_64.appimage https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage) & spinner $! "Установка Neovim..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Не смог скачать Neovim, проверь инет!${NC}" >&2
    exit 1
fi
(chmod u+x nvim-linux-x86_64.appimage) & spinner $! "Настройка права Neovim..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Не смог дать права, что-то не так!${NC}" >&2
    exit 1
fi
(mv nvim-linux-x86_64.appimage /usr/local/bin/nvim) & spinner $! "Перемещение Neovim..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Не смог переместить, проверь права!${NC}" >&2
    exit 1
fi
(mkdir -p ~/.config/nvim && cat << 'EOF' > ~/.config/nvim/init.lua
vim.g.clipboard = 'osc52'
vim.g.mapleader = " "
vim.o.number = true
vim.o.swapfile = false
vim.o.winborder = "rounded"
vim.keymap.set('v', '<C-C>', '"+y', { noremap = true })
vim.keymap.set('n', '<C-f>', '/', { noremap = true })
vim.keymap.set('n', '<leader>f', ":Pick files<CR>")
vim.pack.add{
  { src = 'https://github.com/folke/tokyonight.nvim' },
  { src = 'https://github.com/echasnovski/mini.pick' },
}
require "mini.pick".setup()
vim.cmd(":hi statusline guibg=NONE guifg=#ffffff")
require('tokyonight').setup({
  transparent = true,
  styles = {
    sidebars = 'transparent',
    floats = 'transparent',
  },
})
vim.cmd("colorscheme tokyonight-moon")
EOF
) & spinner $! "Настройка init.lua..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Не смог настроить init.lua, что-то пошло не так!${NC}" >&2
    exit 1
fi
(grep -q "alias vim=nvim" ~/.bashrc || echo "alias vim='nvim'" >> ~/.bashrc) & spinner $! "Добавление алиаса vim -> nvim..."
if [ $? -ne 0 ]; then
    echo -e "${RED}Не смог добавить алиас, проверь ~/.bashrc!${NC}" >&2
    exit 1
fi
echo -e "\n${PURPLE}☑️ Neovim успешно установлен.${NC}\n"
