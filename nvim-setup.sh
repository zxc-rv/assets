#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
  echo "Бери sudo!" >&2
  exit 1
fi

echo "Ставим fuse3..."
apt update && apt install -y fuse3 || {
  echo "Не смог поставить fuse3, чекни логи!" >&2
  exit 1
}

echo "Качаем Neovim AppImage..."
wget -O nvim-linux-x86_64.appimage https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage || {
  echo "Не смог скачать Neovim, проверь инет или ссылку!" >&2
  exit 1
}

echo "Делаем AppImage исполняемым..."
chmod u+x nvim-linux-x86_64.appimage || {
  echo "Не смог дать права, что-то пошло не так!" >&2
  exit 1
}

echo "Кидаем Neovim в /usr/local/bin..."
mv nvim-linux-x86_64.appimage /usr/local/bin/nvim || {
  echo "Не смог переместить, проверь права или место!" >&2
  exit 1
}

echo "Настраиваем init.lua..."
mkdir -p ~/.config/nvim

cat << 'EOF' > ~/.config/nvim/init.lua
vim.g.clipboard = {
  name = 'OSC52',
  copy = {
    ['+'] = function(lines) require('vim.ui.clipboard.osc52').copy('+')(lines) end,
    ['*'] = function(lines) require('vim.ui.clipboard.osc52').copy('*')(lines) end,
  },
  paste = {
    ['+'] = function() return vim.fn.split(vim.fn.getreg('+'), '\n') end,
    ['*'] = function() return vim.fn.split(vim.fn.getreg('*'), '\n') end,
  },
}
vim.keymap.set('v', '<C-C>', '"+y', { noremap = true })
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NonText", { bg = "none" })
vim.o.swapfile = false
EOF

echo "Всё готово! Neovim установлен, init.lua настроен."
