// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/Aion.sol";
import "./interfaces/SchedulerInterface.sol";
import "./interfaces/IMyERC20.sol";
import "./libraries/Strings.sol";

contract DTRUST is ERC1155 {
    // Library///////
    using Strings for string;
    /////////////////

    // constants/////
    uint256 private constant PACK_INDEX =
        0x0000000000000000000000000000000000000000000000000000000000007FFF;
    uint256 private constant PrToken = 0;
    uint256 private constant DToken = 1;
    /////////////////

    enum ContractRights {
        TERMINATE,
        SWAP,
        POSTPONE
    }

    struct PrTokenStruct {
        uint256 id;
        string tokenKey;
    }

    struct Subscription {
        uint256 start;
        uint256 nextPayment;
        bool isTwoYear;
    }

    Aion public aion;
    SchedulerInterface public scheduler;

    uint256 private _AnualFeeTotal = 0;
    uint256 public basisPoint = 1; // for 2 year
    uint256 public countOfPrToken = 1;
    uint256 public payAnnualFrequency = 730 days;
    uint256 public paymentInterval;
    uint256 public lockedUntil;
    uint256[] private assetIds;
    address payable public manager;
    address payable public settlor;
    address payable public trustee;
    address public beneficiary;
    address public currentScheduledTransaction;
    string public name;
    string public symbol;
    string public dTrustUri;
    PrTokenStruct[] public prTokens;
    Subscription private subscription;

    // storage//////////////////////////
    mapping(uint256 => address) public creators;
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
    event TransferBatch(
        address indexed from,
        address indexed to,
        uint256[] value
    );
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
        address recipient
    );
    event PaymentExecuted(
        address indexed scheduledTransaction,
        address recipient,
        uint256 value
    );
    event BorrowedERC20(
        IMyERC20 erc20,
        address sender,
        uint256 amount,
        address from,
        address to,
        bytes data
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
        uint256 _paymentInterval
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

        scheduler = SchedulerInterface(_deployerAddress);
        paymentInterval = _paymentInterval;

        subscription = Subscription(
            block.timestamp,
            block.timestamp + payAnnualFrequency,
            true
        );

        schedule();
    }

    fallback() external payable {
        if (msg.value > 0) {
            //this handles recieving remaining funds sent while scheduling (0.1 ether)
            return;
        }

        process();
    }

    function setURI(string memory _newURI) public onlyManager {
        _setURI(_newURI);
    }

    function getURI(string memory _uri, uint256 _id)
        public
        pure
        returns (string memory)
    {
        return toFullURI(_uri, _id);
    }

    function toFullURI(string memory _uri, uint256 _id)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    _uri,
                    "/",
                    Strings.uint2str(_id & PACK_INDEX),
                    ".json"
                )
            );
    }

    function create(
        uint256 _initialSupply,
        string calldata _uri,
        bytes calldata _data
    ) external {}

    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) external {
        _mint(_to, _id, _quantity, _data);
        tokenSupply[_id] += _quantity;
    }

    function borrowERC20(
        IMyERC20 erc20,
        uint256 _amount,
        address _from,
        address _to,
        bytes calldata _data
    ) public {
        _mint(_to, uint256(address(erc20)), _amount, _data);
        require(
            erc20.transferFrom(_from, address(this), _amount),
            "Cannot transfer."
        );
        emit BorrowedERC20(erc20, msg.sender, _amount, _from, _to, _data);
    }

    function depositAsset(address _tokenAddress, uint256 _amount)
        external
        payable
    {
        uint256 payment = msg.value;
        // require(payment >= tokenPrices[_id] * (_amount));
        require(manager != address(0));
        // require(_exists(_id), "Does not exist!");
        ERC1155 ERC1155interface;
        ERC1155interface = ERC1155(_tokenAddress);
        ERC1155interface.transferFrom(msg.sender, address(this), _amount);
        assetIds.push(_id);

        _orderBook[msg.sender][_id] = _amount;
        emit Order(msg.sender, _id, _amount);

        safeTransferFrom(msg.sender, address(this), _id, _amount, "");
        emit Transfer(address(this), msg.sender, _amount);
    }

    function depositAssetBatch(
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external payable {
        require(manager != address(0));
        require(_ids.length == _amounts.length);

        uint256 payment = msg.value;
        uint256 cost;
        for (uint256 i = 0; i < _ids.length; i++) {
            require(_exists(_ids[i]), "Does not exist!");

            assetIds.push(_ids[i]);

            cost += _ids[i] * _amounts[i];
            _orderBook[msg.sender][_ids[i]] = _amounts[i];
        }
        require(payment >= cost);

        emit OrderBatch(msg.sender, _ids, _amounts);

        safeBatchTransferFrom(msg.sender, address(this), _ids, _amounts, "");
        emit TransferBatch(address(this), msg.sender, _amounts);
    }

    function getTargetDeposit(address _target, uint256 _id)
        external
        view
        onlyManager
        returns (uint256)
    {
        return _orderBook[_target][_id];
    }

    function payToBeneficiary() external {}

    function fillOrder(uint256 _id, uint256 _amount) internal onlyManager {
        tokenSupply[_id] -= _amount;
        _orderBook[beneficiary][_id] = 0;
        safeTransferFrom(msg.sender, beneficiary, _id, _amount, "");
    }

    function fillOrderBatch(uint256[] memory _ids, uint256[] memory _amounts)
        internal
        onlyManager
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            tokenSupply[_ids[i]] -= _amounts[i];
            _orderBook[beneficiary][_ids[i]] = 0;
        }
        safeBatchTransferFrom(msg.sender, beneficiary, _ids, _amounts, "");
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
            tokenId = PrToken;
        } else {
            tokenId = DToken;
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
        semiAnnualFee = _orderBook[_target][DToken] * (basisPoint / 100);
        tokenSupply[DToken] += semiAnnualFee;
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
        PrTokenStruct memory currentPrToken = prTokens[prTokens.length - 1];
        return currentPrToken.id;
    }

    function schedulePay() external {
        aion = Aion(0xFcFB45679539667f7ed55FA59A15c8Cad73d9a4E);
        bytes memory data = abi.encodeWithSelector(
            bytes4(keccak256("setPayouts()"))
        );
        // uint256 callCost = 200000 * 1e9;
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

    function _exists(uint256 _id) internal view returns (bool) {
        return creators[_id] != address(0);
    }

    function process() internal {
        fillOrder(_id, _amount);
        fillOrderBatch(_ids, _amounts);
        schedule();
    }

    function schedule() internal {
        lockedUntil = block.timestamp + paymentInterval;

        currentScheduledTransaction = scheduler.schedule(
            address(this),
            "",
            [
                1000000, // The amount of gas to be sent with the transaction. Accounts for payout + new contract deployment
                0, // The amount of wei to be sent.
                255, // The size of the execution window.
                lockedUntil, // The start of the execution window.
                20000000000 wei, // The gasprice for the transaction (aka 20 gwei)
                20000000000 wei, // The fee included in the transaction.
                20000000000 wei, // The bounty that awards the executor of the transaction.
                30000000000 wei
            ]
        );

        emit PaymentScheduled(currentScheduledTransaction, beneficiary);
    }
}
