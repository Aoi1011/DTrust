// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ControlKey {
    struct StructControlKey {
        string privateKey;
        address settlor;
        address beneficiary;
        address trustee;
        bool usable;
        bool burnable;
    }

    uint256 public numControlKey;

    mapping(uint256 => StructControlKey) controlKeys;

    function generateControlKey(
        string memory _privateKey,
        address _settlor,
        address _beneficiary,
        address _trustee
    ) public returns (uint256 controlKeyId) {
        controlKeyId = numControlKey;
        numControlKey++;
        controlKeys[controlKeyId] = StructControlKey({
            privateKey: _privateKey,
            settlor: _settlor,
            beneficiary: _beneficiary,
            trustee: _trustee,
            usable: false,
            burnable: false
        });
    }

    function getControlKey(uint256 _controlKeyId)
        public
        view
        returns (StructControlKey memory existControlKey)
    {
        require(_controlKeyId >= 0, "Control Key must be more than 0");
        require(_controlKeyId <= numControlKey, "ControlKey does not exist.");
        return controlKeys[_controlKeyId];
    }

    function handleUsableControlKey(uint256 _controlKeyId) public {
        require(_controlKeyId >= 0, "Control Key must be more than 0");
        require(
            _controlKeyId <= numControlKey,
            "ControlKey must be less than total"
        );
        StructControlKey memory existControlKey = controlKeys[_controlKeyId];
        controlKeys[_controlKeyId] = StructControlKey({
            privateKey: existControlKey.privateKey,
            settlor: existControlKey.settlor,
            beneficiary: existControlKey.beneficiary,
            trustee: existControlKey.trustee,
            usable: !existControlKey.usable,
            burnable: existControlKey.burnable
        });
    }

    function handleBurnableControlKey(uint256 _controlKeyId) public {
        require(_controlKeyId >= 0, "Control Key must be more than 0");
        require(
            _controlKeyId <= numControlKey,
            "ControlKey must be less than total"
        );
        StructControlKey memory existControlKey = controlKeys[_controlKeyId];
        controlKeys[_controlKeyId] = StructControlKey({
            privateKey: existControlKey.privateKey,
            settlor: existControlKey.settlor,
            beneficiary: existControlKey.beneficiary,
            trustee: existControlKey.trustee,
            usable: existControlKey.usable,
            burnable: !existControlKey.burnable
        });
    }

    function destroyControlKey(uint256 _controlKeyId) public {
        require(_controlKeyId >= 0, "Control Key must be more than 0");
        require(
            _controlKeyId <= numControlKey,
            "ControlKey must be less than total"
        );

        StructControlKey memory existControlKey = controlKeys[_controlKeyId];
        require(existControlKey.burnable, "Can not destroy.");

        delete controlKeys[_controlKeyId];
    }
}
