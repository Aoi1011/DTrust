// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DTRUST.sol";
import "./ControlKey.sol";

contract DTRUSTFactory {
    struct Token {
        uint256 tokenId;
        string tokenName; // PrToekn, DToken
        string tokenKey;
    }
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
        string memory _tokenName,
        string memory _tokenKey
    ) public returns (bool) {
        for (uint256 i = 0; i < deployedDTRUSTs.length; i++) {
            if (deployedDTRUSTs[i] == _dtrust) {
                DTRUST existDTrust = deployedDTRUSTs[i];
                existDTrust.mint(_id, _tokenName, 1, _tokenKey);
                return true;
            }
        }
        return false;
    }

    function usePromoteToken(DTRUST _dtrust, string memory _tokenKey)
        public
        returns (string memory)
    {
        for (uint256 i = 0; i < deployedDTRUSTs.length; i++) {
            if (deployedDTRUSTs[i] == _dtrust) {
                DTRUST existDTrust = deployedDTRUSTs[i];
                for (uint256 j = 0; j < existDTrust.getCountOfToken(); j++) {
                    // existDTrust.token[j].tokenKey;
                    if (
                        keccak256(
                            abi.encodePacked(
                                existDTrust.token[_tokenId].tokenKey
                            )
                        ) == keccak256(abi.encodePacked(_tokenKey))
                    ) {
                        return
                            existDTrust.getURI(
                                existDTrust,
                                existDTrust.token[_tokenId].tokenId
                            );
                    }
                }
            }
        }
        // DTRUST existDTrust =
    }

    function getAllDeployedDTRUSTs() public view returns (DTRUST[] memory) {
        return deployedDTRUSTs;
    }
}
