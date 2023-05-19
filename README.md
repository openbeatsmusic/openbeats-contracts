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

- (0) Check what happens when deposit is 0
- (0) Setup __ReentrancyGuard_init and then Try ways of breaking the contract such as sell and then call depositEarnings lastMonthIncDeposited
- (0) check expiry date correct in permit and set up tests with current time
- (0) forge coverage in test, then disable. Also comment. Test all functions should be paused
- (0) In mumbai let subscription be payed and change one month should be one day for testing