#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

if [ $# -lt 3 ]; then
    echo "Usage: $0 <version> <hash> <url> [wallet-index]
Examples:
  $0 1.2.3 deadbeef https://example.com/firmware.bin    # uses owner wallet
  $0 1.2.3 deadbeef https://example.com/firmware.bin 0  # uses admin wallet #0"
    exit 1
fi

VERSION="$1"
HASH="$2"
URL="$3"
IDX="$4"

CONTRACT_ADDRESS=$(get_contract_address)

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Contract address missing. Deploy first."
    exit 1
fi

if [ -z "$IDX" ]; then
    # use owner
    if [ ! -f "$WALLET_PEM" ]; then
        echo "Owner wallet not found: $WALLET_PEM"
        exit 1
    fi
    SIGNER_PEM="$WALLET_PEM"
    echo "Using owner wallet to propose release"
else
    # validate numeric
    if ! [[ "$IDX" =~ ^[0-9]+$ ]]; then
        echo "Error: wallet-index must be an integer"
        exit 1
    fi
    ADMIN_PEM="$WALLETS_DIR/$IDX.pem"
    if [ ! -f "$ADMIN_PEM" ]; then
        echo "Admin wallet not found: $ADMIN_PEM"
        exit 1
    fi
    SIGNER_PEM="$ADMIN_PEM"
    echo "Using admin wallet #$IDX to propose release"
fi

echo "Proposing release version=$VERSION hash=$HASH url=$URL"

mxpy contract call "$CONTRACT_ADDRESS" \
    --function "proposeRelease" \
    --arguments "str:$VERSION" "str:$HASH" "str:$URL" \
    --pem "$SIGNER_PEM" \
    --gas-limit $CALL_GAS_LIMIT \
    --proxy "$PROXY" \
    --chain "$CHAIN_ID" \
    --send
