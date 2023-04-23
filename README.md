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

- (0) Check if transferFrom on escrow withdraw works or permit needed
- (0) Events on _beforeTokenTransfer(after events), think, should do getOwnedRoyalties and depositsOf()
- (0) Get Owned but not depositted of royalties, in case you do it add this check to mint and safe transfer and safetransfer batch events
- (1) test reentrancy attack on safetransferfrom
- (1) Deploy and check if internal works as expected for withdraw
- (1) 3. check how I should change variables of playlist with owner OR if I should do it with proxy somehow
- (1) Contract proxy for upgrades, and check if gas increments
- (1) CRON don't send decimals
- (2) check if mint could be gasless, also comment the functions left in contract
- (2) check expiry date correct in permit and set up tests with current time