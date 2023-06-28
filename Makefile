-include .env

#Deploys the DeployFundMe contract on Sepolia
deploy-sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

#Shows how much of the code is covered by tests
coverage:
	forge coverage


#Deploys the DeployFundMe contract on Foundry's makeshift testnet
deploy-foundry:
	forge script script/DeployFundMe.s.sol:DeployFundMe

#Updates dependencies in Foundry
update:
	forge update

#runs all tests
test:
	forge test

#runs tests and provides gas values for each function tested
snapshot:
	forge snapshot

test function:
	forge test --mt