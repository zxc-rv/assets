#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Бери sudo, братан!${NC}" >&2
  exit 1
fi

echo -e "${GREEN}Ставим fuse3...${NC}"
apt update -qq && apt install -y fuse3 -qq > /dev/null 2>&1 || {
  echo -e "${RED}Не смог поставить fuse3, чекни логи!${NC}" >&2
  exit 1
}

echo -e "${GREEN}Качаем Neovim AppImage...${NC}"
wget -q -O nvim-linux-x86_64.appimage https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage || {
  echo -e "${RED}Не смог скачать Neovim, проверь инет!${NC}" >&2
  exit 1
}

echo -e "${GREEN}Делаем AppImage исполняемым...${NC}"
chmod u+x nvim-linux-x86_64.appimage || {
  echo -e "${RED}Не смог дать права, что-то не так!${NC}" >&2
  exit 1
}

echo -e "${GREEN}Кидаем Neovim в /usr/local/bin...${NC}"
mv nvim-linux-x86_64.appimage /usr/local/bin/nvim || {
  echo -e "${RED}Не смог переместить, проверь права!${NC}" >&2
  exit 1
}


echo -e "${GREEN}Настраиваем init.lua...${NC}"
mkdir -p ~/.config/nvim

cat << 'EOF' > ~/.config/nvim/init.lua
vim.g.clipboard = 'osc52'
vim.keymap.set('v', '<C-C>', '"+y', { noremap = true })
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NonText", { bg = "none" })
vim.o.swapfile = false
EOF

echo -e "${GREEN}Neovim успешно установлен.${NC}"
