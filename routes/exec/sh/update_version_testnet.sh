#!/bin/bash
solana_version="1.18.14"
SOLANA_DIR=/root/solana
echo -e "\033[0;32mStarting update Solana node to version $solana_version\033[0m"
current_version=$(solana --version | awk '{print $2}')
if [ "$current_version" == "$solana_version" ]; then
  echo "No need to update. Installed Solana version $current_version"
  exit 0
fi
echo "Current Solana version $current_version, updating to $solana_version."

cd $SOLANA_DIR
rm -fr solana.service
cat > solana.service <<"EOF"
[Unit]
Description=Solana TdS node
After=network.target syslog.target
StartLimitIntervalSec=0
[Service]
Type=simple
Restart=always
RestartSec=1
LimitNOFILE=1000000
LogRateLimitIntervalSec=0
Environment="SOLANA_METRICS_CONFIG=host=https://metrics.solana.com:8086,db=tds,u=testnet_write,p=c4fa841aa918bf8274e3e2a44d77568d9861b3ea"
ExecStart=/root/.local/share/solana/install/active_release/bin/solana-validator \
--entrypoint entrypoint.testnet.solana.com:8001 \
--entrypoint entrypoint2.testnet.solana.com:8001 \
--entrypoint entrypoint3.testnet.solana.com:8001 \
--expected-genesis-hash 4uhcVJyU9pJkvQyS88uRDiswHXSCkY3zQawwpjk2NsNY \
--known-validator 5D1fNXzvv5NjV1ysLjirC4WY92RNsVH18vjmcszZd8on \
--known-validator dDzy5SR3AXdYWVqbDEkVFdvSPCtS9ihF5kJkHCtXoFs \
--known-validator Ft5fbkqNa76vnsjYNwjDZUXoTWpP7VYm3mtsaQckQADN \
--known-validator eoKpUABi59aT4rR9HGS3LcMecfut9x7zJyodWWP43YQ \
--known-validator 9QxCLckBiJc783jnMvXZubK4wH86Eqqvashtrwvcsgkv \
--no-port-check \
--only-known-rpc \
--no-snapshot-fetch \
--identity /root/solana/validator-keypair.json \
--vote-account /root/solana/vote-account-keypair.json \
--ledger /root/solana/ledger \
--snapshots /root/solana/snapshots \
--limit-ledger-size 50000000 \
--dynamic-port-range 8000-8020 \
--log /root/solana/solana.log \
--full-rpc-api \
#--incremental-snapshots \
--full-snapshot-interval-slots 100000 \
--incremental-snapshot-interval-slots 4000 \
--maximum-full-snapshots-to-retain 1 \
--maximum-incremental-snapshots-to-retain 2 \
--wal-recovery-mode skip_any_corrupted_record \
--gossip-port 8001 \
--private-rpc \
--rpc-bind-address 127.0.0.1 \
--rpc-port 8899
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
ulimit -a 1000000
solana-install init $solana_version
fstrim -av
echo -e "\033[0;32mRestarting, KEEP THE WINDOW OPEN! Wait until the command finishes.\033[0m"
solana-validator --ledger /root/solana/ledger --snapshots /root/solana/snapshots wait-for-restart-window --max-delinquent-stake 5 && systemctl restart solana
