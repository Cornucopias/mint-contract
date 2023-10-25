#!/usr/bin/env bash
set -e

# SET UP VARS HERE
source .env

# cip 68 contract
cip68_script_path="../contracts/cip68_contract.plutus"
stake_script_path="../contracts/stake_contract.plutus"
cip68_script_address=$(${cli} address build --payment-script-file ${cip68_script_path} --stake-script-file ${stake_script_path} ${network})

# get current parameters
mkdir -p ./tmp
${cli} query protocol-parameters ${network} --out-file ./tmp/protocol.json
${cli} query tip ${network} | jq

# metadatum
echo -e "\033[1;35m Metadatum Contract Address: \033[0m" 
echo -e "\n \033[1;35m ${cip68_script_address} \033[0m \n";
${cli} query utxo --address ${cip68_script_address} ${network}
${cli} query utxo --address ${cip68_script_address} ${network} --out-file ./tmp/current_metadata.utxo

#
# Loop through each -wallet folder
for wallet_folder in wallets/*-wallet; do
    # Check if payment.addr file exists in the folder
    if [ -f "${wallet_folder}/payment.addr" ]; then
        ${cli} address build --payment-verification-key-file ${wallet_folder}/payment.vkey --out-file ${wallet_folder}/payment.addr ${network}
        addr=$(cat ${wallet_folder}/payment.addr)
        echo
        echo -e "\033[1;34m $wallet_folder $addr \033[0m"
        echo -e "\033[1;33m"
        # Run the cardano-cli command with the reference address and testnet magic
        ${cli} query utxo --address ${addr} ${network}
        ${cli} query utxo --address ${addr} ${network} --out-file ./tmp/"${addr}.json"
        echo -e "\033[0m"
    fi
done
