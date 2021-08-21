// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Governance {
    IERC20 public DTtoken;
    address[] voters;
    Proposal[] public proposals;

    // voter => deposit
    mapping(address => uint256) public deposits;

    // Voter => Withdraw timestamp
    mapping(address => uint256) public withdrawTimes;

    struct Proposal {
        Result result;
        address target;
        bytes data;
        address proposer;
        address feeRecipient;
        uint256 fee;
        uint256 startTime;
        uint256 yesCount;
        uint256 noCount;
    }

    enum Result {
        Pending,
        Yes,
        No
    }

    event Execute(uint256 indexed proposalId);
    event Propose(
        uint256 indexed proposalId,
        address indexed proposer,
        address indexed target,
        bytes data
    );
    event RemoveVote(uint256 indexed proposalId, address indexed voter);
    event Terminate(uint256 indexed proposalId);
    event Vote(
        uint256 indexed proposalId,
        address indexed voter,
        bool approve,
        uint256 weight
    );

    event SplitAnnualFee(uint256 totalOfDTtoken, uint256 lengthOfVoter);

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

    function splitAnnualFee(uint256 _annualAmount) external {
        uint256 totalOfDTtoken = DTtoken.totalSupply();
        uint256 lengthOfVoter = voters.length;
        for (uint256 i = 0; i < lengthOfVoter; i++) {
            uint256 fee = _annualAmount *
                (deposits[voters[i]] * totalOfDTtoken);
            deposits[voters[i]] += fee;
        }
        emit SplitAnnualFee(totalOfDTtoken, lengthOfVoter);
    }

    function propose() external {}

    function voteYes(uint256 _proposalId) external {
        Proposal storage proposal = proposals[_proposalId];

        uint256 fee = (deposits[msg.sender] * 3) / 4;
        require(deposits[msg.sender] > fee, "Not enough amount in your balance");
        deposits[msg.sender] -= fee;
        proposal.yesCount += 1;

        emit Vote(_proposalId, msg.sender, true, fee);
    }

    function voteNo(uint256 _proposalId) external {}

    function removeVote(uint256 _proposaId) external {}

    function finalize(uint256 _proposalId) external {}
}
