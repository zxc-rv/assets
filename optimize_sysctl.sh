#!/bin/sh

set -e

[ "$(id -u)" -eq 0 ] || { echo "Нужен root"; exit 1; }

echo "tcp_bbr" > /etc/modules-load.d/bbr.conf
modprobe tcp_bbr

cat > /etc/sysctl.d/99-network-tuning.conf <<EOF
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.wmem_default = 2097152
net.core.netdev_max_backlog = 10240
net.core.somaxconn = 8192
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_max_syn_backlog = 10240
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.udp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 131072 67108864
net.ipv4.tcp_wmem = 4096 131072 67108864
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_slow_start_after_idle = 0
fs.inotify.max_user_instances = 8192
net.ipv4.ip_local_port_range = 1024 45000
net.ipv4.tcp_notsent_lowat = 131072
EOF

sysctl --system > /dev/null

printf '\n  Оптимизация сервера \033[32mвыполнена\033[0m\n\n'
