// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DTRUST.sol";
import "./ControlKey.sol";

contract DTRUSTFactory {
    DTRUST[] public deployedDTRUSTs;

    mapping(DTRUST => bool) isDeployed;

    event CreateDTRUST(
        DTRUST createdDtrust,
        string indexed newuri,
        uint256 frequency
    );

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
        bool _settlorCBWA,
        bool _trusteeCBWA,
        bool _settlorCDS,
        bool _trusteeCDS,
        bool _settlorRD,
        bool _trusteeRD,
        bool _settlorSA,
        bool _trusteeTA,
        bool _settlorILT,
        uint256 __paymentInterval,
        uint256 _frequency
    ) external {
        DTRUST newDTRUST = new DTRUST(
            _newuri,
            payable(msg.sender),
            payable(_settlor),
            _beneficiary,
            payable(_trustee),
            _settlorCBWA,
            _trusteeCBWA,
            _settlorCDS,
            _trusteeCDS,
            _settlorRD,
            _trusteeRD,
            _settlorSA,
            _trusteeTA,
            _settlorILT,
            __paymentInterval,
            _frequency
        );
        deployedDTRUSTs.push(newDTRUST);
        isDeployed[newDTRUST] = true;

        emit CreateDTRUST(newDTRUST, _newuri, _frequency);
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
            existDTrust.mint(_receiver, true, 1, _tokenKey);
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
