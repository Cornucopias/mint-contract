#!/usr/bin/env bash
set -e

export CARDANO_NODE_SOCKET_PATH=$(cat ../data/path_to_socket.sh)
cli=$(cat ../data/path_to_cli.sh)
testnet_magic=$(cat ../data/testnet.magic)

# get params
${cli} query protocol-parameters --testnet-magic ${testnet_magic} --out-file ../tmp/protocol.json

# cip 68 contract
cip68_script_path="../../contracts/cip68_contract.plutus"
cip68_script_address=$(${cli} address build --payment-script-file ${cip68_script_path} --testnet-magic ${testnet_magic})

#
hot_pkh=$(${cli} address key-hash --payment-verification-key-file ../wallets/hot-wallet/payment.vkey)

#
collat_address=$(cat ../wallets/collat-wallet/payment.addr)
collat_pkh=$(${cli} address key-hash --payment-verification-key-file ../wallets/collat-wallet/payment.vkey)

#
receiver_address=$(cat ../wallets/receiver-wallet/payment.addr)
receiver_pkh=$(${cli} address key-hash --payment-verification-key-file ../wallets/receiver-wallet/payment.vkey)

# the minting script policy
policy_id=$(cat ../../hashes/mint.hash)

echo -e "\033[0;36m Gathering Payer UTxO Information  \033[0m"
${cli} query utxo \
    --testnet-magic ${testnet_magic} \
    --address ${receiver_address} \
    --out-file ../tmp/receiver_utxo.json

TXNS=$(jq length ../tmp/receiver_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${receiver_address} \033[0m \n";
   exit;
fi
alltxin=""
TXIN=$(jq -r --arg alltxin "" 'keys[] | . + $alltxin + " --tx-in"' ../tmp/receiver_utxo.json)
receiver_tx_in=${TXIN::-8}

echo "Payer UTxO:" $receiver_tx_in
first_utxo=$(jq -r 'keys[0]' ../tmp/receiver_utxo.json)
string=${first_utxo}
IFS='#' read -ra array <<< "$string"

prefix_100="2831303029"
prefix_222="2832323229"

ref_name=$(python3 -c "import sys; sys.path.append('../py/'); from get_token_name import token_name; token_name('${array[0]}', ${array[1]}, '${prefix_100}')")
nft_name=$(python3 -c "import sys; sys.path.append('../py/'); from get_token_name import token_name; token_name('${array[0]}', ${array[1]}, '${prefix_222}')")

echo -n $ref_name > ../tmp/ref.token
echo -n $nft_name > ../tmp/nft.token

# The assets that are being mints
REF_ASSET="1 ${policy_id}.${ref_name}"
NFT_ASSET="1 ${policy_id}.${nft_name}"

# total mint asset
MINT_ASSET="1 ${policy_id}.${ref_name} + 1 ${policy_id}.${nft_name}"

# reference min ada
UTXO_VALUE=$(${cli} transaction calculate-min-required-utxo \
    --babbage-era \
    --protocol-params-file ../tmp/protocol.json \
    --tx-out-inline-datum-file ../data/cip68/metadata-datum.json \
    --tx-out="${cip68_script_address} + 5000000 + ${REF_ASSET}" | tr -dc '0-9')
reference_address_out="${cip68_script_address} + ${UTXO_VALUE} + ${REF_ASSET}"

# nft min ada
UTXO_VALUE=$(${cli} transaction calculate-min-required-utxo \
    --babbage-era \
    --protocol-params-file ../tmp/protocol.json \
    --tx-out="${receiver_address} + 5000000 + ${NFT_ASSET}" | tr -dc '0-9')

receiver_address_out="${receiver_address} + ${UTXO_VALUE} + ${NFT_ASSET}"

echo "Ref Mint OUTPUT:" ${reference_address_out}
echo "Nft Mint OUTPUT:" ${receiver_address_out}
#
# exit
#
echo -e "\033[0;36m Gathering Collateral UTxO Information  \033[0m"
${cli} query utxo \
    --testnet-magic ${testnet_magic} \
    --address ${collat_address} \
    --out-file ../tmp/collat_utxo.json
TXNS=$(jq length ../tmp/collat_utxo.json)
if [ "${TXNS}" -eq "0" ]; then
   echo -e "\n \033[0;31m NO UTxOs Found At ${collat_address} \033[0m \n";
   exit;
fi
collat_utxo=$(jq -r 'keys[0]' ../tmp/collat_utxo.json)

script_ref_utxo=$(${cli} transaction txid --tx-file ../tmp/mint-reference-utxo.signed)

# Add metadata to this build function for nfts with data
echo -e "\033[0;36m Building Tx \033[0m"
FEE=$(${cli} transaction build \
    --babbage-era \
    --out-file ../tmp/tx.draft \
    --change-address ${receiver_address} \
    --tx-in ${receiver_tx_in} \
    --tx-in-collateral="${collat_utxo}" \
    --tx-out="${reference_address_out}" \
    --tx-out-inline-datum-file ../data/cip68/metadata-datum.json \
    --tx-out="${receiver_address_out}" \
    --required-signer-hash ${receiver_pkh} \
    --required-signer-hash ${collat_pkh} \
    --required-signer-hash ${hot_pkh} \
    --mint="${MINT_ASSET}" \
    --mint-tx-in-reference="${script_ref_utxo}#1" \
    --mint-plutus-script-v2 \
    --policy-id="${policy_id}" \
    --mint-reference-tx-in-redeemer-file ../data/mint/mint-redeemer.json \
    --testnet-magic ${testnet_magic})

IFS=':' read -ra VALUE <<< "${FEE}"
IFS=' ' read -ra FEE <<< "${VALUE[1]}"
FEE=${FEE[1]}
echo -e "\033[1;32m Fee: \033[0m" $FEE
#
# exit
#
echo -e "\033[0;36m Signing \033[0m"
${cli} transaction sign \
    --signing-key-file ../wallets/hot-wallet/payment.skey \
    --signing-key-file ../wallets/collat-wallet/payment.skey \
    --signing-key-file ../wallets/receiver-wallet/payment.skey \
    --tx-body-file ../tmp/tx.draft \
    --out-file ../tmp/tx.signed \
    --testnet-magic ${testnet_magic}
#    
# exit
#
echo -e "\033[0;36m Submitting \033[0m"
${cli} transaction submit \
    --testnet-magic ${testnet_magic} \
    --tx-file ../tmp/tx.signed

tx=$(cardano-cli transaction txid --tx-file ../tmp/tx.signed)
echo "Tx Hash:" $tx