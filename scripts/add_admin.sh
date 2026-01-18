#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

if [ -z "$1" ]; then
    echo "Usage: $0 <wallet-index>"
    echo "Example: $0 0"
    exit 1
fi

ADMIN_PEM="$WALLETS_DIR/$1.pem"
if [ ! -f "$ADMIN_PEM" ]; then
    echo "Admin wallet not found: $ADMIN_PEM"
    exit 1
fi

ADDRESS=$(mxpy wallet convert --infile "$ADMIN_PEM" --in-format pem --out-format address-bech32 | cut -d ':' -f2 | tr -d '[:space:]')
CONTRACT_ADDRESS=$(get_contract_address)

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Contract address missing. Deploy first."
    exit 1
fi

if [ ! -f "$WALLET_PEM" ]; then
    echo "Owner wallet not found"
    exit 1
fi

echo "Adding admin wallet #$1 ($ADDRESS)"

mxpy contract call "$CONTRACT_ADDRESS" \
    --function "addAdmin" \
    --arguments "addr:$ADDRESS" \
    --pem "$WALLET_PEM" \
    --gas-limit $CALL_GAS_LIMIT \
    --proxy "$PROXY" \
    --chain "$CHAIN_ID" \
    --send
