#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

if [ -z "$1" ]; then
    echo "Usage: $0 <version> [wallet-index]
Examples:
  $0 1.2.3      # uses owner wallet
  $0 1.2.3 0    # uses admin wallet #0"
    exit 1
fi

VERSION="$1"
IDX="$2"

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
    echo "Using owner wallet to approve release"
else
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
    echo "Using admin wallet #$IDX to approve release"
fi

echo "Approving release version=$VERSION"

mxpy contract call "$CONTRACT_ADDRESS" \
    --function "approveRelease" \
    --arguments "str:$VERSION" \
    --pem "$SIGNER_PEM" \
    --gas-limit $CALL_GAS_LIMIT \
    --proxy "$PROXY" \
    --chain "$CHAIN_ID" \
    --send
