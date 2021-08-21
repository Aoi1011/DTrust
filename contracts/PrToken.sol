// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PrToken is ERC20 {
    address public registry;

    constructor(address _registry, uint256 _initialSupply)
        ERC20("PrToken", "PR")
    {
        registry = _registry;
        _mint(msg.sender, _initialSupply);
    }

    function mint(address _account, uint256 value) external {
        require(
            msg.sender == registry,
            "Only the registry can mint new tokens"
        );
        _mint(_account, value);
    }
}
