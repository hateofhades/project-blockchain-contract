#!/bin/bash

source "$(dirname "$0")/config.sh"
cd "$(dirname "$0")"

if [ -z "$1" ]; then
    echo "Usage: $0 <version>
Example: $0 1.2.3"
    exit 1
fi

VERSION="$1"
CONTRACT_ADDRESS=$(get_contract_address)

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Contract address missing. Deploy first."
    exit 1
fi

echo "Querying release '$VERSION' for contract $CONTRACT_ADDRESS"

mxpy contract query "$CONTRACT_ADDRESS" \
    --function "getRelease" \
    --arguments "str:$VERSION" \
    --abi "$ABI_PATH" \
    --proxy "$PROXY"
