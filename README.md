# KipuBankV2 🏦

## Description

`KipuBank 0.2.0` is a smart contract that functions as a decentralized bank on the Ethereum network, allowing users to deposit and withdraw Ether (ETH). The contract enforces transaction limits and manages individual user balances.

Key features include:

* **Deposit Functionality**: Users can deposit ETH into a personal vault within the contract. 💰
* **Withdrawal Limits**: A maximum withdrawal amount is enforced per transaction to mitigate risk. 💸
* **Global Capacity Cap**: The total amount of ETH held by the contract is capped to prevent over-liquidation. 📊
* **Balance Tracking**: Each user's balance and transaction history are securely tracked. 📝
* **Secure ETH Handling**: It includes safe calls for ETH transfers to prevent common re-entrancy attacks. 🔒
* **ETH/USD Price Tracking**: Integrates with Chainlink Oracle for real-time ETH price feeds. 📈

## Contract on Sepolia Testnet

This contract has been deployed on the Sepolia testnet. You can view it and interact with it on Etherscan at the following address:

[KipuBank on Sepolia](https://sepolia.etherscan.io/address/0x756b60e5ba46b30940d4daf3ce774417efa7f3f7) 🔗

## Deployment Instructions

These instructions assume you are using an online IDE like Remix.

### Prerequisites

* A wallet configured with a connection to an Ethereum network (e.g., MetaMask). 🦊
* Testnet ETH (e.g., Sepolia ETH) for deployment. 💎

### Using Remix

1. **Open Remix IDE**: Navigate to [remix.ethereum.org](https://remix.ethereum.org).
2. **Create New Files**: Create the following files:
   - `KipuBank.sol`
   - `BankBase.sol`
   - `Oracle.sol`
   - `IOracle.sol`
3. **Paste the Code**: Copy and paste the provided contract code into each respective file.
4. **Install OpenZeppelin**: In Remix, the OpenZeppelin contracts will be imported automatically.
5. **Compile the Contracts**: 
   - Go to the "Solidity Compiler" tab.
   - Ensure the compiler version is set to `^0.8.0`.
   - Click **Compile** for each contract.
6. **Deploy the Contracts**:
   - Go to the "Deploy & Run Transactions" tab (Ethereum logo icon).
   - In the "Environment" dropdown, select **Injected Provider - MetaMask**.
   - Connect your wallet to the **Sepolia testnet**.
   
   **Step 1: Deploy Oracle**
   - Select `Oracle` from the contract dropdown.
   - Click **Deploy** and confirm in MetaMask.
   - Copy the deployed Oracle contract address.
   
   **Step 2: Deploy KipuBank**
   - Select `KipuBank` from the contract dropdown.
   - Enter constructor parameters:
     - `_bankCap`: Maximum ETH capacity (e.g., `50000000000000000000` for 50 ETH)
     - `_oracle`: Paste the Oracle contract address from Step 1
   - Click **Deploy** and confirm the transaction in MetaMask.

## How to Interact with the Contract

After deployment, you can interact with the contract's public functions using Etherscan or your development environment.

### Deposit

* **Function**: `deposit()`
* **Description**: Call this function and attach the ETH amount you want to deposit.
* **Example**: To deposit 0.04 ETH:
  - In Remix: Set VALUE to `0.04` Ether, then click `deposit`
  - In wei: `40000000000000000`

### Withdrawal

* **Function**: `withdraw(uint256 amount)`
* **Description**: Withdraw a specified `amount` of ETH from your balance. Maximum 5 ETH per transaction.
* **Parameters**: `amount` (uint256) - The amount in wei.
* **Example**: To withdraw 1 ETH, call `withdraw(1000000000000000000)`

### View Functions

* **`getBalance(address account)`**: Check the ETH balance of any account within the bank.
* **`getDepositCount(address account)`**: Get the total number of deposits made by a specific account.
* **`getWithdrawalCount(address account)`**: Get the total number of withdrawals made by a specific account.
* **`getTotalDeposits()`**: Returns the total amount of ETH deposited in the contract.
* **`getTotalDepositsCount()`**: Returns the total number of deposit transactions across all users.
* **`getTotalWithdrawalsCount()`**: Returns the total number of withdrawal transactions across all users.
* **`getCurrentETHPrice()`**: Fetch the current ETH/USD price from the Chainlink Oracle (scaled by 1e8).
* **`balance(address account)`**: Returns a struct with both ETH balance and USD equivalent value.

## Integration Guide: Frontend & Backend

For interacting with the **KipuBank** smart contract from a web application or backend service, you will need the contract's **address** and its **Application Binary Interface (ABI)**.

---

## 🔍 Get the Contract ABI

1. Go to the **KipuBank Etherscan** page 🌐  
2. Navigate to the **Contract** tab  
3. Scroll down to the **Contract ABI** section  
4. Click the **Copy** button to copy the entire ABI (a large JSON array) to your clipboard 📋  

---

## 💻 Frontend Interaction (Web3 DApp)

For browser-based applications, use a Web3 library like **Ethers.js** or **Web3.js** to connect to a user's wallet (e.g., **MetaMask** 🦊).

### Example using Ethers.js
```javascript
// Import ethers.js
import { ethers } from "ethers";

// Your contract's address on Sepolia
const contractAddress = "0x756b60e5ba46b30940d4daf3ce774417efa7f3f7";

// Your contract's ABI (Paste the JSON array here)
const contractAbi = [...]; 

// Get the user's wallet provider and signer
const provider = new ethers.BrowserProvider(window.ethereum);
const signer = await provider.getSigner();

// Create a contract instance
const kipuBankContract = new ethers.Contract(contractAddress, contractAbi, signer);

// Example: Deposit function
async function depositEth(amountInEth) {
  try {
    const amountInWei = ethers.parseEther(amountInEth.toString());
    const tx = await kipuBankContract.deposit({ value: amountInWei });
    await tx.wait(); // Wait for the transaction to be mined
    console.log("Deposit successful! ✅ Transaction hash:", tx.hash);
  } catch (error) {
    console.error("Deposit failed! 😥", error);
  }
}

// Example: Get user balance (a read-only function)
async function getMyBalance() {
  try {
    const myAddress = await signer.getAddress();
    const balanceInWei = await kipuBankContract.getBalance(myAddress);
    const balanceInEth = ethers.formatEther(balanceInWei);
    console.log(`Your balance is: ${balanceInEth} ETH 💰`);
  } catch (error) {
    console.error("Could not fetch balance! 😥", error);
  }
}

// Example: Get ETH price in USD
async function getETHPrice() {
  try {
    const price = await kipuBankContract.getCurrentETHPrice();
    const priceInUSD = Number(price) / 1e8; // Convert from 8 decimals
    console.log(`Current ETH price: $${priceInUSD.toFixed(2)} 💵`);
  } catch (error) {
    console.error("Could not fetch ETH price! 😥", error);
  }
}

// Example: Withdraw ETH
async function withdrawEth(amountInEth) {
  try {
    const amountInWei = ethers.parseEther(amountInEth.toString());
    const tx = await kipuBankContract.withdraw(amountInWei);
    await tx.wait();
    console.log("Withdrawal successful! ✅ Transaction hash:", tx.hash);
  } catch (error) {
    console.error("Withdrawal failed! 😥", error);
  }
}
```

> ⚠️ Use this code with caution.

---

## 🛠️ Backend Interaction (Server-side)

For a backend application, you will need a **blockchain provider** (like Infura or Alchemy) and a **private key** to sign transactions.  
> 🔒 Never expose your private key in client-side code.

### Example using Ethers.js (Node.js)
```javascript
// Import ethers.js and dotenv for secure access to environment variables
require('dotenv').config();
const { ethers } = require("ethers");

// Your contract's address on Sepolia
const contractAddress = "0x756b60e5ba46b30940d4daf3ce774417efa7f3f7";

// Your contract's ABI (Paste the JSON array here)
const contractAbi = [...]; 

// Set up provider and signer
const sepoliaProvider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, sepoliaProvider);

// Create a contract instance with the wallet
const kipuBankContract = new ethers.Contract(contractAddress, contractAbi, wallet);

// Example: Withdraw function from a backend service
async function withdrawFromBackend(amountInEth) {
  try {
    const amountInWei = ethers.parseEther(amountInEth.toString());
    const tx = await kipuBankContract.withdraw(amountInWei);
    await tx.wait();
    console.log("Withdrawal transaction sent! ✅ Hash:", tx.hash);
  } catch (error) {
    console.error("Withdrawal failed! 😥", error);
  }
}

// Example: Get total deposits
async function getTotalDeposits() {
  try {
    const totalWei = await kipuBankContract.getTotalDeposits();
    const totalEth = ethers.formatEther(totalWei);
    console.log(`Total deposits: ${totalEth} ETH 📊`);
  } catch (error) {
    console.error("Could not fetch total deposits! 😥", error);
  }
}
```

> **Note:** In the backend example, `SEPOLIA_RPC_URL` and `PRIVATE_KEY` should be stored securely as **environment variables** and **not hardcoded** into your source file. 🛡️

---

## 📊 Contract Architecture

**KipuBank** is built with a modular architecture:

- **`KipuBank.sol`**: Main contract handling deposits and withdrawals
- **`BankBase.sol`**: Abstract base contract with core banking logic
- **`Oracle.sol`**: Chainlink price feed integration for ETH/USD prices
- **`IOracle.sol`**: Interface defining oracle contract structure

---

## 🔐 Security Features

- ✅ **Reentrancy Protection**: Safe ETH transfer patterns
- ✅ **Access Control**: Ownable pattern for administrative functions
- ✅ **Input Validation**: Zero amount checks and balance validations
- ✅ **Withdrawal Limits**: Maximum 5 ETH per transaction
- ✅ **Capacity Controls**: Global bank cap to prevent over-deposits

---

## 📝 License

This project is licensed under the MIT License.

---

## 👩‍💻 Author

**Carla Montani**

---

## 🆘 Support

For questions or issues, please check the contract on [Etherscan](https://sepolia.etherscan.io/address/0x756b60e5ba46b30940d4daf3ce774417efa7f3f7) or review the contract source code.
