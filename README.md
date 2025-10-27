# KipuBankV2 🏦

## Description

`KipuBank 0.2.0` is a smart contract that functions as a decentralized bank on the Ethereum network, allowing users to deposit and withdraw Ether (ETH). The contract enforces transaction limits and manages individual user balances.

Key features include:

* **Deposit Functionality**: Users can deposit ETH into a personal vault within the contract. 💰
* **Withdrawal Limits**: A maximum withdrawal amount is enforced per transaction to mitigate risk. 💸
* **Global Capacity Cap**: The total amount of ETH held by the contract is capped to prevent over-liquidation. 📊
* **Balance Tracking**: Each user's balance and transaction history are securely tracked. 📝
* **Secure ETH Handling**: It includes safe calls for ETH transfers to prevent common re-entrancy attacks. 🔒

## Contract on Sepolia Testnet

This contract has been deployed on the Sepolia testnet. You can view it and interact with it on Etherscan at the following address:
[KipuBank on Sepolia](https://sepolia.etherscan.io/address/0x2d9ded90c8b42de78ae7955674f94b147212f9da) 🔗

## Deployment Instructions

These instructions assume you are using an online IDE like Remix.

### Prerequisites

* A wallet configured with a connection to an Ethereum network (e.g., MetaMask).
* Testnet ETH (e.g., Sepolia ETH) for deployment.

### Using Remix

1. **Open Remix IDE**: Navigate to `remix.ethereum.org`.
2. **Create a New File**: Click the "+" icon to create a new file named `KipuBank.sol`.
3. **Paste the Code**: Copy and paste the provided `KipuBank.sol` contract code into the file.
4. **Compile the Contract**: Go to the "Solidity Compiler" tab. Ensure the compiler version is set to `0.8.0` or higher and click **Compile `KipuBank.sol`**.
5. **Deploy the Contract**:
    * Go to the "Deploy & Run Transactions" tab (the icon that looks like an Ethereum logo).
    * In the "Environment" dropdown, select **Injected Provider - MetaMask**. Connect your wallet to the desired network (e.g., Sepolia testnet).
    * In the "Deploy" section, you will see the `KipuBank` contract.
    * Enter the `_bankCap` value (the maximum total amount the bank can hold) in the constructor input field. For example, `50000000000000000000`,which is 50 ETH.
    * Click **Deploy** and confirm the transaction in your wallet.

## How to Interact with the Contract

After deployment, you can interact with the contract's public functions using a block explorer like Etherscan or through your development environment.

### Deposit

* **Via `Deposit()`**: Call the `Deposit` function and attach the amount of ETH you wish to send. This achieves the same result as the `receive` function.
* Try `40000000000000000` 0.04 ether

### Withdrawal

* **Function**: `Withdrawal(uint256 amount)`
* **Description**: This function allows a user to withdraw a specified `amount` of ETH from their balance. The maximum is 5 ETH per transaction.
* **Parameters**: `amount` (uint256) - The amount of ETH to withdraw in wei.
* **Example**: To withdraw 1 ETH, you would call `Withdrawal` with the value `1000000000000000000`.

### View Functions

* `GetBalance(address account)`: Check the ETH balance of any `account` within the bank.
* `GetDepositCount(address account)`: Get the total number of deposits made by a specific `account`.
* `GetWithdrawalCount(address account)`: Get the total number of withdrawals made by a specific `account`.

### Integration Guide: Frontend & Backend

For interacting with the **KipuBank** smart contract from a web application or backend service, you will need the contract's **address** and its **Application Binary Interface (ABI)**.

---

## 🔍 Get the Contract ABI

1. Go to the **KipuBank Etherscan** page 🌐  
2. Navigate to the **Contract** tab  
3. Scroll down to the **Contract ABI** section  
4. Click the **Copy** button to copy the entire ABI (a large JSON array) to your clipboard 📋  

---

## 💻 Frontend Interaction (Web3 DApp)

For browser-based applications, use a Web3 library like **Ethers.js** or **Web3.js** to connect to a user’s wallet (e.g., **MetaMask** 🦊).

### Example using Ethers.js

```javascript
// Import ethers.js
import { ethers } from "ethers";

// Your contract's address on Sepolia
const contractAddress = "0x2d9ded90c8b42de78ae7955674f94b147212f9da";

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
    const tx = await kipuBankContract.Deposit({ value: amountInWei });
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
    const balanceInWei = await kipuBankContract.GetBalance(myAddress);
    const balanceInEth = ethers.formatEther(balanceInWei);
    console.log(`Your balance is: ${balanceInEth} ETH 💰`);
  } catch (error) {
    console.error("Could not fetch balance! 😥", error);
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
const contractAddress = "0x2d9ded90c8b42de78ae7955674f94b147212f9da";

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
    const tx = await kipuBankContract.Withdrawal(amountInWei);
    await tx.wait();
    console.log("Withdrawal transaction sent! ✅ Hash:", tx.hash);
  } catch (error) {
    console.error("Withdrawal failed! 😥", error);
  }
}
```

>  
> **Note:** In the backend example, `SEPOLIA_RPC_URL` and `PRIVATE_KEY` should be stored securely as **environment variables** and **not hardcoded** into your source file. 🛡️
