// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// interface Aion
interface Aion {
    
    function serviceFee(uint256 _serviceFee) external returns (uint256);

    function ScheduleCall(
        uint256 blocknumber,
        address to,
        uint256 value,
        uint256 gaslimit,
        uint256 gasprice,
        bytes memory data,
        bool schedType
    ) external payable returns (uint256, address);
}
