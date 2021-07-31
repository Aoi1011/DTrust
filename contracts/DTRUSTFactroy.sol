// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DTRUST.sol";

contract DTRUSTFactory {
    DTRUST[] public deployedDTRUSTs;

    function createDTRUST(
        string memory _contractSymbol,
        string memory _newuri,
        string memory _contractName
    ) public {
        DTRUST newDTRUST = new DTRUST(
            _contractName,
            _contractSymbol,
            _newuri,
            payable(msg.sender)
        );
        deployedDTRUSTs.push(newDTRUST);
    }

    function getNumberDeployedDTRUSTs() public view returns (uint256) {
        return deployedDTRUSTs.length;
    }
}
