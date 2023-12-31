// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IVaultV3 is IERC20, IERC20Metadata {

    struct StrategyParams {
        uint256 activation;
        uint256 last_report;
        uint256 current_debt;
        uint256 max_debt;
    }
    
    function asset() external view returns (address _asset);

    function totalAssets() external view returns (uint256 _totalAssets);

    function strategies(address strategy) external view returns (StrategyParams calldata);

    /**
        @notice Update the max debt for a strategy.
        @param strategy The strategy to update the max debt for.
        @param new_max_debt The new max debt for the strategy.
     */
    function update_max_debt_for_strategy(address strategy, uint256 new_max_debt) external;
}
