# Risk Framework Onchain

## How to Calculate the Scores in Uint

Let's say, we want to score a target address using these 7 scores:

Scores: 5, 4, 3, 2, 1, 2, and 3.

If we convert each score into binary, each one is:

Scores: 00101, 00100, 00011, 00010, 00001, 00010 and 00011

But if we join all the binary values in one number:

`101001000001100010000010001000011`

The decimal representation is: `5506139203`

That is the value we use to call the Risk Framework onchain.

The values are manipulated by bitwise operators in the library `ScoresLib.sol`.

## Considerations

- It supports up to 15 scores.
- The scores are processed in order (right to left).
- The sorting process cannot be change in the scores. It means that if the first score (right) represents the Testing score, then it cannot be changed to the second place, because as we saw before, the final number (decimal representation) would change.

### Scores

The scores must be set in this order:

- Audit
- Code Review
- Complexity
- Protocol Safety
- Team Knowledge
- Testing

### How to Get the Decimal Score from List of Scores

- Call `fromListToScore` (view) function passing the scores list as parameter.

### How to Get the List of Scores from Decimal Score

- Call `fromScoreToList` (view) function passing the score value as parameter.

## Deployment Scripts

### RiskFramework Contract

`forge create --rpc-url <your_rpc_url> --constructor-args 0x757f29A77D90a45b188c095A04aFa19F497c8B0E 0x757f29A77D90a45b188c095A04aFa19F497c8B0E 6 --private-key <your_private_key> --etherscan-api-key <your_etherscan_api_key> --verify contracts/RiskFramework.sol:RiskFramework`

### ImpactCalculator Contract

This script uses the create2 opcode to pre-defined the contract address:

`forge script ./script/ImpactCalculator.s.sol:ImpactCalculatorScript --rpc-url <rpc-url> --etherscan-api-key <etherscan-api-key> --broadcast --verify -vvvv`

`forge create --rpc-url <your_rpc_url> --private-key <your_private_key> --etherscan-api-key <your_etherscan_api_key> --verify contracts/lens/ImpactCalculator.sol:ImpactCalculator`

## Deployment Addresses

More info [here](./DEPLOYMENTS.md).

## Scripts

More info [here](./SCRIPTS.md).

## Network IDs

- Ethereum = 1
- Binance Smart Chain = 56
- Polygon = 137
- Fantom = 250
- Base = 8453
- Avalanche = 43114
- Optimism = 10
- Linea = 59144
- Arbitrum = 42161

## How to Verify Whether a Target is Supported in The ORF or Not

```solidity
uint256 networkId = ...;
address target = 0x...;
(
    uint128 scores,
    uint8[] memory scoresList,
    uint128 averageScore,
    bytes32[] memory tagsList,
    bool isActive
) = riskFramework.getTargetInfo(networkId, target);
require(scores > 0 && isActive);
```
