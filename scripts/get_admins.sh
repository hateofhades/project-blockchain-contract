#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

CONTRACT_ADDRESS=$(get_contract_address)

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Contract address missing. Deploy first."
    exit 1
fi

echo "Querying admins for contract $CONTRACT_ADDRESS"

mxpy contract query "$CONTRACT_ADDRESS" \
    --function "getAdmins" \
    --abi "$ABI_PATH" \
    --proxy "$PROXY"
