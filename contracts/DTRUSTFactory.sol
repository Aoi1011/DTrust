// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DTRUST.sol";
import "./ControlKey.sol";

contract DTRUSTFactory {
    DTRUST[] public deployedDTRUSTs;

    mapping(DTRUST => bool) isDeployed;

    event CreateDTRUST(
        DTRUST createdDtrust,
        string contractSymbol,
        string indexed newuri,
        string indexed contractName
    );

    event CreatePrToken(
        uint256 indexed prTokenId,
        string prTokenKey,
        bool isSucceed
    );

    function createDTRUST(
        string memory _contractSymbol,
        string memory _newuri,
        string memory _contractName,
        address _settlor,
        address _beneficiary,
        address _trustee
    ) external {
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
        isDeployed[newDTRUST] = true;

        emit CreateDTRUST(newDTRUST, _contractSymbol, _newuri, _contractName);
    }

    function createPrToken(DTRUST _dtrust, string memory _tokenKey) external {
        uint256 prTokenId = 0;
        bool isSucceed = false;

        if (isDeployed[_dtrust]) {
            DTRUST existDTrust = _dtrust;
            existDTrust.mint(true, 1, _tokenKey);
            prTokenId = existDTrust.getCurrentPrToken();

            isSucceed = true;
        }
        if (isSucceed) {
            emit CreatePrToken(prTokenId, _tokenKey, true);
        } else {
            emit CreatePrToken(prTokenId, _tokenKey, false);
        }
    }

    function usePrToken(DTRUST _dtrust, string memory _tokenKey)
        external
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
        external
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

    function getAllDeployedDTRUSTs() external view returns (DTRUST[] memory) {
        return deployedDTRUSTs;
    }
}
