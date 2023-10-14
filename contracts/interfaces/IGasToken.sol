// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGasToken is IERC20 {
    function getEffectiveTotal() external view returns (uint256);

    function includeAccount(address account) external;

    function excludeAccount(address account) external;

    function getEarningFactor() external view returns (uint256);

    function getSnapshot(address account) external view returns (uint256);
}