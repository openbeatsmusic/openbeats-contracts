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

- (0) Check what happens when deposit is 0 and do a whole flow of transferFrom and depositEarnings.
- (0) Setup __ReentrancyGuard_init.
- (0) Events on _beforeTokenTransfer(after events), think, should do getOwnedRoyalties and depositsOf() events
- (0) Withdraw fees earned from escrow or send to two different account on payPlan and payFirstPlan
- (0) check expiry date correct in permit and set up tests with current time, check reentrancy
- (0) forge coverage in test, then disable. Also comment. Test all functions should be paused
- (0) Try ways of breaking the contract such as sell and then call depositEarnings lastMonthIncDeposited
- (0) In mumbai let subscription be payed and change one month should be one day for testing