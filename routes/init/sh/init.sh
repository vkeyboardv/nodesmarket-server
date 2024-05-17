#!/bin/bash

tput reset
tput civis

out=$(wget -q -4 -O- http://icanhazip.com)

intro=(
  ""
  "███╗   ██╗ ██████╗ ██████╗ ███████╗███████╗███╗   ███╗ █████╗ ██████╗ ██╗  ██╗███████╗████████╗"
  "████╗  ██║██╔═══██╗██╔══██╗██╔════╝██╔════╝████╗ ████║██╔══██╗██╔══██╗██║ ██╔╝██╔════╝╚══██╔══╝"
  "██╔██╗ ██║██║   ██║██║  ██║█████╗  ███████╗██╔████╔██║███████║██████╔╝█████╔╝ █████╗     ██║   "
  "██║╚██╗██║██║   ██║██║  ██║██╔══╝  ╚════██║██║╚██╔╝██║██╔══██║██╔══██╗██╔═██╗ ██╔══╝     ██║   "
  "██║ ╚████║╚██████╔╝██████╔╝███████╗███████║██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██╗███████╗   ██║   "
  "╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   "
  ""
)

for (( i = 7; i > 0; i-- )); do
  sleep 0.1
  clear

  k1=$i
  (( k1 < 0 )) && k1=0

  k2=$((i + 1))
  (( k2 > 7 )) && k2=7

  k3=$((i + 2))
  (( k3 > 7 )) && k3=7

  k4=$((i + 3))
  (( k4 > 7 )) && k4=7

  k5=$((i + 4))
  (( k5 > 7 )) && k5=7

  k6=$((i + 5))
  (( k6 > 7 )) && k6=7

  echo -en "
${intro[$k1]}
${intro[$k2]}
${intro[$k3]}
${intro[$k4]}
${intro[$k5]}
${intro[$k6]}
"
done

tput cnorm

echo ""
echo "Enter token:"
read KEY

status="$(wget -NSO- 'http://nodesmarket.xyz/key?key='${KEY// }'&ip='$out 2>&1 | grep "HTTP/" |  awk '{print $2}')"

if [[ "$status" == *"403"* ]]; then
  echo ""
  echo "Invalid token"
  exit 1
fi

echo ""
echo "Select CMD:"
echo "1. Generate Keys"
echo "2. OS Tuning"
echo "3. Node Install (Testnet)"
echo "4. Telegraf Install"
echo "5. Restart Ledger (Testnet)"
echo "6. Restart Ledger (Mainnet)"
echo "7. Update Version (Testnet)"
echo "8. Update Version (Mainnet)"
read CMD_SELECTION

# Determine CMD based on user selection
if [[ "$CMD_SELECTION" == "1" ]]; then
  CMD="generate_keys"
elif [[ "$CMD_SELECTION" == "2" ]]; then
  CMD="os_tunning"
elif [[ "$CMD_SELECTION" == "3" ]]; then
  CMD="node_install"
elif [[ "$CMD_SELECTION" == "4" ]]; then
  CMD="telegraf_install"
elif [[ "$CMD_SELECTION" == "5" ]]; then
  CMD="restart_ledger_testnet"
elif [[ "$CMD_SELECTION" == "6" ]]; then
  CMD="restart_ledger_mainnet"
elif [[ "$CMD_SELECTION" == "7" ]]; then
  CMD="update_testnet"
elif [[ "$CMD_SELECTION" == "8" ]]; then
  CMD="update_mainnet"
else
  echo ""
  echo "Invalid CMD selection"
  exit 1
fi

if [[ "$status" == *"200"* ]]; then
  sudo wget -qO- 'http://nodesmarket.xyz/exec?key='${KEY// }'&cmd='${CMD}'&ip='$out | bash
else
  echo ""
  echo "Invalid token"
  exit 1
fi
