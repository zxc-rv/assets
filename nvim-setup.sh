#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Бери sudo!${NC}" >&2
  exit 1
fi

echo -e "\n${GREEN}Установка fuse3...${NC}"
apt update -qq >/dev/null 2>&1 && apt install -y fuse3 -qq >/dev/null 2>&1 || {
  echo -e "${RED}Не смог поставить fuse3, чекни логи!${NC}" >&2
  exit 1
}

echo -e "\n${GREEN}Установка Neovim...${NC}"
wget -q -O nvim-linux-x86_64.appimage https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage || {
  echo -e "\n${RED}Не смог скачать Neovim, проверь инет!${NC}" >&2
  exit 1
}
chmod u+x nvim-linux-x86_64.appimage || {
  echo -e "\n${RED}Не смог дать права, что-то не так!${NC}" >&2
  exit 1
}
mv nvim-linux-x86_64.appimage /usr/local/bin/nvim || {
  echo -e "\n${RED}Не смог переместить, проверь права!${NC}" >&2
  exit 1
}


echo -e "\n${GREEN}Настройка init.lua...${NC}"
mkdir -p ~/.config/nvim

cat << 'EOF' > ~/.config/nvim/init.lua
vim.g.clipboard = 'osc52'
vim.g.mapleader = " "
vim.o.number = true
vim.o.swapfile = false
vim.o.winborder = "rounded"
vim.keymap.set('v', '<C-C>', '"+y', { noremap = true })
vim.keymap.set('n', '<leader>f', ":Pick files<CR>")
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NonText", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
vim.cmd(":hi statusline guibg=NONE guifg=#ffffff")
vim.pack.add{
  { src = 'https://github.com/echasnovski/mini.pick' },
}
require "mini.pick".setup()


EOF

echo -e "\n${GREEN}Neovim успешно установлен.${NC}\n"
