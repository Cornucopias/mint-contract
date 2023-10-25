#!/usr/bin/env bash
set -e

# cli path
cli=$(cat ./scripts/data/path_to_cli.sh)

###############################################################################
###############################################################################

# check if jq is installed
if command -v jq >/dev/null 2>&1; then
    echo "JQ Is Installed"
else
    echo "Please Install JQ"
    exit 1;
fi

# check if the cbor module is installed
python3 -c "import importlib.util, sys; print('Python3 CBOR2 Is Installed') if importlib.util.find_spec('cbor2') else print('Please Install Python3 CBOR2') or sys.exit(1)"

# Check if the hot wallet exists
if [[ -e "scripts/wallets/hot-wallet/payment.vkey" ]]; then
    echo "Hot Wallet Exists"
else
    echo "Please Create The Hot Wallet"
    exit 1;
fi

###############################################################################
###############################################################################

# create directories if dont exist
mkdir -p contracts
mkdir -p hashes
mkdir -p certs

# remove old files
rm contracts/* || true
rm hashes/* || true
rm certs/* || true

# build out the entire script
echo -e "\033[1;34m\nBuilding Contracts\n\033[0m"
aiken build
# aiken build --keep-traces

###############################################################################
###############################################################################
# assume hot key wallet is in wallets folder and compile scripts
# these lines below can be commented out for a simply hardcoding of the start_info.json file
#
# hard code if required
# hot_pkh=""
#
# autofill the hot pkh
hot_pkh=$(${cli} address key-hash --payment-verification-key-file scripts/wallets/hot-wallet/payment.vkey)
variable=${hot_pkh}; jq --arg variable "$variable" '.hotKey=$variable' start_info.json > start_info-new.json
mv start_info-new.json start_info.json
###############################################################################
###############################################################################

# Convert hot key into cbor
hot=$(jq -r '.hotKey' start_info.json)
hot_cbor=$(python3 -c "import cbor2;hex_string='${hot}';data = bytes.fromhex(hex_string);encoded = cbor2.dumps(data);print(encoded.hex())")

echo -e "\033[1;33m\nConvert CIP68 Metadatum Storage Contract\033[0m"
aiken blueprint apply -o plutus.json -v cip68.params "${hot_cbor}"
aiken blueprint convert -v cip68.params > contracts/cip68_contract.plutus
${cli} transaction policyid --script-file contracts/cip68_contract.plutus > hashes/cip68.hash

# convert cip 68 hash into cbor
cip68_hash=$(cat hashes/cip68.hash)
cip68_hash_cbor=$(python3 -c "import cbor2;hex_string='${cip68_hash}';data = bytes.fromhex(hex_string);encoded = cbor2.dumps(data);print(encoded.hex())")

echo -e "\033[1;33m\nConvert CIP68 Staking Contract\033[0m"
aiken blueprint apply -o plutus.json -v staking.params "${hot_cbor}"
aiken blueprint convert -v staking.params > contracts/stake_contract.plutus
${cli} transaction policyid --script-file contracts/stake_contract.plutus > hashes/stake.hash

# create the staking certs
${cli} stake-address registration-certificate --stake-script-file contracts/stake_contract.plutus --out-file certs/stake.cert
poolId=$(jq -r '.poolId' start_info.json)
${cli} stake-address delegation-certificate --stake-script-file contracts/stake_contract.plutus --stake-pool-id ${poolId} --out-file certs/deleg.cert

# convert cip 68 hash into cbor
staking_hash=$(cat hashes/stake.hash)
staking_hash_cbor=$(python3 -c "import cbor2;hex_string='${staking_hash}';data = bytes.fromhex(hex_string);encoded = cbor2.dumps(data);print(encoded.hex())")

# Update Staking Redeemer
echo -e "\033[1;33m Updating Stake Redeemer \033[0m"
jq \
--arg stakeHash "$staking_hash" \
--arg poolId "$poolId" \
'.fields[0].fields[0].bytes=$stakeHash |
.fields[0].fields[1].bytes=$poolId' \
./scripts/data/stake/delegate-redeemer.json | sponge ./scripts/data/stake/delegate-redeemer.json

# random bit
ran=$(jq -r '.random' start_info.json)
ran_cbor=$(python3 -c "import cbor2;hex_string='${ran}';data = bytes.fromhex(hex_string);encoded = cbor2.dumps(data);print(encoded.hex())")

echo -e "\033[1;33m\nConvert Minting Contract\033[0m"
aiken blueprint apply -o plutus.json -v minter.params "${hot_cbor}"
aiken blueprint apply -o plutus.json -v minter.params "${cip68_hash_cbor}"
aiken blueprint apply -o plutus.json -v minter.params "${staking_hash_cbor}"
aiken blueprint apply -o plutus.json -v minter.params "${ran_cbor}"
aiken blueprint convert -v minter.params > contracts/mint_contract.plutus
${cli} transaction policyid --script-file contracts/mint_contract.plutus > hashes/mint.hash

# end of build
echo -e "\033[1;32m\nBuilding Complete!\033[0m"