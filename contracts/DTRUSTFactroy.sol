// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DTRUST.sol";
import "./ControlKey.sol";

contract DTRUSTFactory {
    DTRUST[] public deployedDTRUSTs;

    function createDTRUST(
        string memory _contractSymbol,
        string memory _newuri,
        string memory _contractName,
        string memory _privateKey,
        address _settlor,
        address _beneficiary,
        address _trustee
    ) public returns (DTRUST, uint256) {
        DTRUST newDTRUST = new DTRUST(
            _contractName,
            _contractSymbol,
            _newuri,
            payable(msg.sender),
            payable(_settlor),
            _beneficiary,
            payable(_trustee)
        );
        deployedDTRUSTs.push(newDTRUST);
        ControlKey newControlKey = new ControlKey();
        return (
            newDTRUST,
            newControlKey.generateControlKey(
                _privateKey,
                _settlor,
                _beneficiary,
                _trustee
            )
        );
    }

    function getDeployedDTRUSTs() public view returns (DTRUST[] memory) {
        return deployedDTRUSTs;
    }
}
