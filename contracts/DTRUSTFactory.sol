// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DTRUST.sol";
import "./ControlKey.sol";

contract DTRUSTFactory {
    DTRUST[] public deployedDTRUSTs;
    uint256 public basisPoint;

    address public governanceAddress;

    mapping(DTRUST => bool) isDeployed;

    event CreateDTRUST(DTRUST createdDtrust, string indexed newuri);
    event UpdateBasisPoint(uint256 basispoint);

    event CreatePrToken(
        uint256 indexed prTokenId,
        string prTokenKey,
        bool isSucceed
    );

    constructor(address _governanceAddress) {
        governanceAddress = _governanceAddress;
        basisPoint = 1;
    }

    function createDTRUST(
        string memory _newuri,
        address _settlor,
        address _beneficiary,
        address _trustee, 
        bool _hasPromoter, 
        address promoter
    ) external {
        DTRUST newDTRUST = new DTRUST(
            _newuri,
            payable(msg.sender),
            payable(_settlor),
            _beneficiary,
            payable(_trustee),
            governanceAddress,
            basisPoint, 
            _hasPromoter, 
            promoter
        );
        deployedDTRUSTs.push(newDTRUST);
        isDeployed[newDTRUST] = true;

        emit CreateDTRUST(newDTRUST, _newuri);
    }

    function updateBasisPoint(uint256 _basepoint) external {
        basisPoint = _basepoint;
        emit UpdateBasisPoint(basisPoint);
    }
    
    function getAllDeployedDTRUSTs() external view returns (DTRUST[] memory) {
        return deployedDTRUSTs;
    }
}
