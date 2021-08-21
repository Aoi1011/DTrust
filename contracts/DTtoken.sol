// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DTtoken is ERC20 {

    string constant name = "DTtoken";
    string constant symbol = "DT";

    address public registry;

    constructor(address _registry, uint256 _initialSupply) ERC20(name, symbol) {
        registry = _registry;
        _mint(msg.sender, _initialSupply);
    }

    function mint(address _account, uint256 value) external {
        require(
            msg.sender == registry,
            "Humanity::mint: Only the registry can mint new tokens"
        );
        _mint(_account, value);
    }
}
