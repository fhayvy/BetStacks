# BetStacks: Decentralized Sports Betting Platform

BetStacks is a decentralized sports betting platform built on Stacks blockchain using Clarity smart contracts. The platform enables trustless peer-to-peer betting on various events with multiple betting mechanisms.

## Features

- **Decentralized Betting**: Create and participate in betting markets without intermediaries
- **Multiple Betting Types**:
  - Winner-take-all: Winners split the entire pool proportionally
  - Proportional: Payouts based on the proportion of your stake
  - Fixed-odds: Classic bookmaker-style odds with predetermined payouts
- **Transparent & Fair**: All betting logic is on-chain and verifiable
- **Autonomous Resolution**: Betting events can be resolved automatically based on outcomes
- **User Protection**: Built-in cancellation and refund mechanisms

## Smart Contract Architecture

The BetStacks platform is built around a single Clarity smart contract with the following core components:

### Data Structures

- `wagers`: Main mapping for all betting events
- `bettor-positions`: Tracks all users' bets for each wager
- `supported-wager-types`: List of supported betting mechanisms

### Key Functions

#### For Wager Creators
- `create-wager`: Create a new betting event with customizable parameters
- `close-wager`: Close betting for an event after the end block is reached
- `cancel-wager`: Cancel a wager and initiate refunds (only available before end block)

#### For Bettors
- `place-bet`: Place a bet on a specific outcome with a specified amount
- `claim-winnings`: Claim winnings after a wager is resolved

#### For Administrators
- `resolve-wager`: Determine winning outcomes for a closed wager

#### Read-Only Functions
- `get-wager`: Retrieve details about a specific wager
- `get-bettor-position`: Check a bettor's position in a specific wager
- `get-current-block-height`: Get the current block height

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Local Clarity development environment
- [Stacks Wallet](https://www.hiro.so/wallet) - For interacting with the deployed contract

### Installation

1. Clone the repository
```bash
git clone https://github.com/fhayvy/betstacks.git
cd betstacks
```

2. Initialize the Clarinet project
```bash
clarinet integrate
```

### Local Testing

```bash
clarinet test
```

### Deployment

1. Deploy to testnet
```bash
clarinet deploy --testnet
```

2. Deploy to mainnet
```bash
clarinet deploy --mainnet
```

## Usage Examples

### Creating a Betting Event

```clarity
(contract-call? .betstacks create-wager 
  "World Cup 2026 Winner" 
  (list "Brazil" "France" "Germany" "Argentina" "Spain") 
  u100000 
  "fixed-odds" 
  (some (list u200 u350 u400 u250 u500)))
```

### Placing a Bet

```clarity
(contract-call? .betstacks place-bet u0 u1 u1000)
```

### Claiming Winnings

```clarity
(contract-call? .betstacks claim-winnings u0)
```

## Security Considerations

- The contract includes safety measures to prevent unauthorized access and manipulation
- All betting funds are held in the contract until proper resolution
- Multiple error codes help diagnose issues clearly
- Events cannot be modified once closed, ensuring fair outcomes

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details

## Acknowledgments

- Stacks blockchain community
- Clarity language developers
- All open-source contributors