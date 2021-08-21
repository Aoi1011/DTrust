// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PRtoken is ERC20 {
    address public registry;

    uint256 public constant INITIAL_SUPPLY = 0;

    constructor(address _registry) ERC20("PRtoken", "PR") {
        registry = _registry;
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function mint(address _account, uint256 value) external {
        require(
            msg.sender == registry,
            "Only the registry can mint new tokens"
        );
        _mint(_account, value);
    }
}
