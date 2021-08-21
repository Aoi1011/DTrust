// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Governance {
    IERC20 public DTtoken;
    address[] voters;
    // voter => deposit
    mapping(address => uint256) public deposits;

    // Voter => Withdraw timestamp
    mapping(address => uint256) public withdrawTimes;

    constructor(IERC20 _DTtoken) {
        DTtoken = _DTtoken;
    }

    function registerVoter(address _newVoter) external {
        require(_newVoter != address(0));
        voters.push(_newVoter);
    }

    function deposit(uint256 _amount) external {
        deposits[msg.sender] += _amount;
        DTtoken.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _amount) external {
        deposits[msg.sender] -= deposits[msg.sender];
        DTtoken.transfer(msg.sender, _amount);
    }

    function splitAnnualFee(uint256 _amount) external {
        uint256 totalOfDTtoken = DTtoken.totalSupply();
        uint256 lengthOfVoter = voters.length;
        for (uint256 i = 0; i < lengthOfVoter; i++) {
            uint256 fee = _amount * (deposits[voters[i]] * totalOfDTtoken);
            deposits[voters[i]] += fee;
        }
    }
}
