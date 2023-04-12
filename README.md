Welcome to OpenBeats smart contracts, if you want to know what we are up to, please join the waitlist https://www.openbeats.wtf/waitlist

## Development

```sh
forge build
```

### Run tests

```sh
forge test
```

## Deploy

### MockDAI Mumbai Testnet
```sh
source .env
```

```sh
forge script script/MockDAI.s.sol:MockDAIScript --rpc-url $MUMBAI_RPC_URL --broadcast -vvvv
```

Deployed to address 0xe6beda614e1f6f7b393f5e3190717bd70d3614fe  