# 🎁 Gift Card Token System

A complete prepaid token management system built on the Stacks blockchain using Clarity smart contracts. Issue, redeem, and transfer digital gift cards with built-in expiration and balance tracking.

## ✨ Features

- 🎫 **Issue Gift Cards**: Create digital gift cards with custom amounts and expiration dates
- 💳 **Redeem Tokens**: Convert gift card value to user balance (full or partial redemption)
- 🔄 **Transfer Cards**: Send gift cards to other users
- 🛒 **Marketplace Trading**: Buy and sell gift cards at discounted prices on secondary market
- ⏰ **Expiration Management**: Automatic expiration handling with fund recovery
- 📊 **Balance Tracking**: Real-time balance management for users and contract
- 🛡️ **Admin Controls**: Owner-only functions for card management
- 📈 **Analytics**: Track total issued, redeemed, and marketplace statistics

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet configured

### Installation

```bash
clarinet new gift-card-project
cd gift-card-project
# Copy the contract file to contracts/gift-card-token-system.clar
```

### Development

```bash
# Check contract syntax
clarinet check

# Run tests
clarinet test

# Start local testnet
clarinet integrate
```

## 📖 Usage Guide

### 🎫 Issuing Gift Cards

**Function**: `issue-gift-card`

```clarity
(contract-call? .gift-card-token-system issue-gift-card 'SP1234...RECIPIENT u1000 u144)
```

- `recipient`: Principal address receiving the gift card
- `amount`: Gift card value in micro-STX
- `expiration-blocks`: Number of blocks until expiration

### 💰 Redeeming Gift Cards

**Function**: `redeem-gift-card`

```clarity
(contract-call? .gift-card-token-system redeem-gift-card u1 u500)
```

**Partial Redemption**: `partial-redeem-gift-card`

```clarity
(contract-call? .gift-card-token-system partial-redeem-gift-card u1 u250)
```

### 🔄 Transferring Gift Cards

**Function**: `transfer-gift-card`

```clarity
(contract-call? .gift-card-token-system transfer-gift-card u1 'SP5678...NEWOWNER)
```

### 💳 Withdrawing Balance

**Function**: `withdraw-from-balance`

```clarity
(contract-call? .gift-card-token-system withdraw-from-balance u1000)
```

### 🛒 Marketplace Operations

**List Gift Card**: `list-gift-card-on-marketplace`

```clarity
(contract-call? .gift-card-token-system list-gift-card-on-marketplace u1 u800)
```

**Buy Gift Card**: `buy-gift-card-from-marketplace`

```clarity
(contract-call? .gift-card-token-system buy-gift-card-from-marketplace u1)
```

**Delist Gift Card**: `delist-gift-card-from-marketplace`

```clarity
(contract-call? .gift-card-token-system delist-gift-card-from-marketplace u1)
```

## 📋 Read-Only Functions

### 🔍 Check Gift Card Details

```clarity
(contract-call? .gift-card-token-system get-gift-card u1)
(contract-call? .gift-card-token-system get-gift-card-status u1)
```

### 💼 Check User Balance

```clarity
(contract-call? .gift-card-token-system get-balance 'SP1234...USER)
```

### 📊 Contract Statistics

```clarity
(contract-call? .gift-card-token-system get-contract-stats)
```

### 🛒 Marketplace Information

```clarity
(contract-call? .gift-card-token-system get-marketplace-listing u1)
(contract-call? .gift-card-token-system get-marketplace-stats)
(contract-call? .gift-card-token-system get-gift-card-with-listing u1)
```

## 🛠️ Admin Functions

### 💸 Fund Contract

```clarity
(contract-call? .gift-card-token-system fund-contract u10000)
```

### 🚫 Deactivate Gift Card

```clarity
(contract-call? .gift-card-token-system deactivate-gift-card u1)
```

### ⏳ Withdraw Expired Funds

```clarity
(contract-call? .gift-card-token-system withdraw-expired-funds u1)
```

### 🆘 Emergency Pause

```clarity
(contract-call? .gift-card-token-system emergency-pause-all)
```

### 🔄 Reactivate Gift Card

```clarity
(contract-call? .gift-card-token-system reactivate-gift-card u1)
```

### ⏰ Extend Expiration

```clarity
(contract-call? .gift-card-token-system extend-expiration u1 u144)
```

### 🛒 Marketplace Admin

```clarity
(contract-call? .gift-card-token-system set-marketplace-fee-rate u250)
(contract-call? .gift-card-token-system force-delist-gift-card u1)
```

## 🏗️ Architecture

### Data Structures

- **gift-cards**: Core gift card data with amounts, expiration, and status
- **gift-card-ownership**: Maps gift card IDs to current owners
- **user-balances**: Tracks redeemed balances per user
- **user-gift-cards**: Efficient lookup of user's gift cards
- **marketplace-listings**: Active marketplace listings with prices and sellers
- **marketplace-sales**: Completed sales history for analytics

### Key Features

- ✅ **Expiration Handling**: Cards automatically expire after specified blocks
- ✅ **Partial Redemption**: Use gift cards in smaller amounts
- ✅ **Transfer System**: Move gift cards between users
- ✅ **Marketplace Trading**: Secondary market with configurable fees
- ✅ **Admin Recovery**: Recover funds from expired cards
- ✅ **Emergency Controls**: Pause system in case of issues

## 🔒 Security Features

- **Owner-Only Functions**: Critical operations restricted to contract deployer
- **Expiration Enforcement**: Automatic prevention of expired card usage
- **Balance Validation**: Prevents overdrafts and invalid operations
- **Ownership Verification**: Users can only operate on their own cards

## 📊 Error Codes

| Code | Error | Description |
|------|-------|-------------|
| u100 | `err-owner-only` | Function restricted to contract owner |
| u101 | `err-not-found` | Gift card not found |
| u102 | `err-expired` | Gift card has expired |
| u103 | `err-already-redeemed` | Gift card fully redeemed |
| u104 | `err-insufficient-balance` | Insufficient balance for operation |
| u105 | `err-invalid-amount` | Invalid amount provided |
| u106 | `err-unauthorized` | User not authorized for this operation |
| u107 | `err-gift-card-exists` | Gift card already exists |
| u108 | `err-already-listed` | Gift card already listed on marketplace |
| u109 | `err-not-listed` | Gift card not found in marketplace |
| u110 | `err-invalid-price` | Invalid marketplace price |
| u111 | `err-cannot-buy-own` | Cannot buy your own listed gift card |

## 🧪 Testing

```bash
# Run all tests
clarinet test

# Check contract
clarinet check

# Console testing
clarinet console
```

## 🛣️ Roadmap

- 🎯 Multi-merchant support
- 🏪 Marketplace integration
- 📱 Mobile wallet compatibility
- 🔗 Cross-chain compatibility
- 📈 Advanced analytics dashboard

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

---

Built with ❤️ on Stacks blockchain
