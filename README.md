# CCIP Rebase Token

A cross-chain rebase token implementation using Chainlink's CCIP (Cross-Chain Interoperability Protocol) that allows users to deposit into a vault and earn interest.

## Overview

This project implements a rebase token system with the following features:

- **Cross-chain transfers** using Chainlink CCIP
- **Interest-bearing tokens** that accrue value over time
- **Vault system** for managing deposits
- **Custom token pools** for cross-chain compatibility

## Contracts

- **RebaseToken.sol**: ERC20 token with rebase functionality and interest accrual
- **RebaseTokenPool.sol**: Custom CCIP token pool for cross-chain transfers
- **Vault.sol**: Vault contract for managing token deposits

## Features

- ✅ Cross-chain token transfers via Chainlink CCIP
- ✅ Dynamic interest rate mechanism (can only decrease)
- ✅ Per-user interest rate tracking
- ✅ Role-based access control for minting and burning
- ✅ Comprehensive test suite (unit tests, fuzz tests, cross-chain tests)

## Validation Snapshot (Feb 2026)

- `forge test`: **10/10 tests passed** (unit + fuzz + cross-chain)
- Fuzz campaign depth: **8 fuzz tests**, each with **256 runs**
- `forge coverage --report summary --ir-minimum`: core contract coverage
	- `src/RebaseToken.sol`: **95.74% lines**, **95.45% statements**, **100% funcs**
	- `src/RebaseTokenPool.sol`: **100% lines/statements/funcs**
	- `src/Vault.sol`: **93.75% lines**, **92.86% statements**, **100% funcs**

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/downloads)
- Node.js and npm (for dependencies)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/GN25/Foundry-Rebase-Token.git
cd Foundry-Rebase-Token
```

2. Install dependencies:
```bash
forge install
```

3. Create environment configuration:
```bash
cp .env.example .env
```

4. Edit `.env` and add your RPC URLs and private key

## Configuration

The project uses the following environment variables:

- `SEPOLIA_RPC_URL`: RPC endpoint for Sepolia testnet
- `ARB_SEPOLIA_RPC_URL`: RPC endpoint for Arbitrum Sepolia testnet
- `PRIVATE_KEY`: Your wallet private key for deployments (optional)

Get free RPC URLs from [Alchemy](https://www.alchemy.com/)

## Build

```bash
forge build
```

## Test

Run all tests:
```bash
forge test
```

Run tests with verbosity:
```bash
forge test -vvv
```

Run specific test file:
```bash
forge test --match-path test/unit/RebaseTokenTest.t.sol
```

Run fuzz tests:
```bash
forge test --match-path test/fuzz/RebaseTokenFuzzTest.t.sol
```

## Deployment

Deploy contracts using the deployment scripts:

```bash
# Deploy to Sepolia
forge script script/Deployer.s.sol:Deployer --rpc-url $SEPOLIA_RPC_URL --broadcast

# Deploy to Arbitrum Sepolia
forge script script/Deployer.s.sol:Deployer --rpc-url $ARB_SEPOLIA_RPC_URL --broadcast
```

## Scripts

- **Deployer.s.sol**: Main deployment script
- **ConfigurePool.s.sol**: Configure CCIP token pools
- **BridgeTokens.s.sol**: Bridge tokens cross-chain

## Project Structure

```
├── src/                    # Smart contracts
│   ├── RebaseToken.sol
│   ├── RebaseTokenPool.sol
│   ├── Vault.sol
│   └── interfaces/
├── script/                 # Deployment scripts
├── test/                   # Test files
│   ├── unit/              # Unit tests
│   ├── fuzz/              # Fuzz tests
│   └── CrossChainTest.t.sol
├── lib/                    # Dependencies
└── foundry.toml           # Foundry configuration
```

## Dependencies

- [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [Chainlink CCIP](https://github.com/smartcontractkit/ccip)
- [Chainlink Local](https://github.com/smartcontractkit/chainlink-local)
- [Forge Standard Library](https://github.com/foundry-rs/forge-std)

## Security

⚠️ **IMPORTANT**: This project is for educational/demonstration purposes. 

- Never commit your `.env` file or private keys
- The contract has centralization risks (owner can grant mint/burn roles)
- Always audit smart contracts before mainnet deployment

## Author

Guillem Navarra (GN25)

## License

MIT

## Resources

- [Chainlink CCIP Documentation](https://docs.chain.link/ccip)
- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Documentation](https://docs.openzeppelin.com/)
