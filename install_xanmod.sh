#!/bin/bash

XANMOD='\033[38;2;158;154;154m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
BLUE='\033[1;34m'
PURPLE='\033[38;2;120;93;200m'

clear

echo -e "${XANMOD}██╗  ██╗ █████╗ ███╗   ██╗███╗   ███╗ ██████╗ ██████╗     ███████╗███████╗████████╗██╗   ██╗██████╗ ${NC}"
echo -e "${XANMOD}╚██╗██╔╝██╔══██╗████╗  ██║████╗ ████║██╔═══██╗██╔══██╗    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗${NC}"
echo -e "${XANMOD} ╚███╔╝ ███████║██╔██╗ ██║██╔████╔██║██║   ██║██║  ██║    ███████╗█████╗     ██║   ██║   ██║██████╔╝${NC}"
echo -e "${XANMOD} ██╔██╗ ██╔══██║██║╚██╗██║██║╚██╔╝██║██║   ██║██║  ██║    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ ${NC}"
echo -e "${XANMOD}██╔╝ ██╗██║  ██║██║ ╚████║██║ ╚═╝ ██║╚██████╔╝██████╔╝    ███████║███████╗   ██║   ╚██████╔╝██║     ${NC}"
echo -e "${XANMOD}╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝ ╚═════╝     ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     ${NC}"
echo ""

