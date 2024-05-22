#!/bin/bash

echo -e "\033[0;32mStarting install Solana node testnet...\033[0m"
SOLANA_DIR=/root/solana
mkdir -p $SOLANA_DIR
source /root/.bashrc
cp /root/testnet-validator-keypair.json /root/solana/validator-keypair.json
cp /root/testnet-vote-account-keypair.json /root/solana/vote-account-keypair.json
cp /root/testnet-withdrawer-keypair.json /root/solana/withdrawer-keypair.json
url="https://api.testnet.solana.com"
solanaversion="1.18.14"
clusternetwork="testnet"
apt update -y && apt upgrade -y && apt install curl gnupg git wget -y


echo -e "\033[0;32mInstalling Solana\033[0m $solanaversion $clusternetwork"

sh -c "$(curl -sSfL https://release.solana.com/v$solanaversion/install)" && \
export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"
echo 'export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"' >> /root/.bashrc
. /root/.bashrc
solana --version
solana config set --url $url --keypair $SOLANA_DIR/validator-keypair.json

echo -e "\033[0;32mCreating SWAP...\033[0m"
SWAP_SIZE_GB=300
SWAP_NAME="/swapfile"

CURRENT_SWAP_NAME=$(sudo swapon --show | awk 'NR==2{print $1}')
CURRENT_SWAP_SIZE=$(sudo swapon --show --bytes | awk 'NR==2{print $3}' | sed 's/[a-zA-Z]//g' | awk '{ byte =$1 /1024/1024; print byte }')
echo  $CURRENT_SWAP_SIZE
if [ -n "$CURRENT_SWAP_NAME" ]; then
    CURRENT_SWAP_SIZE_GB=$(($CURRENT_SWAP_SIZE / 1024))
else
    CURRENT_SWAP_SIZE_GB=0
fi
if [[ -n "$CURRENT_SWAP_NAME" && "$CURRENT_SWAP_SIZE_GB" -ge "$SWAP_SIZE_GB" ]]; then
    echo "Swap ${CURRENT_SWAP_NAME}  ${CURRENT_SWAP_SIZE_GB}G is already exist!"
else
    if [[ -n "$CURRENT_SWAP_NAME" && "$CURRENT_SWAP_SIZE_GB" -lt "$SWAP_SIZE_GB" ]]; then
        echo "Deleting old swap ${CURRENT_SWAP_NAME}   ${CURRENT_SWAP_SIZE_GB}G"
        sudo swapoff "$CURRENT_SWAP_NAME"
        sudo sed -i "${CURRENT_SWAP_NAME}/d" /etc/fstab
        sudo rm -f "$CURRENT_SWAP_NAME"
    fi

    echo "Creating new swap ${SWAP_SIZE_GB}G"
    sudo dd if=/dev/zero of=$SWAP_NAME bs=1G count=$SWAP_SIZE_GB
    sudo chmod 600 $SWAP_NAME
    sudo mkswap $SWAP_NAME

    echo "Mounting swap"
    sudo swapon $SWAP_NAME

    if ! grep -q "swapfile" /etc/fstab; then
        echo "${SWAP_NAME} none swap sw 0 0" | sudo tee -a /etc/fstab
    fi
fi

sysctl vm.swappiness=10

if grep -q "^vm.swappiness" /etc/sysctl.conf; then
    sed -i "s/^vm.swappiness.*/vm.swappiness=10/" /etc/sysctl.conf
else
    echo "vm.swappiness=10" >> /etc/sysctl.conf
fi


echo -e "\033[0;32mCreating service files...\033[0m"

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
#--no-snapshot-fetch \
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

cat > $SOLANA_DIR/solana.logrotate <<EOF
$SOLANA_DIR/solana.log {
  rotate 7
  daily
  missingok
  postrotate
    systemctl kill -s USR1 solana.service
  endscript
}
EOF


echo -e "\033[0;32mCreating symbolic links...\033[0m"
sudo ln -s $SOLANA_DIR/solana.service /etc/systemd/system
sudo ln -s $SOLANA_DIR/solana.logrotate /etc/logrotate.d/
systemctl daemon-reload
sudo systemctl enable $SOLANA_DIR/solana.service

systemctl start solana

echo "### Install is complete."
echo "### Server name: $VALIDATOR_NAME"
echo "### Cluster: $clusternetwork"
echo "### You identity pubkey: $(solana address)"
echo "### You vote pubkey: $(solana-keygen pubkey $SOLANA_DIR/vote-account-keypair.json)"
echo "### You balance: $(solana balance)"
exit 0
