#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

if [ -z "$1" ]; then
    echo "Usage: $0 <required-approvals>
Example: $0 3"
    exit 1
fi

APPROVALS="$1"

# validate numeric and > 0
if ! [[ "$APPROVALS" =~ ^[0-9]+$ ]]; then
    echo "Error: approvals must be a positive integer"
    exit 1
fi

if [ "$APPROVALS" -eq 0 ]; then
    echo "Error: approvals must be greater than 0"
    exit 1
fi

CONTRACT_ADDRESS=$(get_contract_address)

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Contract address missing. Deploy first."
    exit 1
fi

if [ ! -f "$WALLET_PEM" ]; then
    echo "Owner wallet not found"
    exit 1
fi

echo "Setting required approvals to $APPROVALS"

mxpy contract call "$CONTRACT_ADDRESS" \
    --function "setRequiredApprovals" \
    --arguments "$APPROVALS" \
    --pem "$WALLET_PEM" \
    --gas-limit $CALL_GAS_LIMIT \
    --proxy "$PROXY" \
    --chain "$CHAIN_ID" \
    --send
