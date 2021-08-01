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

    function createPromoteToken(
        DTRUST _dtrust,
        uint256 _id,
        string memory _tokenName
    ) public returns (bool) {
        for (uint256 i = 0; i < deployedDTRUSTs.length; i++) {
            if (deployedDTRUSTs[i] == _dtrust) {
                DTRUST existDTrust = deployedDTRUSTs[i];
                existDTrust.mint(_id, _tokenName, 1);
                return true;
            }
        }
        return false;
    }

    function getAllDeployedDTRUSTs() public view returns (DTRUST[] memory) {
        return deployedDTRUSTs;
    }
}
