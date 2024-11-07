#!/usr/bin/env bash
rm -f /tmp/warp-connected
[ -c /dev/ppp ] || mknod /dev/ppp c 108 0

mkdir -p /dev/net
mknod /dev/net/tun c 10 200
chmod 600 /dev/net/tun

# as gateway
function setup_iptables() {
  VPN_IF="CloudflareWARP"
  while [ ! -e "/sys/class/net/CloudflareWARP/" ]; do
    echo Waiting for tun interface..
    sleep 1
  done
  iptables -t nat -A POSTROUTING -o $VPN_IF -j MASQUERADE
  iptables -A FORWARD -i $VPN_IF -o $VPN_IF -j ACCEPT
  iptables -A FORWARD -i eth0 -o $VPN_IF -j ACCEPT
  iptables -A FORWARD -i $VPN_IF -o eth0 -j ACCEPT
}

( while true; do
  if [ ! -e "/run/cloudflare-warp/warp_service" ]; then
    sleep 1
    continue;
  fi
  sleep 3
  warp-cli --accept-tos registration new || true

  # enable socks5
  #warp-cli --accept-tos mode proxy || true
  #warp-cli --accept-tos proxy port "1080" || true

  if ! warp-cli --accept-tos connect; then
    sleep 2
    continue
  fi

#   setup_iptables

  touch /tmp/warp-connected
  echo Warp connected!
  break
done &)

warp-svc > /dev/null 2>&1