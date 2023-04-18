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

### Local
```sh
source .env
```

```sh
anvil
```

```sh
forge script script/MockDAI.s.sol:MockDAIScript --rpc-url $LOCAL_RPC_URL --broadcast -vvvv
```

### MockDAI Mumbai Testnet
```sh
source .env
```

```sh
forge script script/MockDAI.s.sol:MockDAIScript --rpc-url $MUMBAI_RPC_URL --broadcast -vvvv
```

Deployed to address 0xe6beda614e1f6f7b393f5e3190717bd70d3614fe  

### TODO:

- (1) See metadata for ERC1155 and how is displayed on OpenSea
- (1) Deploy and check if internal works as expected for receiveRoyalties
- (1) balanceOfUser
- (1) Playlist tokens have 3% commission and can only be sold on my platform
- (1) receive royalties -> see argument limit for algo
- (1) check how I should change variables of playlist
- (1) check if payment token will be used for withdrawals
- (1) can there be an attack from internal contract inheritance?
- (1) add only owner to getFeesEarned
- (1) should be called mint a new playlist?
- (2) check if mint could be gasless
- (2) check expiry date correct in permit and set up tests with current time
- (2) order variables and comments
