// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;
import "@nomiclabs/buidler/console.sol"; // advance debugging
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol"; // --> safe ERC1155 internals

import "./SafeMath.sol";

contract DTRUST {
    DTRUST[] public deployedDTRUSTs;

    function createDTRUST(
        string memory _contractSymbol,
        string memory _newuri,
        string memory _contractName
    ) public {
        DTRUST newDTRUST = new DTRUST(
            _contractName,
            _contractSymbol,
            _newuri,
            msg.sender, 
        );
        deployedDTRUSTs.push(newDTRUST);
    }

    function getDeployedDTRUSTs() public view returns (DTRUST[] memory) {
        return deployedDTRUSTs;
    }

}

interface DTRUSTi {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

contract DTRUST is DTRUSTi, ERC1155 {
    using SafeMath for uint256;
    enum ContractRights {
        TERMINATE,
        SWAP,
        POSTPONE
    }

    enum TokenType {
        DToken,
        PrToken
    }

    struct ControlKey {
        string privateKey;
        address[] settlors;
        address[] beneficiaries;
        address[] trustees;
        bool usable;
        bool burnable;
    }

    uint256 private _AnualFeeTotal;
    uint256 public _Fee = 0.25; // it can be updated later  percent
    uint256 public numControlKey;
    address payable public manager;
    string public name;
    string public symbol;
    string private _uri;
    mapping(uint256 => ControlKey) controlKeys;
    mapping(TokenType => uint256) public tokenType; // tokentype -> id
    mapping(uint256 => uint256) public tokenSupply; // id -> tokensupply
    mapping(uint256 => uint256) public tokenPrices; // id -> tokenPrice
    mapping(address => mapping(uint256 => uint256)) private _orderBook; // address -> id -> amount of asset

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
    ) public ERC1155(_newURI) {
        manager = _deployerAddress;
        name = _contractName;
        symbol = _contractSymbol;
    }

    function setBeneficiary(uint256 _id, uint256 _price) public onlyManager() {
        tokenPrices[_id] = _price;
    }

    function setBeneficiaries(
        address payable _beneficiary,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) public onlyManager() {
        safeBatchTransferFrom(msg.sender, _beneficiary, _ids, _amounts, "");
        for (uint256 i = 0; i < _ids.length; i++) {
            tokenPrices[_ids[i]] = _amounts[i];
        }
    }

    function setPayouts(
        address payable _target,
        uint256[] memory _ids,
        uint256[] memory _amounts
    ) public onlyManager() {
        safeBatchTransferFrom(msg.sender, _target, _ids, _amounts, "");
        for (uint256 i = 0; i < _ids.length; i++) {
            tokenPrices[_ids[i]] = _amounts[i];
        }
    }

    function setRights(
        address payable _target,
        uint256[] memory _ids,
        string[] memory _amounts
    ) public onlyManager() {
        safeBatchTransferFrom(msg.sender, _target, _ids, _amounts, "");
        for (uint256 i = 0; i < _ids.length; i++) {}
    }

    function mint(
        uint256 _id,
        uint256 _amount,
        TokenType _tokenType
    ) public onlyManager() {
        _mint(manager, _id, _amount, "");
        tokenSupply[_id] = _amount;
        tokenType[_tokenType] = _id;
    }

    function mintBatch(
        uint256[] memory _ids,
        uint256[] memory _amounts,
        TokenType[] memory _tokenTypes
    ) public onlyManager() {
        _mintBatch(manager, _ids, _amounts, "");
        for (uint256 i = 0; i < _ids.length; i++) {
            tokenSupply[_ids[i]] = _amounts[i];
            tokenType[_tokenTypes[i]] = _ids[i];
        }
    }

    function get_target(address _target, uint256 _id)
        public
        view
        onlyManager()
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
    ) public onlyManager() {
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
    ) public onlyManager() {
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

    function setURI(string memory _newURI) public onlyManager() {
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

    function updateSemiAnnualFee(uint256 _fee) public onlyManager() {
        _Fee = _fee;
    }

    function paySemiAnnualFeeForFirstTwoYear(uint256 _id, address _target, bool _hasPromoter) public onlyManager() {

        uint256 semiAnnualFee = _orderBook[_target][_id].mul(_Fee.div(100));

        // pay annual fee
        if (_hasPromoter) {
            uint256 prTokenId = tokenType[TokenType.PrToken];
            totalSupply[prTokenId] = totalSupply[prTokenId].add(semiAnnualFee);
        } else {
            uint256 dTokenId = tokenType[TokenType.DToken];
            totalSupply[dTokenId] = totalSupply[dTokenId].add(semiAnnualFee);
        }

        _AnualFeeTotal.add(semiAnnualFee);
    }

    function paySemiAnnualFeeForSubsequentYear(
        address assetHolder,
        uint256 _assetAmount
    ) public onlyManager() {
        
        uint256 semiAnnualFee = _orderBook[_target][_id].mul(_Fee.div(100));

        // pay annual fee
        uint256 dTokenId = tokenType[TokenType.DToken];
        totalSupply[dTokenId] = totalSupply[dTokenId].add(semiAnnualFee);

        _AnualFeeTotal.add(semiAnnualFee);
    }

    function generateControlKeys(
        string memory _privateKey, 
        address[] memory _settlors, 
        address[] memory _beneficiaries, 
        address[] memory _trustees
    ) public returns (uint256 controlKeyId) {
        controlKeyId = numControlKey++;
        controlKeys[controlKeyId] = ControlKey({
            privateKey: _privateKey, 
            settlors: _settlors, 
            beneficiaries: _beneficiaries, 
            trustees: _trustees,
            usable: false, 
            burnable: false
        });
    }
    
    function getControlKey(uint256 _controlKeyId) public view returns (ControlKey memory existControlKey) {
        require(_controlKeyId >= 0, "Control Key must be more than 0");
        require(_controlKeyId <= numControlKey, "ControlKey does not exist.");
        return controlKeys[_controlKeyId];
    }

    function handleUsableControlKeys(uint256 _controlKeyId) public {
        require(_controlKeyId >= 0, "Control Key must be more than 0");
        require(_controlKeyId <= numControlKey, "ControlKey must be less than total");
        ControlKey memory existControlKey = controlKeys[_controlKeyId];
        controlKeys[_controlKeyId] = ControlKey({
            privateKey: existControlKey.privateKey, 
            settlors: existControlKey.settlors,
            beneficiaries: existControlKey.beneficiaries, 
            trustees: existControlKey.trustees,
            usable: !existControlKey.usable, 
            burnable: existControlKey.burnable
        });
    }

    function handleBurnableControlKeys(uint256 _controlKeyId) public {
        require(_controlKeyId >= 0, "Control Key must be more than 0");
        require(_controlKeyId <= numControlKey, "ControlKey must be less than total");
        ControlKey memory existControlKey = controlKeys[_controlKeyId];
        controlKeys[_controlKeyId] = ControlKey({
            privateKey: existControlKey.privateKey, 
            settlors: existControlKey.settlors,
            beneficiaries: existControlKey.beneficiaries, 
            trustees: existControlKey.trustees,
            usable: existControlKey.usable, 
            burnable: !existControlKey.burnable
        });
    }
}