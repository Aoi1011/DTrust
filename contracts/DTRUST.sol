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
    /////////////////

    enum ContractRights {
        TERMINATE,
        SWAP,
        POSTPONE
    }

    struct Token {
        uint256 tokenId;
        string tokenName; // PrToekn, DToken
        string tokenKey;
    }

    uint256 private _AnualFeeTotal;
    uint256 public percent = 25;
    uint256 public _SemiAnnualFee = percent.div(100);
    uint256[] public tokenIds;
    address payable public manager;
    address payable public settlor;
    address payable public trustee;
    address public beneficiary;
    string public name;
    string public symbol;
    string private _uri;

    // storage//////////////////////////
    mapping(uint256 => Token) public token; // id -> Token
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
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
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
        uint256 _id,
        string memory _tokenName,
        uint256 _amount,
        string memory _tokenKey
    ) public onlyManager {
        _mint(manager, _id, _amount, "");
        tokenSupply[_id] += _amount;

        Token memory newToken = token[_id];
        newToken.tokenId = _id;
        newToken.tokenName = _tokenName;
        newToken.tokenKey = _tokenKey;
        tokenIds.push(_id);
    }

    function mintBatch(
        uint256[] memory _ids,
        string[] memory _tokenNames,
        uint256[] memory _amounts,
        string[] memory _tokenKeys
    ) public onlyManager {
        _mintBatch(manager, _ids, _amounts, "");
        for (uint256 i = 0; i < _ids.length; i++) {
            tokenSupply[_ids[i]] += _amounts[i];

            Token memory newToken = token[_ids[i]];
            newToken.tokenId = _ids[i];
            newToken.tokenName = _tokenNames[i];
            newToken.tokenKey = _tokenKeys[i];
            tokenIds.push(_ids[i]);
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

    function getURI(string memory uri, uint256 _id)
        public
        pure
        returns (string memory)
    {
        return toFullURI(uri, _id);
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

    function toFullURI(string memory uri, uint256 _id)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(uri, "/", uint2str(_id & PACK_INDEX), ".json")
            );
    }

    function updateSemiAnnualFee(uint256 _percent) public onlyManager {
        percent = _percent;
    }

    function paySemiAnnualFeeForFirstTwoYear(
        uint256 _id,
        address _target,
        bool _hasPromoter
    ) public onlyManager {
        uint256 semiAnnualFee = _orderBook[_target][_id].mul(
            _SemiAnnualFee.div(100)
        );
        Token memory t = token[_id];

        // pay annual fee
        if (
            _hasPromoter &&
            keccak256(abi.encodePacked(t.tokenName)) ==
            keccak256(abi.encodePacked("PrToken"))
        ) {
            // uint256 prTokenId = tokenType[TokenType.PrToken];
            tokenSupply[_id] = tokenSupply[_id].add(semiAnnualFee);
        } else {
            // uint256 dTokenId = tokenType[TokenType.DToken];
            tokenSupply[_id] = tokenSupply[_id].add(semiAnnualFee);
        }

        _AnualFeeTotal.add(semiAnnualFee);
    }

    function paySemiAnnualFeeForSubsequentYear(uint256 _id, address _target)
        public
        onlyManager
    {
        uint256 semiAnnualFee = _orderBook[_target][_id].mul(
            _SemiAnnualFee.div(100)
        );

        // pay annual fee
        tokenSupply[_id] = tokenSupply[_id].add(semiAnnualFee);

        _AnualFeeTotal.add(semiAnnualFee);
    }
}