spinner() {
  local pid=$1
  local msg=$2
  local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  while [ -d /proc/$pid ]; do
    printf "\r${BLUE}%s${NC} %s" "${spinstr:$i:1}" "$msg"
    i=$(((i + 1) % ${#spinstr}))
    sleep 0.1
  done
  printf "\r${GREEN}✔ ${NC} %s\n" "$msg"
}

if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Требуются права root${NC}" >&2
  exit 1
fi

echo ""

(apt update -qq >/dev/null 2>&1 && apt install -y gpg -qq >/dev/null 2>&1) &
spinner $! "Установка gpg..."
if [ $? -ne 0 ]; then
  echo -e "${RED}Ошибка установки gpg${NC}" >&2
  exit 1
fi

(curl -Ls https://gitlab.com/afrd.gpg | gpg --dearmor --yes -o /usr/share/keyrings/xanmod-archive-keyring.gpg) &
spinner $! "Установка ключа Xanmod..."
if [ $? -ne 0 ]; then
  echo -e "${RED}Ошибка скачивания ключа${NC}" >&2
  exit 1
fi

(echo "deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main" | tee /etc/apt/sources.list.d/xanmod-release.list >/dev/null) &
spinner $! "Добавление репозитория Xanmod..."
if [ $? -ne 0 ]; then
  echo -e "${RED}Ошибка добавления репозитория${NC}" >&2
  exit 1
fi

psabi_output=$(curl -Ls https://dl.xanmod.org/check_x86-64_psabi.sh | awk -f - 2>/dev/null)
psabi_status=$?
psabi=$(echo "$psabi_output" | grep -o 'x86-64-v[1-4]' || true)
if [ $psabi_status -lt 2 ] || [ -z "$psabi" ]; then
  echo -e "${RED}Ошибка определения CPU${NC}" >&2
  exit 1
fi

echo -e "${BLUE}ℹ️ Обнаружен CPU: $psabi${NC}"

case "$psabi" in
x86-64-v1)
  kernel_pkg="linux-xanmod-x64v1"
  ;;
x86-64-v2)
  kernel_pkg="linux-xanmod-x64v2"
  ;;
x86-64-v3 | x86-64-v4)
  kernel_pkg="linux-xanmod-x64v3"
  ;;
*)
  echo -e "${RED}Неизвестный CPU $psabi${NC}" >&2
  exit 1
  ;;
esac

(apt update -qq >/dev/null 2>&1 && apt install -y "$kernel_pkg" -qq >/dev/null 2>&1) &
spinner $! "Установка ядра $kernel_pkg..."
if [ $? -ne 0 ]; then
  echo -e "${RED}Ошибка установки ядра $kernel_pkg${NC}" >&2
  exit 1
fi

(sleep 0.5 &&
  sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf &&
  sed -i '/net.core.rmem_max/d' /etc/sysctl.conf &&
  sed -i '/net.core.wmem_max/d' /etc/sysctl.conf &&
  sed -i '/net.core.wmem_default/d' /etc/sysctl.conf &&
  sed -i '/net.core.netdev_max_backlog/d' /etc/sysctl.conf &&
  sed -i '/net.core.somaxconn/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.tcp_syncookies/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.tcp_tw_reuse/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.tcp_fin_timeout/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.tcp_keepalive_time/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.tcp_keepalive_probes/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.tcp_keepalive_intvl/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.tcp_max_syn_backlog/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.tcp_max_tw_buckets/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.tcp_fastopen/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.tcp_timestamps/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.tcp_mem/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.udp_mem/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.tcp_rmem/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.tcp_wmem/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.tcp_mtu_probing/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.tcp_slow_start_after_idle/d' /etc/sysctl.conf &&
  sed -i '/fs.inotify.max_user_instances/d' /etc/sysctl.conf &&
  sed -i '/net.ipv4.ip_local_port_range/d' /etc/sysctl.conf &&
  echo "net.core.default_qdisc=fq" >>/etc/sysctl.conf &&
  echo "net.ipv4.tcp_congestion_control=bbr" >>/etc/sysctl.conf &&
  echo "net.core.rmem_max = 67108864" >>/etc/sysctl.conf &&
  echo "net.core.wmem_max = 67108864" >>/etc/sysctl.conf &&
  echo "net.core.wmem_default = 2097152" >>/etc/sysctl.conf &&
  echo "net.core.netdev_max_backlog = 10240" >>/etc/sysctl.conf &&
  echo "net.core.somaxconn = 8192" >>/etc/sysctl.conf &&
  echo "net.ipv4.tcp_syncookies = 1" >>/etc/sysctl.conf &&
  echo "net.ipv4.tcp_tw_reuse = 1" >>/etc/sysctl.conf &&
  echo "net.ipv4.tcp_fin_timeout = 30" >>/etc/sysctl.conf &&
  echo "net.ipv4.tcp_keepalive_time = 1200" >>/etc/sysctl.conf &&
  echo "net.ipv4.tcp_keepalive_probes = 5" >>/etc/sysctl.conf &&
  echo "net.ipv4.tcp_keepalive_intvl = 30" >>/etc/sysctl.conf &&
  echo "net.ipv4.tcp_max_syn_backlog = 10240" >>/etc/sysctl.conf &&
  echo "net.ipv4.tcp_max_tw_buckets = 5000" >>/etc/sysctl.conf &&
  echo "net.ipv4.tcp_fastopen = 3" >>/etc/sysctl.conf &&
  echo "net.ipv4.tcp_timestamps = 1" >>/etc/sysctl.conf &&
  echo "net.ipv4.tcp_mem = 25600 51200 102400" >>/etc/sysctl.conf &&
  echo "net.ipv4.udp_mem = 25600 51200 102400" >>/etc/sysctl.conf &&
  echo "net.ipv4.tcp_rmem = 16384 262144 8388608" >>/etc/sysctl.conf &&
  echo "net.ipv4.tcp_wmem = 32768 524288 16777216" >>/etc/sysctl.conf &&
  echo "net.ipv4.tcp_mtu_probing = 1" >>/etc/sysctl.conf &&
  echo "net.ipv4.tcp_slow_start_after_idle=0" >>/etc/sysctl.conf &&
  echo "fs.inotify.max_user_instances = 8192" >>/etc/sysctl.conf &&
  echo "net.ipv4.ip_local_port_range = 1024 45000" >>/etc/sysctl.conf &&
  sysctl -p >/dev/null 2>&1) &
spinner $! "Оптимизация настроек sysctl..."
if [ $? -ne 0 ]; then
  echo -e "${RED}Ошибка настройки и применения sysctl${NC}" >&2
  exit 1
fi

echo ""
echo -e "${PURPLE}☑️ Xanmod успешно установлен.${NC}"
echo ""
echo -e "${RED}❗ Перезагрузите систему для загрузки Xanmod.${NC}"
echo ""
