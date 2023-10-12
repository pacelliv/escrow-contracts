-include .env

.PHONY: format format-fix compile deploy test-forge test-escrow test-factory clean

# Variables:
VERBOSITY ?=
TEST ?=
GREP ?=
TAGS ?=

# Formatting commands:
format-check :; npx prettier --check '**/**/*.{ts,json}' 'src/**/*.sol' 'test-forge/**/*.sol'
format-fix :; npx prettier --write '**/**/*.ts' 'src/**/*.sol' 'test-forge/**/*.sol'

# Clean cache and artifacts:
clean :; yarn hardhat clean

# Compile command:
build :; yarn hardhat compile

# Deploy commands:
deploy:
ifdef network
	yarn hardhat deploy --network $(network)
else
	yarn hardhat deploy 
endif

# Launch Hardhat's local chain:
chain :; yarn hardhat node

# Test commands:
test-forge :; forge test $(VERBOSITY) $(TEST)
test-hardhat :; yarn hardhat test test/unit/escrow_factory.t.ts test/unit/erc20_escrow.t.ts test/unit/native_escrow.t.ts $(GREP) $(TEST)