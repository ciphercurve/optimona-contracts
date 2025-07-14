source .env
forge verify-contract $1 --chain-id 11155111 \
  --rpc-url $SEPOLIA_RPC_URL \
  --compiler-version 0.8.20 \
  --watch