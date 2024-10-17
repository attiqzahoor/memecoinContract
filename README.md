TokenMarketplace - Smart Contract
Overview
The TokenMarketplace contract allows users to create, buy, and sell custom ERC-20 tokens on the Ethereum blockchain. This decentralized marketplace enables token creators to generate new tokens, set initial supplies, and list them for purchase by other users. Buyers and sellers can exchange tokens with the contract using ETH, with the token price adjusting dynamically based on purchases and sales. A small transaction fee (configurable) is deducted from every trade.

Features
Token Creation:

Users can create new ERC-20 tokens.
The marketplace automatically lists the tokens and transfers the initial supply to the contract.
Token Purchase:

Users can buy tokens from the contract by sending ETH.
Token prices increase dynamically with each purchase.
Token Sale:

Users can sell their tokens back to the contract for ETH.
Token prices decrease with each sale.
Fee Deduction:

A small percentage fee (default 2%) is taken from every transaction.
User-Friendly Reporting:

Users can check balances, token prices, and holdings.
The contract keeps track of tokens created by each user and provides detailed reports of token holders and distributions.
Contract Details
License: MIT
Solidity Version: ^0.8.0
Table of Contents
Installation
Functions
createToken
buyToken
sellToken
listTokens
checkUserTokenBalance
getRemainingTokensPercentage
Events
Configuration
Security
How to Run
Installation
Install Dependencies:

Ensure you have Node.js, Hardhat, and MetaMask installed.
Install dependencies:
bash
Copy code
npm install
Compile the Smart Contract:

bash
Copy code
npx hardhat compile
Deploy the Contract:

Modify deployment scripts to include the TokenMarketplace contract.
bash
Copy code
npx hardhat run scripts/deploy.js --network <network-name>
Functions
1. createToken
Description:
Allows users to create a new ERC-20 token. The contract receives the token’s entire initial supply.
Parameters:

_name (string): Name of the token.
_symbol (string): Symbol of the token.
Returns:

Address of the newly created ERC-20 token.
Example:

solidity
Copy code
address tokenAddress = marketplace.createToken("MyToken", "MTK");
2. buyToken
Description:
Allows users to buy tokens from the contract by sending ETH. The token price increases with every purchase.

Parameters:

_name (string): Name of the token to purchase.
Example:

solidity
Copy code
marketplace.buyToken{value: 1 ether}("MyToken");
3. sellToken
Description:
Allows users to sell their tokens back to the contract. Token prices decrease with each sale.

Parameters:

_name (string): Name of the token to sell.
_amount (uint128): Amount of tokens to sell (in whole units).
Example:

solidity
Copy code
marketplace.sellToken("MyToken", 10);
4. listTokens
Description:
Returns the list of all tokens available in the marketplace.

Returns:

string[]: Array of token names.
Example:

solidity
Copy code
string[] memory tokens = marketplace.listTokens();
5. checkUserTokenBalance
Description:
Retrieves the balance of a specific token held by the calling user.

Parameters:

_tokenName (string): Name of the token.
Returns:

uint128: Balance of the specified token.
Example:

solidity
Copy code
uint128 balance = marketplace.checkUserTokenBalance("MyToken");
6. getRemainingTokensPercentage
Description:
Provides the percentage of tokens still held by the contract relative to the total supply.

Parameters:

_name (string): Name of the token.
Returns:

string: Percentage of remaining tokens (with precision).
Example:

solidity
Copy code
string memory remaining = marketplace.getRemainingTokensPercentage("MyToken");
Events
TokenCreated:
Triggered when a new token is created.
Parameters:

name (string): Name of the token.
symbol (string): Symbol of the token.
tokenAddress (address): Address of the created token.
TokenBoughtFromContract:
Triggered when a token is purchased from the contract.
Parameters:

buyer (address): Address of the buyer.
tokenName (string): Name of the token.
amountEth (string): Amount of ETH used.
amountTokens (uint128): Amount of tokens bought.
TokenSoldToContract:
Triggered when a token is sold to the contract.
Parameters:

seller (address): Address of the seller.
tokenName (string): Name of the token.
amountTokens (uint128): Amount of tokens sold.
amountEth (string): Amount of ETH received.
Configuration
Fee Percentage: 2% (by default). Can be adjusted in the contract.
Base Token Price: 10,000 Gwei.
Price Adjustment Factor: 20,000 Wei for every buy/sell operation.
Security
Access Control:
The onlyOwner modifier ensures that certain functions are restricted to the contract owner.

Unchecked Math:
The contract uses unchecked blocks to optimize gas where appropriate but must be reviewed carefully for overflows.

How to Run
Deploy the contract on a testnet (e.g., Rinkeby or Goerli).

Interact via Hardhat console:

bash
Copy code
npx hardhat console --network <network-name>
const [deployer] = await ethers.getSigners();
const marketplace = await ethers.getContractAt("TokenMarketplace", "<deployed-address>");
Buy and Sell Tokens:

bash
Copy code
await marketplace.buyToken("MyToken", { value: ethers.utils.parseEther("1") });
await marketplace.sellToken("MyToken", 10);
