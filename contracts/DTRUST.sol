// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/SchedulerInterface.sol";
import "./interfaces/Aion.sol";

contract DTRUST is ERC1155 {
    // Library///////
    using SafeERC20 for IERC20;
    /////////////////

    // constants/////
    uint256 private constant PACK_INDEX =
        0x0000000000000000000000000000000000000000000000000000000000007FFF;
    uint256 private constant PrTokenId = 0;
    uint256 private constant DTokenId = 1;
    /////////////////

    enum ContractRights {
        TERMINATE,
        SWAP,
        POSTPONE
    }

    struct PrToken {
        uint256 id;
        string tokenKey;
    }

    struct Subscription {
        uint256 start;
        uint256 nextPayment;
        bool isTwoYear;
    }

    Aion public aion;

    uint256 private _AnualFeeTotal = 0;
    uint256 public basisPoint = 1; // for 2 year
    uint256 public countOfPrToken = 1;
    uint256 public payAnnualFrequency = 0;
    uint256 public paymentInterval;
    uint256 public lockedUntil;
    address payable public manager;
    address payable public settlor;
    address payable public trustee;
    address public beneficiary;
    address public currentScheduledTransaction;
    string public name;
    string public symbol;
    string public dTrustUri;
    bool settlorCBWA;
    bool trusteeCBWA;
    bool settlorCDS;
    bool trusteeCDS;
    bool settlorRD;
    bool trusteeRD;
    bool settlorSA;
    bool trusteeTA;
    bool settlorILT;
    PrToken[] public prTokens;
    Subscription private subscription;

    // storage//////////////////////////
    mapping(uint256 => uint256) public tokenSupply; // id -> tokensupply
    mapping(uint256 => uint256) public tokenPrices; // id -> tokenPrice
    mapping(address => mapping(uint256 => uint256)) private _orderBook; // customer -> id -> amount of asset
    /////////////////////////////////////

    // event/////////////////////////////
    event Order(
        address indexed _target,
        uint256 indexed _id,
        uint256 indexed _amount
    );
    event OrderBatch(
        address indexed _target,
        uint256[] indexed _ids,
        uint256[] indexed _amounts
    );
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed sender, uint256 tokenId, uint256 amount);
    event UpdateBasisPoint(uint256 basispoint);
    event PaymentSentForFirstTwoYear(
        address from,
        uint256 tokenId,
        uint256 amount,
        uint256 total,
        uint256 date
    );
    event PaymentSentForSubsequentYear(
        address from,
        uint256 amount,
        uint256 total,
        uint256 date
    );
    event PaymentScheduled(
        address indexed scheduledTransaction,
        address recipient,
        uint256 value
    );
    event PaymentExecuted(
        address indexed scheduledTransaction,
        address recipient,
        uint256 value
    );
    ////////////////////////////////////////

    modifier onlyManager() {
        require(
            msg.sender == manager ||
                msg.sender == settlor ||
                msg.sender == trustee,
            "Error: The caller is not any of the defined managers (settlor and trustee)!"
        );
        _;
    }

    constructor(
        string memory _newURI,
        address payable _deployerAddress,
        address payable _settlor,
        address _beneficiary,
        address payable _trustee,
        bool _settlorCBWA,
        bool _trusteeCBWA,
        bool _settlorCDS,
        bool _trusteeCDS,
        bool _settlorRD,
        bool _trusteeRD,
        bool _settlorSA,
        bool _trusteeTA,
        bool _settlorILT,
        uint256 _paymentInterval,
        uint256 _payAnnualFrequnecy
    ) ERC1155(_newURI) {
        require(address(_deployerAddress) != address(0));
        require(address(_settlor) != address(0));
        require(address(_beneficiary) != address(0));
        require(address(_trustee) != address(0));

        dTrustUri = _newURI;
        manager = _deployerAddress;
        settlor = _settlor;
        beneficiary = _beneficiary;
        trustee = _trustee;
        settlorCBWA = _settlorCBWA;
        trusteeCBWA = _trusteeCBWA;
        settlorCDS = _settlorCDS;
        trusteeCDS = _trusteeCDS;
        settlorRD = _settlorRD;
        trusteeRD = _trusteeRD;
        settlorSA = _settlorSA;
        trusteeTA = _trusteeTA;
        settlorILT = _settlorILT;
        payAnnualFrequency = _payAnnualFrequnecy;

        // scheduler = SchedulerInterface(_deployerAddress);
        paymentInterval = _paymentInterval;

        subscription = Subscription(
            block.timestamp,
            block.timestamp + _payAnnualFrequnecy,
            true
        );
    }

    function setBeneficiaryAsset(uint256 _id, uint256 _price)
        external
        onlyManager
    {
        tokenPrices[_id] = _price;
    }

    function setBeneficiariesAssets(
        address payable _beneficiary,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyManager {
        for (uint256 i = 0; i < _ids.length; i++) {
            tokenPrices[_ids[i]] = _amounts[i];
        }
        safeBatchTransferFrom(msg.sender, _beneficiary, _ids, _amounts, "");
    }

    function setPayouts(
        address payable _target,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyManager {
        for (uint256 i = 0; i < _ids.length; i++) {
            tokenPrices[_ids[i]] = _amounts[i];
        }
        safeBatchTransferFrom(msg.sender, _target, _ids, _amounts, "");
    }

    function setRights(
        address payable _target,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyManager {
        safeBatchTransferFrom(msg.sender, _target, _ids, _amounts, "");
        // for (uint256 i = 0; i < _ids.length; i++) {}
    }

    function mint(
        address _receiver,
        bool _isPromoteToken,
        uint256 _amount,
        string memory _tokenKey
    ) external onlyManager {
        if (_isPromoteToken) {
            tokenSupply[PrTokenId] += _amount;
            PrToken memory newPrToken = PrToken(countOfPrToken, _tokenKey);
            prTokens.push(newPrToken);
            countOfPrToken++;
            _mint(_receiver, PrTokenId, _amount, "");

            emit Mint(msg.sender, PrTokenId, _amount);
        } else {
            tokenSupply[DTokenId] += _amount;
            _mint(manager, DTokenId, _amount, "");

            emit Mint(msg.sender, DTokenId, _amount);
        }
    }

    function getTargetDeposit(address _target, uint256 _id)
        external
        view
        onlyManager
        returns (uint256)
    {
        return _orderBook[_target][_id];
    }

    function customerDeposit(uint256 _id, uint256 _amount) external payable {
        uint256 payment = msg.value;
        require(payment >= tokenPrices[_id] * _amount);
        require(manager != address(0));

        _orderBook[msg.sender][_id] = _amount;

        emit Order(msg.sender, _id, _amount);
    }

    function fillOrder(
        address payable _target,
        uint256 _id,
        uint256 _amount
    ) external onlyManager {
        tokenSupply[_id] -= _amount;
        _orderBook[_target][_id] = 0;
        safeTransferFrom(msg.sender, _target, _id, _amount, "");
    }

    function _targetDepositBatch(
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external payable {
        require(manager != address(0));
        require(_ids.length == _amounts.length);

        uint256 payment = msg.value;
        uint256 cost;
        for (uint256 i = 0; i < _ids.length; i++) {
            cost += _ids[i] * _amounts[i];
            _orderBook[msg.sender][_ids[i]] = _amounts[i];
        }
        require(payment >= cost);

        emit OrderBatch(msg.sender, _ids, _amounts);
    }

    function fillOrderBatch(
        address payable _target,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) external onlyManager {
        for (uint256 i = 0; i < _ids.length; i++) {
            tokenSupply[_ids[i]] -= _amounts[i];
            _orderBook[_target][_ids[i]] = 0;
        }
        safeBatchTransferFrom(msg.sender, _target, _ids, _amounts, "");
    }

    function getURI(string memory _uri, uint256 _id)
        public
        pure
        returns (string memory)
    {
        return toFullURI(_uri, _id);
    }

    function setURI(string memory _newURI) external onlyManager {
        _setURI(_newURI);
    }

    function uint2str(uint256 _i)
        private
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }

        return string(bstr);
    }

    function toFullURI(string memory _uri, uint256 _id)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(_uri, "/", uint2str(_id & PACK_INDEX), ".json")
            );
    }

    function updateBasisPoint(uint256 _basepoint) external onlyManager {
        basisPoint = _basepoint;
        emit UpdateBasisPoint(basisPoint);
    }

    function paySemiAnnualFeeForFirstTwoYear(bool hasPromoter, address _target)
        external
        onlyManager
    {
        require(subscription.isTwoYear);
        require(block.timestamp >= subscription.nextPayment, "not due yet");
        uint256 semiAnnualFee = 0;
        uint256 tokenId = 0;
        if (hasPromoter) {
            tokenId = PrTokenId;
        } else {
            tokenId = DTokenId;
        }
        semiAnnualFee = _orderBook[_target][tokenId] * (basisPoint / 100);
        tokenSupply[tokenId] += semiAnnualFee;
        _AnualFeeTotal += semiAnnualFee;

        emit PaymentSentForFirstTwoYear(
            _target,
            tokenId,
            semiAnnualFee,
            _AnualFeeTotal,
            block.timestamp
        );

        subscription.nextPayment += payAnnualFrequency;
        subscription.isTwoYear = false;
    }

    function paySemiAnnualFeeForSubsequentYear(address _target)
        external
        onlyManager
    {
        require(!subscription.isTwoYear);
        require(block.timestamp >= subscription.nextPayment, "not due yet");
        uint256 semiAnnualFee = 0;
        semiAnnualFee = _orderBook[_target][DTokenId] * (basisPoint / 100);
        tokenSupply[DTokenId] += semiAnnualFee;
        _AnualFeeTotal += semiAnnualFee;

        emit PaymentSentForSubsequentYear(
            _target,
            semiAnnualFee,
            _AnualFeeTotal,
            block.timestamp
        );

        subscription.nextPayment += payAnnualFrequency;
    }

    function getSpecificPrToken(string memory _prTokenKey)
        external
        view
        returns (string memory)
    {
        uint256 prTokenLength = prTokens.length;
        for (uint256 i = 0; i < prTokenLength; i++) {
            if (
                keccak256(abi.encodePacked(prTokens[i].tokenKey)) ==
                keccak256(abi.encodePacked(_prTokenKey))
            ) {
                return getURI(dTrustUri, i);
            }
        }
        return "";
    }

    function getCountOfPrToken() external view returns (uint256) {
        return prTokens.length;
    }

    function getCurrentPrToken() external view returns (uint256) {
        PrToken memory currentPrToken = prTokens[prTokens.length - 1];
        return currentPrToken.id;
    }

    function schedulePay() external {
        aion = Aion(0xFcFB45679539667f7ed55FA59A15c8Cad73d9a4E);
        bytes memory data = abi.encodeWithSelector(
            bytes4(keccak256("setPayouts()"))
        );
        uint256 callCost = 200000 * 1e9;
        aion.ScheduleCall(
            block.timestamp + paymentInterval,
            address(this),
            0,
            200000,
            1e9,
            data,
            true
        );
    }

}
