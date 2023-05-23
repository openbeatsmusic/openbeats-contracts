-include .env

.PHONY: source .env

install :; forge install foundry-rs/forge-std --no-commit && forge install transmissions11/solmate --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit && forge install https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit && forge remappings > remappings.txt

# This is the first private key of account from from the "make anvil" command
# Example on how to run this command: "make deploy-anvil contract=MockDAI", remember to first run "make anvil"
deploy-anvil :; forge clean && forge script script/${contract}.s.sol:Deploy${contract} --rpc-url http://localhost:8545  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast -vvvv

# Example on how to run this command: "make deploy-goerli contract=MockDAI"
deploy-goerli :; forge clean && forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${GOERLI_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast -vvvv

deploy-mumbai :; forge clean && forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${MUMBAI_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${POLYGON_API_KEY} -vvvv

deploy-all :; make deploy-${network} contract=APIConsumer && make deploy-${network} contract=KeepersCounter && make deploy-${network} contract=PriceFeedConsumer && make deploy-${network} contract=VRFConsumerV2
