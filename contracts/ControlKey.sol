// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ControlKey {
    struct StructControlKey {
        string privateKey;
        address[] settlors;
        address[] beneficiaries;
        address[] trustees;
        bool usable;
        bool burnable;
    }
    uint256 public numControlKey;

    mapping(uint256 => StructControlKey) controlKeys;

    function generateControlKey(
        string memory _privateKey,
        address[] memory _settlors,
        address[] memory _beneficiaries,
        address[] memory _trustees
    ) public returns (uint256 controlKeyId) {
        controlKeyId = numControlKey++;
        controlKeys[controlKeyId] = StructControlKey({
            privateKey: _privateKey,
            settlors: _settlors,
            beneficiaries: _beneficiaries,
            trustees: _trustees,
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
            settlors: existControlKey.settlors,
            beneficiaries: existControlKey.beneficiaries,
            trustees: existControlKey.trustees,
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
            settlors: existControlKey.settlors,
            beneficiaries: existControlKey.beneficiaries,
            trustees: existControlKey.trustees,
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
