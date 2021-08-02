// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DTRUST.sol";
import "./ControlKey.sol";

contract DTRUSTFactory {
    DTRUST[] public deployedDTRUSTs;

    event CreateDTRUST(
        string contractSymbol,
        string indexed newuri,
        string indexed contractName
    );

    function createDTRUST(
        string memory _contractSymbol,
        string memory _newuri,
        string memory _contractName,
        address _settlor,
        address _beneficiary,
        address _trustee
    ) public payable {
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

        emit CreateDTRUST(_contractSymbol, _newuri, _contractName);
    }

    function createPromoteToken(DTRUST _dtrust, string memory _tokenKey)
        public
        returns (bool)
    {
        for (uint256 i = 0; i < deployedDTRUSTs.length; i++) {
            if (deployedDTRUSTs[i] == _dtrust) {
                DTRUST existDTrust = deployedDTRUSTs[i];
                existDTrust.mint(true, 1, _tokenKey);
                return true;
            }
        }
        return false;
    }

    function usePromoteToken(DTRUST _dtrust, string memory _tokenKey)
        public
        view
        returns (string memory)
    {
        for (uint256 i = 0; i < deployedDTRUSTs.length; i++) {
            if (deployedDTRUSTs[i] == _dtrust) {
                DTRUST existDTrust = deployedDTRUSTs[i];
                return existDTrust.getSpecificPrToken(_tokenKey);
            }
        }
        return "";
    }

    function getCurrentPromoteToken(DTRUST _dtrust)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < deployedDTRUSTs.length; i++) {
            if (deployedDTRUSTs[i] == _dtrust) {
                DTRUST existDTrust = deployedDTRUSTs[i];
                return existDTrust.getCurrentPrToken();
            }
        }
    }

    function getAllDeployedDTRUSTs() public view returns (DTRUST[] memory) {
        return deployedDTRUSTs;
    }
}
