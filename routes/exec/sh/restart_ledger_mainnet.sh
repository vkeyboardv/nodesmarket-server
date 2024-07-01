#!/bin/bash

SOLANA_DIR=/root/solana
echo -e "\033[0;32mRestarting, KEEP THE WINDOW OPEN! Wait until the command finishes.\033[0m"

cd $SOLANA_DIR
rm -fr solana.service
cat > /etc/systemd/system/solana.service <<"EOF"
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
Environment="SOLANA_METRICS_CONFIG=host=https://metrics.solana.com:8086,db=mainnet-beta,u=mainnet-beta_write,p=password"
ExecStart=/root/.local/share/solana/install/active_release/bin/solana-validator \
--entrypoint entrypoint.mainnet-beta.solana.com:8001 \
--entrypoint entrypoint2.mainnet-beta.solana.com:8001 \
--entrypoint entrypoint3.mainnet-beta.solana.com:8001 \
--entrypoint entrypoint4.mainnet-beta.solana.com:8001 \
--entrypoint entrypoint5.mainnet-beta.solana.com:8001 \
--expected-genesis-hash 5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d \
--known-validator 7Np41oeYqPefeNQEHSv1UDhYrehxin3NStELsSKCT4K2 \
--known-validator GdnSyH3YtwcxFvQrVVJMm1JhTS4QVX7MFsX56uJLUfiZ \
--known-validator DE1bawNcRJB9rVm3buyMVfr8mBEoyyu73NBovf2oXJsJ \
--known-validator CakcnaRDHka2gXyfbEd2d3xsvkJkqsLw2akB3zsN1D2S \
--no-port-check \
--only-known-rpc \
#--no-snapshot-fetch \
--use-snapshot-archives-at-startup when-newest \
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
echo -e "\033[0;32mStopping solana\033[0m"
systemctl stop solana
echo -e "\033[0;32mDeleting ledger\033[0m"
rm -rf /root/solana/ledger
fstrim -av
echo -e "\033[0;32mStatring solana\033[0m"
