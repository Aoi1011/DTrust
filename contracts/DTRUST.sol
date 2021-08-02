// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "../node_modules/@nomiclabs/buidler/console.sol"; // advance debugging
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol"; // --> safe ERC1155 internals
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libraries/SafeMath.sol";

contract DTRUST is ERC1155 {
    // Library///////
    using SafeMath for uint256;
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

    uint256 private _AnualFeeTotal;
    uint256 public percent = 25;
    uint256 public _SemiAnnualFee = percent.div(100);
    // uint256[] public tokenIds;
    uint256 public countOfPrToken = 1;
    address payable public manager;
    address payable public settlor;
    address payable public trustee;
    address public beneficiary;
    string public name;
    string public symbol;
    string public dTrustUri;
    PrToken[] public prTokens;

    // storage//////////////////////////
    // mapping(uint256 => Token) public token; // id -> Token
    mapping(uint256 => uint256) public tokenSupply; // id -> tokensupply
    mapping(uint256 => uint256) public tokenPrices; // id -> tokenPrice
    mapping(address => mapping(uint256 => uint256)) private _orderBook; // address -> id -> amount of asset
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
        string memory _contractName,
        string memory _contractSymbol,
        string memory _newURI,
        address payable _deployerAddress,
        address payable _settlor,
        address _beneficiary,
        address payable _trustee
    ) ERC1155(_newURI) {
        name = _contractName;
        symbol = _contractSymbol;
        dTrustUri = _newURI;
        manager = _deployerAddress;
        settlor = _settlor;
        beneficiary = _beneficiary;
        trustee = _trustee;
    }

    function setBeneficiaryAsset(uint256 _id, uint256 _price)
        public
        onlyManager
    {
        tokenPrices[_id] = _price;
    }

    function setBeneficiariesAssets(
        address payable _beneficiary,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) public onlyManager {
        safeBatchTransferFrom(msg.sender, _beneficiary, _ids, _amounts, "");
        for (uint256 i = 0; i < _ids.length; i++) {
            tokenPrices[_ids[i]] = _amounts[i];
        }
    }

    function setPayouts(
        address payable _target,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) public onlyManager {
        safeBatchTransferFrom(msg.sender, _target, _ids, _amounts, "");
        for (uint256 i = 0; i < _ids.length; i++) {
            tokenPrices[_ids[i]] = _amounts[i];
        }
    }

    function setRights(
        address payable _target,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) public onlyManager {
        safeBatchTransferFrom(msg.sender, _target, _ids, _amounts, "");
        for (uint256 i = 0; i < _ids.length; i++) {}
    }

    function mint(
        bool _isPromoteToken,
        uint256 _amount,
        string memory _tokenKey
    ) public {
        if (_isPromoteToken) {
            _mint(manager, PrTokenId, _amount, "");
            tokenSupply[PrTokenId] += _amount;

            PrToken memory newPrToken = PrToken(countOfPrToken, _tokenKey);
            prTokens.push(newPrToken);
            countOfPrToken++;

            emit Mint(msg.sender, PrTokenId, _amount);
        } else {
            _mint(manager, DTokenId, _amount, "");
            tokenSupply[DTokenId] += _amount;

            emit Mint(msg.sender, DTokenId, _amount);
        }
    }

    function get_target(address _target, uint256 _id)
        public
        view
        onlyManager
        returns (uint256)
    {
        return _orderBook[_target][_id];
    }

    function customerDeposit(uint256 _id, uint256 _amount) external payable {
        uint256 payment = msg.value;
        require(payment >= tokenPrices[_id].mul(_amount));
        require(manager != address(0));

        _orderBook[msg.sender][_id] = _amount;

        emit Order(msg.sender, _id, _amount);
    }

    function fillOrder(
        address payable _target,
        uint256 _id,
        uint256 _amount
    ) public onlyManager {
        safeTransferFrom(msg.sender, _target, _id, _amount, "");
        tokenSupply[_id] -= _amount;
        _orderBook[_target][_id] = 0;
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
            cost += _ids[i].mul(_amounts[i]);
            _orderBook[msg.sender][_ids[i]] = _amounts[i];
        }
        require(payment >= cost);

        emit OrderBatch(msg.sender, _ids, _amounts);
    }

    function fillOrderBatch(
        address payable _target,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) public onlyManager {
        safeBatchTransferFrom(msg.sender, _target, _ids, _amounts, "");
        for (uint256 i = 0; i < _ids.length; i++) {
            tokenSupply[_ids[i]] -= _amounts[i];
            _orderBook[_target][_ids[i]] = 0;
        }
    }

    function getURI(string memory _uri, uint256 _id)
        public
        pure
        returns (string memory)
    {
        return toFullURI(_uri, _id);
        // return dTrustUri;
    }

    function setURI(string memory _newURI) public onlyManager {
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
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
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

    function updateSemiAnnualFee(uint256 _percent) public onlyManager {
        percent = _percent;
    }

    function paySemiAnnualFeeForFirstTwoYear(bool isPrToken, address _target)
        public
        onlyManager
    {
        uint256 semiAnnualFee = 0;
        if (isPrToken) {
            semiAnnualFee = _orderBook[_target][PrTokenId].mul(
                _SemiAnnualFee.div(100)
            );
            tokenSupply[PrTokenId] = tokenSupply[PrTokenId].add(semiAnnualFee);
        } else {
            semiAnnualFee = _orderBook[_target][DTokenId].mul(
                _SemiAnnualFee.div(100)
            );
            tokenSupply[DTokenId] = tokenSupply[DTokenId].add(semiAnnualFee);
        }

        _AnualFeeTotal.add(semiAnnualFee);
    }

    function paySemiAnnualFeeForSubsequentYear(bool isPrToken, address _target)
        public
        onlyManager
    {
        uint256 semiAnnualFee = 0;
        if (isPrToken) {
            semiAnnualFee = _orderBook[_target][PrTokenId].mul(
                _SemiAnnualFee.div(100)
            );
            tokenSupply[PrTokenId] = tokenSupply[PrTokenId].add(semiAnnualFee);
        } else {
            semiAnnualFee = _orderBook[_target][DTokenId].mul(
                _SemiAnnualFee.div(100)
            );
            tokenSupply[DTokenId] = tokenSupply[DTokenId].add(semiAnnualFee);
        }

        _AnualFeeTotal.add(semiAnnualFee);
    }

    function getSpecificPrToken(string memory _prTokenKey)
        public
        view
        returns (string memory)
    {
        for (uint256 i = 0; i < prTokens.length; i++) {
            if (
                keccak256(abi.encodePacked(prTokens[i].tokenKey)) ==
                keccak256(abi.encodePacked(_prTokenKey))
            ) {
                return getURI(dTrustUri, i);
            }
        }
        return "";
    }

    function getCountOfPrToken() public view returns (uint256) {
        return prTokens.length;
    }

    function getCurrentPrToken() public view returns (uint256) {
        PrToken memory currentPrToken = prTokens[prTokens.length - 1];
        return currentPrToken.id;
    }
}
