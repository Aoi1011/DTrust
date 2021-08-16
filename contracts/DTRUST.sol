// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/SchedulerInterface.sol";
import "./interfaces/IMyERC20.sol";
import "./interfaces/IMyERC721.sol";
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

    struct ERC20TokenAsset {
        IMyERC20 erc20;
        uint256 erc20TokenId;
        uint256 erc20Payment;
        address currentScheduledTransaction;
        uint256 paymentInterval;
        uint256 lockedUntil;
    }

    struct ERC721TokenAsset {
        IMyERC721 erc721;
        uint256 erc721TokenId;
        address currentScheduledTransaction;
        uint256 paymentInterval;
        uint256 lockedUntil;
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

    SchedulerInterface public scheduler;

    uint256 private _AnualFeeTotal = 0;
    uint256 public basisPoint = 1; // for 2 year
    uint256 public countOfPrToken = 1;
    uint256 public payAnnualFrequency = 730 days;
    // uint256[] public erc20PaymentIntervals;
    // uint256[] public erc721PaymentIntervals;
    // uint256[] public erc20LockedUntils;
    // uint256[] public erc721LockedUntils;
    uint256[] private erc20assetIds;
    uint256[] private erc721assetIds;
    address payable public manager;
    address payable public settlor;
    address payable public trustee;
    address public beneficiary;
    // address[] public currentScheduledTransactionsForERC20;
    // address[] public currentScheduledTransactionsForERC721;
    string public name;
    string public symbol;
    string public dTrustUri;
    ERC20TokenAsset[] public erc20TokenAssets;
    ERC721TokenAsset[] public erc721TokenAssets;
    PrTokenStruct[] public prTokens;
    Subscription private subscription;

    // storage//////////////////////////
    mapping(uint256 => bool) public existToken;
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
        address[] indexed scheduledTransactionForERC20,
        address[] indexed schediledTransactionForERC721,
        address recipient
    );
    event PaymentExecuted(
        address indexed scheduledTransaction,
        address recipient,
        uint256 value
    );
    event PayToBeneficiary(uint256[] ids, uint256[] amounts);
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
        address payable _trustee
        // uint256[] memory _erc20PpaymentIntervals,
        // uint256[] memory _erc721PaymentIntervals
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
        // erc20PaymentIntervals = _erc20PpaymentIntervals;
        // erc721PaymentIntervals = _erc721PaymentIntervals;

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

    receive() external payable {}

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

    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity,
        bytes memory _data
    ) public onlyManager {
        _mint(_to, _id, _quantity, _data);
        tokenSupply[_id] += _quantity;
    }

    function mintBatch(
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public onlyManager {
        _mintBatch(manager, _ids, _amounts, _data);
        for (uint256 i = 0; i < _ids.length; i++) {
            existToken[_ids[i]] = true;
            tokenSupply[_ids[i]] = _amounts[i];
        }
    }

    function depositERC20Assets(
        IMyERC20[] memory erc20s,
        uint256[] memory _amounts,
        bytes calldata _data,
        uint256[] memory _paymentPerFrequency
    ) external payable onlyManager {
        for (uint256 i = 0; i < erc20s.length; i++) {
            uint256 id = uint256(uint160(address(erc20s[i])));
            erc20assetIds.push(id);
            ERC20TokenAsset memory newerc20 = ERC20TokenAsset(
                erc20s[i],
                id,
                _paymentPerFrequency[i]
            );
            erc20TokenAssets.push(newerc20);
            _orderBook[manager][id] = _amounts[i];

            require(
                erc20s[i].transferFrom(manager, address(this), _amounts[i]),
                "Cannot transfer."
            );
        }
        mintBatch(erc20assetIds, _amounts, _data);

        emit OrderBatch(manager, erc20assetIds, _amounts);
    }

    function depositERC721Assets(
        IMyERC721[] calldata _erc721Tokens,
        bytes calldata _data
    ) external payable onlyManager {
        uint256[] memory amounts = new uint256[](_erc721Tokens.length);
        for (uint256 i = 0; i < _erc721Tokens.length; i++) {
            uint256 _erc1155TokenId = _tokenHash(_erc721Tokens[i]);
            erc721assetIds.push(_erc1155TokenId);
            ERC721TokenAsset memory newerc721 = ERC721TokenAsset(
                _erc721Tokens[i],
                _erc1155TokenId
            );
            erc721TokenAssets.push(newerc721);
            amounts[i] = 1;
            _orderBook[manager][_erc1155TokenId] = 1;
            _erc721Tokens[i].transferFrom(
                manager,
                address(this),
                _erc1155TokenId
            );
        }

        mintBatch(erc721assetIds, amounts, _data);

        emit OrderBatch(manager, erc721assetIds, amounts);
    }

    function getTargetDeposit(uint256 _id)
        external
        view
        onlyManager
        returns (uint256)
    {
        return _orderBook[manager][_id];
    }

    function withdrawERC20Assets(
        ERC20TokenAsset[] memory erc20s,
        uint256[] memory _amounts
    ) internal {
        for (uint256 i = 0; i < erc20s.length; i++) {
            uint256 id = uint256(uint160(address(erc20s[i].erc20)));
            require(existToken[id], "Does not exist");
            erc20assetIds.push(id);
            for (uint256 j = 0; j < erc20TokenAssets.length; j++) {
                if (id == erc20TokenAssets[j].erc20TokenId) {
                    erc20TokenAssets[j] = erc20TokenAssets[
                        erc20TokenAssets.length - 1
                    ];
                    erc20TokenAssets.pop();
                    return;
                }
            }
            _orderBook[manager][id] -= _amounts[i];

            require(
                erc20s[i].erc20.transfer(beneficiary, _amounts[i]),
                "Cannot transfer."
            );
        }
        _burnBatch(msg.sender, erc20assetIds, _amounts);

        emit PayToBeneficiary(erc20assetIds, _amounts);
    }

    function withdrawERC721Assets(IMyERC721[] memory _erc721Tokens) internal {
        uint256[] memory amounts = new uint256[](_erc721Tokens.length);
        for (uint256 i = 0; i < _erc721Tokens.length; i++) {
            uint256 tokenId = _tokenHash(_erc721Tokens[i]);
            require(existToken[tokenId], "Does not exist!");
            erc721assetIds.push(tokenId);
            for (uint256 j = 0; j < erc721TokenAssets.length; j++) {
                if (tokenId == erc721TokenAssets[j].erc721TokenId) {
                    erc721TokenAssets[j] = erc721TokenAssets[
                        erc721TokenAssets.length - 1
                    ];
                    erc721TokenAssets.pop();
                    return;
                }
            }
            _orderBook[msg.sender][tokenId] = 0;
            amounts[i] = 1;
            _erc721Tokens[i].transferFrom(address(this), beneficiary, tokenId);
        }
        _burnBatch(msg.sender, erc721assetIds, amounts);
        emit PayToBeneficiary(erc721assetIds, amounts);
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

    function process() internal {
        uint256 lengthOfERC20Assets = erc20TokenAssets.length;
        uint256 lengthOfERC721Assets = erc721TokenAssets.length;
        IMyERC20[] memory erc20sForWithdrawing = new IMyERC20[](
            lengthOfERC20Assets
        );
        uint256[] memory paymentsForWithdrawing = new uint256[](
            lengthOfERC20Assets
        );
        IMyERC721[] memory erc721ForWidthdrawing = new IMyERC721[](
            lengthOfERC721Assets
        );

        for (uint256 i = 0; i < lengthOfERC20Assets; i++) {
            erc20sForWithdrawing[i] = erc20TokenAssets[i].erc20;
            paymentsForWithdrawing[i] = erc20TokenAssets[i].erc20Payment;
        }

        for (uint256 j = 0; j < lengthOfERC721Assets; j++) {
            erc721ForWidthdrawing[j] = erc721TokenAssets[j].erc721;
        }

        withdrawERC20Assets(erc20TokenAssets, paymentsForWithdrawing);
        withdrawERC721Assets(erc721ForWidthdrawing);
        schedule();
    }

    function schedule() internal {
        for (uint256 i = 0; i < erc20TokenAssets.length; i++) {
            erc20okenAssets[i].lockedUntils = block.timestamp + erc20TokenAssets[i].paymentInterval;
            erc20okenAssets[i].currentScheduledTransaction = scheduler.schedule(
                address(this),
                "",
                [
                    1000000,
                    0,
                    255,
                    erc20okenAssets[i].lockedUntils,
                    20000000000 wei,
                    20000000000 wei,
                    20000000000 wei,
                    30000000000 wei
                ]
            );
        }

        for (uint256 i = 0; i < erc721TokenAssets.length; i++) {
            erc721TokenAssets[i].lockedUntils = block.timestamp + erc721TokenAssets[i].paymentInterval;
            erc721TokenAssets[i].currentScheduledTransaction = scheduler.schedule(
                address(this),
                "",
                [
                    1000000,
                    0,
                    255,
                    erc721TokenAssets[i].lockedUntils,
                    20000000000 wei,
                    20000000000 wei,
                    20000000000 wei,
                    30000000000 wei
                ]
            );
        }

        emit PaymentScheduled(
            currentScheduledTransaction,
            currentScheduledTransaction,
            beneficiary
        );
    }

    function _tokenHash(IMyERC721 erc721token)
        internal
        virtual
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(erc721token)));
    }
}
