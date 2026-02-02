# 🏦 TrancheVault Protocol

**TrancheVault** is a structured DeFi yield protocol built using the **ERC-4626 Tokenized Vault Standard**.  
It allows users to deposit assets into a vault that allocates capital across multiple yield strategies while offering **risk-segmented tranches** (Senior & Junior).

This project demonstrates advanced **DeFi protocol engineering**, including:

- ERC-4626 vault mechanics
- Multi-strategy yield routing
- Structured finance tranching (waterfall model)
- Aave integration for real yield
- Full-stack Web3 dApp (Next.js + Ethers)

---

## 🚀 Overview

Users deposit USDC into the protocol and choose between two risk tranches:

| Tranche   | Risk Level  | Return Profile                       |
| --------- | ----------- | ------------------------------------ |
| 🟦 Senior | Lower Risk  | Stable, protected yield              |
| 🟥 Junior | Higher Risk | Higher returns, absorbs losses first |

Funds are pooled into a central ERC-4626 vault and deployed into yield-generating strategies such as **Aave lending markets**.

Profits and losses are distributed through a **waterfall accounting model**, inspired by structured finance systems.

---

## 🎯 Scope of the Project

### Core Features

- ERC-4626 compliant yield vault
- Strategy router supporting multiple strategies
- Aave yield integration
- Senior & Junior tranche system
- Profit and loss waterfall distribution
- Full frontend for deposits and withdrawals
- Deployment on Arbitrum Sepolia testnet

### Out of Scope (Future Work)

- Governance
- Dynamic strategy rebalancing
- On-chain price oracles
- Advanced Uniswap V3 LP management

---

## 🏗 Protocol Architecture

User
│
▼
SeniorVault / JuniorVault (Tranche Tokens)
│
▼
TrancheManager (Risk & Accounting Logic)
│
▼
Main ERC4626 Vault
│
▼
Strategy Router
│
▼
Aave Strategy (Yield Source)

---

## 💰 Capital Flow

### Deposit Flow

User deposits USDC
│
▼
Chooses Senior or Junior tranche
│
▼
Receives tranche shares (svUSDC / jvUSDC)
│
▼
Funds routed to Main Vault
│
▼
Vault allocates capital to strategies

---

### Yield Flow

Strategies earn yield
│
▼
Vault totalAssets increases
│
▼
Share price increases
│
▼
User position value grows automatically

---

### Withdrawal Flow

User redeems tranche shares
│
▼
TrancheManager calculates owed assets
│
▼
Vault withdraws funds from strategies
│
▼
USDC sent back to user

---

## ⚖️ Tranche Waterfall Model

### Profit Distribution

Vault earns profit
│
▼
Senior tranche receives fixed/stable portion
│
▼
Junior tranche receives remaining excess profit

### Loss Distribution

Vault incurs loss
│
▼
Junior tranche absorbs losses first
│
▼
Senior tranche affected only if losses exceed junior capital

This creates a **risk hierarchy** where Senior is protected and Junior is leveraged.

---

## 📜 Smart Contracts

| Contract             | Responsibility                       |
| -------------------- | ------------------------------------ |
| BaseVault.sol        | ERC-4626 vault holding pooled assets |
| StrategyRouter.sol   | Allocates funds across strategies    |
| AaveStrategy.sol     | Supplies capital to Aave             |
| TrancheManager.sol   | Handles profit/loss distribution     |
| SeniorVaultToken.sol | ERC20 share token for Senior tranche |
| JuniorVaultToken.sol | ERC20 share token for Junior tranche |

---

## 🧪 Testing

Testing is done using **Foundry**.

Key test scenarios:

- Deposits and withdrawals
- Share price growth with yield
- Profit distribution between tranches
- Loss waterfall logic
- Invariant: `seniorAssets + juniorAssets == vaultTotalAssets`

Run tests:

```bash
forge test
🌐 Frontend
Built with:

Next.js

Ethers.js

Wagmi

Frontend features:

Wallet connection

Deposit into Senior/Junior tranche

Withdraw funds

Vault statistics dashboard

🚀 Deployment
Network: Arbitrum Sepolia

Contracts
Deployed using Foundry scripts.

Frontend
Hosted on Vercel.

📚 Learning Resources
ERC-4626 Standard: https://eips.ethereum.org/EIPS/eip-4626

OpenZeppelin ERC4626 Implementation

Aave Developer Docs: https://docs.aave.com/developers/

Yearn Vault Architecture: https://docs.yearn.finance/

Structured Finance Tranches (Traditional Finance concept)

🧠 Key Concepts Demonstrated
✔ Tokenized Vault Standards
✔ Yield Strategy Integration
✔ Structured Risk Tranching
✔ DeFi Capital Allocation
✔ Smart Contract Accounting
✔ Full-Stack Web3 Integration

⚠️ Disclaimer
This project is for educational purposes only.
Not audited. Do not use in production with real funds.

👨‍💻 Author
Built as a deep dive into DeFi protocol engineering and structured yield systems.

```
