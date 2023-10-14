## Week 5 project - Escrow Contract 📑

### ⚡️⚡️ [Live Demo](escrow-frontend-gamma.vercel.app/)

### Introduction 👩‍🏫👨‍🏫

From [Wikipedia](https://en.wikipedia.org/wiki/Escrow):

> An escrow is a contractual arrangement in which a third party (the stakeholder or escrow agent) receives and disburses money or property for the primary transacting parties, with the disbursement dependent on conditions agreed to by the transacting parties.

Transactions between parties are commonplace and occur regularly, whether it's for transferring ownership of property or acquiring services. However, trust issues often plague such transactions. For instance, when a person intends to purchase a vehicle from a dealership, both parties might harbor doubts; the buyer may be unable to trust or verify whether the vehicle matches the advertised conditions or specifications by the seller, while the seller may question the buyer's financial capacity to afford the purchase. Escrow contracts emerge as a solution to instill trust in transactions that lacks it.

In the situation from above if the transactional parties establish a escrow contract, first the seller would allow the buyer to inspect the vehichle to verify the conditions of it. If the verification the satisfy the buyer, he/she will notify the escrow agent to release the locked funds to the seller to complete the purchase of the vehicle. If the vehicle does not match the advertised condition then the escrow agent won't transfer the funds to the seller and they will be returned to the buyer.

In theory, this arrangement appears highly beneficial, but in practice, the behavior of the escrow agent may not always meet expectations. Instances abound where judges or arbitrators can be influenced or where their interpretation of the contract leads to decisions that are not impartial.

If we leverage the immutable nature of smart contracts we can completely replace the figure of the escrow agent with code or with a Decentralized Autonomous Organization (DAO) to increase the level of trust between the transactional parties.

### Overview 🌌

Two contract were created to handle playments in different tokens.

- ERC20Escrow: holds and disimburses payment in the form on ERC20 tokens.
- NativeEscrow: holds and disimburses payment in the form on native coins.

After the creation of a new escrow with the funds in it, the grantee (seller) will have a period of time to fulfill his side of the agreement, if the he/she does before the escrow expires then the grantor (buyer) confirms the receipt and the funds are sent to the grantee.

If the time expires and the grantee has not fulfilled his side of the agreement then the grantor is allowed to withdraw the escrowed funds.

In the case of a disagreement by the either of the transactional parties, either one can start a dispute which will call the arbiter to review the contractual agreements and decide the distribution of locked funds, to resolve the dispute.

A factory pattern (`EscrowFactory`) was created to deploy the escrow contracts using the `CREATE2` opcode.

### Quick Start 🏃‍♀️🏃

To install the dependencies run:

```bash
npm install
# or
yarn install
```

### Running the contracts 👩‍💻👨‍💻

You're going to need the following enviroment variables, create a `.env` file with the following content:

```bash
SEPOLIA_RPC_URL=xxxx
PRIVATE_KEY_A=xxxx
PRIVATE_KEY_B=xxxx
PRIVATE_KEY_C=xxxx
ETHERSCAN_API_KEY=xxxx
COINMARKETCAP_API_KEY=xxxx
REPORT_GAS=xxxx
```

`SEPOLIA_RPC_URL`: an endpoint to interact with the blockchain. Get one for free from [Alchemy](https://www.alchemy.com/).

`ETHERSCA_API_KEY`: If you deploy your contracts to a testnet or mainnet, you will need a API key to verify them. Get one for free from [Etherscan](https://etherscan.io/login?cmd=last). The deploy scripts will auto verify your contracts.

Import three private keys from Metamask. I highly encourage using wallets that are not associated with real funds.

`COINMARKETCAP_API_KEY`: To get an USD estimation of gas cost, you'll need a COINMARKETCAP_API_KEY environment variable. You can get one for free from [CoinMarketCap](https://pro.coinmarketcap.com/login?returnUrl=%2Faccount).

`REPORT_GAS`: to enable gas reports from the `hardhat-gas-reporter` plugin. The variables can be either `true` or `false`.

Replace the values of the keys in the `.env` file. A `.env.example` file is provided for reference.

#### Compile
```bash
make build
```

#### Deploy
```bash
# to deploy locally
make deploy

# to deploy to a tesnet or mainnet
make deploy network=network_name
```

#### Test
```bash
# runs unit test using Mocha
make test-hardhat

# run fuzz test using Foundry
make test-forge
```

### Run tasks 👩‍💻👨‍💻

Check the `tasks` subdirectory to see the task. Use `npx hardhat help task_name` to see more information about the task.

Tasks can be used on a testnet o the local node.

```bash
make chain
```

### Formatting:

```bash
make format-check
make format-fix
```

### Resources 📚
- [Hardhat docs](https://hardhat.org/docs)
- [ERC-20](https://docs.openzeppelin.com/contracts/2.x/api/token/erc20)
- [Ethers v6](https://docs.ethers.org/v6/)
- [CREATE2](https://docs.openzeppelin.com/cli/2.8/deploying-with-create2)