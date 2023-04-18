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

Deployed to address 0xe6beda614e1f6f7b393f5e3190717bd70d3614fe  

### TODO:

- (1) See metadata for ERC1155 and how is displayed on OpenSea
- (1) Deploy and check if internal works as expected for receiveRoyalties
- (1) balanceOfUser
- (1) check how I should change variables of playlist
- (1) check if payment token will be used for withdrawals
- (1) can there be an attack from internal contract inheritance?
- (1) add only owner to getFeesEarned
- (1) should be called mint a new playlist?
- (1) etherscan api key in deployments -> example -> deploy-sepolia :; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${SEPOLIA_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}  -vvvv
- (2) check if mint could be gasless
- (2) check expiry date correct in permit and set up tests with current time
- (2) order variables and comments
- (2) Deploy on same vanity address https://0xfoobar.substack.com/p/vanity-addresses?nthPub=22&profile-setup-message=post-subscribe-prompt
