// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC1155Views.sol";
import "../interfaces/IMyERC20.sol";

abstract contract ERC1155FromERC20 is IERC1155Views {
    function name(uint256 _id) external view override returns (string memory) {
        address contractAddress = address(_id);
        return IMyERC20(address(_id)).name();
    }

    function symbol(uint256 _id) external view override returns (string memory) {
        return IMyERC20(address(_id)).symbol();
    }

    function decimals(uint256 _id) external view override returns (uint8) {
        return IMyERC20(address(_id)).decimals();
    }
}
