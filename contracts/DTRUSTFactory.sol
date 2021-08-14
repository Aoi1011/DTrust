// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DTRUST.sol";
import "./ControlKey.sol";

contract DTRUSTFactory {
    DTRUST[] public deployedDTRUSTs;

    mapping(DTRUST => bool) isDeployed;

    event CreateDTRUST(DTRUST createdDtrust, string indexed newuri);

    event CreatePrToken(
        uint256 indexed prTokenId,
        string prTokenKey,
        bool isSucceed
    );

    function createDTRUST(
        string memory _newuri,
        address _settlor,
        address _beneficiary,
        address _trustee,
        uint256 _paymentInterval
    ) external {
        DTRUST newDTRUST = new DTRUST(
            _newuri,
            payable(msg.sender),
            payable(_settlor),
            _beneficiary,
            payable(_trustee),
            _paymentInterval
        );
        deployedDTRUSTs.push(newDTRUST);
        isDeployed[newDTRUST] = true;

        emit CreateDTRUST(newDTRUST, _newuri);
    }

    function createPrToken(
        DTRUST _dtrust,
        string memory _tokenKey,
        address _receiver
    ) external {
        uint256 prTokenId = 0;
        bool isSucceed = false;

        if (isDeployed[_dtrust]) {
            DTRUST existDTrust = _dtrust;
            existDTrust.mint(_receiver, 0, 1, "");
            prTokenId = existDTrust.getCurrentPrToken();

            isSucceed = true;
        }

        emit CreatePrToken(prTokenId, _tokenKey, isSucceed);
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
        uint256 lengthOfDtrust = deployedDTRUSTs.length;
        uint256 currentPrToken = 0;
        for (uint256 i = 0; i < lengthOfDtrust; i++) {
            if (deployedDTRUSTs[i] == _dtrust) {
                DTRUST existDTrust = deployedDTRUSTs[i];
                currentPrToken = existDTrust.getCurrentPrToken();
                return currentPrToken;
            }
        }
        return currentPrToken;
    }

    function getAllDeployedDTRUSTs() external view returns (DTRUST[] memory) {
        return deployedDTRUSTs;
    }
}
