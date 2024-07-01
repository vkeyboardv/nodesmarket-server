#!/bin/bash

apt update && sudo apt upgrade -y

if exists curl; then
        echo ''
else
  sudo apt install curl -y < "/dev/null"
fi

SOLANA_DIR=/root/solana

mkdir -p $SOLANA_DIR
echo -e "\033[0;32mInstalling Solana tools...\033[0m"

sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env
rustup update stable --force
cd $HOME

apt install -y build-essential clang libudev-dev pkg-config libhidapi-dev librust-openssl-sys-dev librocksdb-dev libssl-dev libudev-dev pkg-config zlib1g-dev llvm

sh -c "$(curl -sSfL https://release.solana.com/v1.18.17/install)"
export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"
echo 'export PATH="/root/.local/share/solana/install/active_release/bin:$PATH"' >> /root/.bashrc
source /root/.bashrc
echo -e "\033[0;32mSolana cli installed\033[0m"
solana --version

cargo install solana-foundation-delegation-program-cli
echo -e "\033[0;32msolana-foundation-delegation-program installed\033[0m"
solana-foundation-delegation-program --version

echo -e "\033[0;32mCreating testnet-validator-keypair.json ...\033[0m"
# solana-keygen new -o testnet-validator-keypair.json
solana-keygen new --no-bip39-passphrase -o $SOLANA_DIR/testnet-validator-keypair.json
echo -e "\033[0;31m!!!!!!!!!!!!Save this information in a secure place.!!!!!!!!!!!\033[0m"
echo -e "\033[0;32mPress any key to continue\033[0m"
read -rsn1 variable </dev/tty

echo -e "\033[0;32mCreating mainnet-validator-keypair.json ...\033[0m"
solana-keygen new --no-bip39-passphrase -o $SOLANA_DIR/mainnet-validator-keypair.json
echo -e "\033[0;31m!!!!!!!!!!!!Save this information in a secure place.!!!!!!!!!!!\033[0m"
echo -e "\033[0;32mPress any key to continue\033[0m"
read -rsn1 variable </dev/tty


echo -e "\033[0;32m Your testnet address testnet-validator-keypair.json is:  \033[0m"
solana address -k $SOLANA_DIR/testnet-validator-keypair.json

echo -e "===================================================================="
echo -e "\033[0;32m Your mainnet address mainnet-validator-keypair.json is:  \033[0m"
solana address -k $SOLANA_DIR/mainnet-validator-keypair.json
echo -e "===================================================================="
echo -e "\033[0;32mYou can find your keys in this directory:  \033[0m $SOLANA_DIR"

echo -e "\033[0;32msolana-foundation-delegation-program installed\033[0m"
solana-foundation-delegation-program --version
echo -e "\033[0;32mSolana cli installed\033[0m"
solana --version
echo -e "===================================================================="
echo -e "\033[0;31mAttention!!! You need to re-login to the server or execute this command:\033[0m"
echo -e "\033[0;33msource /root/.bashrc\033[0m"
