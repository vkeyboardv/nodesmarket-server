#!/bin/bash


echo -e "\033[0;32mStarting install Solana node mainnet edgevana...\033[0m"
device="/dev/nvme0n1"
if mount | grep -q "$device"; then
    echo "$device is already mounted."
    exit 1
fi
echo "Formatting $device to ext4..."
sudo mkfs.ext4 -F "$device"

if [ ! -d "/root/solana" ]; then
    sudo mkdir -p /root/solana
fi

echo "Mounting $device to /root/solana..."
sudo mount "$device" /root/solana

uuid=$(sudo blkid -s UUID -o value "$device")
if [ -z "$uuid" ]; then
    echo "Error retrieving UUID for $device."
    exit 1
fi

echo "Adding mount entry to /etc/fstab..."
echo "UUID=$uuid /root/solana ext4 defaults 0 2" | sudo tee -a /etc/fstab

sleep 3
df -h
sleep 3

SOLANA_DIR="/root/solana"
USER_HOME_DIRS=("/home/linuxuser" "/home/ubuntu" "/root")


for dir in "${USER_HOME_DIRS[@]}"; do
  if [[ -f "$dir/mainnet-validator-keypair.json" && -f "$dir/mainnet-vote-account-keypair.json" ]]; then
    cp "$dir/mainnet-validator-keypair.json" "$SOLANA_DIR/validator-keypair.json"
    cp "$dir/mainnet-vote-account-keypair.json" "$SOLANA_DIR/vote-account-keypair.json"

    if [[ "$dir" != "/root" ]]; then
      cp "$dir/.bash"* "/root/"
      cp "$dir/.pro"* "/root/"
      source /root/.bashrc
    fi

    break
  fi
done


url="https://api.mainnet-beta.solana.com"
solanaversion="1.18.15"
clusternetwork="mainnet"
apt update -y </dev/tty
# apt upgrade -y </dev/tty
apt install curl gnupg git wget -y

echo -e "\033[0;32mInstalling Solana\033[0m $solanaversion $clusternetwork"

sh -c "$(curl -sSfL https://release.solana.com/v$solanaversion/install)" && \
export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"
echo 'export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"' >> /root/.bashrc
. /root/.bashrc
solana --version
solana config set --url $url --keypair $SOLANA_DIR/validator-keypair.json

echo -e "\033[0;32mCreating SWAP...\033[0m"
SWAP_SIZE_GB=300
SWAP_NAME="/root/solana/swapfile"

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
Description=Solana main node
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
