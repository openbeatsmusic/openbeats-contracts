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

- (0) Forge coverage and comment functions. Check which fuzz testing, different variables, can be done in tests. Check if doing invariant. Use ffi to reproduce real payments. 
- (0) Setup __ReentrancyGuard_init and Check if transferFrom on escrow withdraw works or permit needed. First do deposit
- (0) Events on _beforeTokenTransfer(after events), think, should do getOwnedRoyalties and depositsOf()
- (0) Get Owned but not depositted of royalties, in case you do it add this check to mint and safe transfer and safetransfer batch events
- (0) check expiry date correct in permit and set up tests with current time, check reentrancy