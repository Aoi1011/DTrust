// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "../node_modules/@nomiclabs/buidler/console.sol"; // advance debugging
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC1155/ERC1155.sol"; // --> safe ERC1155 internals
import "../node_modules/@openzeppelin/contracts/utils/Context.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/security/Pausable.sol";

import "./SafeMath.sol";
import "./stringUtils.sol";

contract DTRUSTs {
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
            payable(msg.sender)
        );
        deployedDTRUSTs.push(newDTRUST);
    }

    function getDeployedDTRUSTs() public view returns (DTRUST[] memory) {
        return deployedDTRUSTs;
    }
}

interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;
}

contract BurnValley {
    event TokensDestroyed(address burner, uint256 amount);

    /**
     * @dev Method for burning any token from contract balance.
     * All tokens which will be sent here should be locked forever or burned
     * For better transparency everybody can call this method and burn tokens
     * Emits a {TokensDestroyed} event.
     */
    function burnAllTokens(address _token) external {
        IERC20Burnable token = IERC20Burnable(_token);

        uint256 balance = token.balanceOf(address(this));
        token.burn(balance);

        emit TokensDestroyed(msg.sender, balance);
    }
}

contract DTRUST is ERC1155, Ownable, Pausable {
    // Library///////
    using SafeMath for uint256;
    using StringUtils for string;
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

    struct TokenType {
        uint256 tokenId;
        string tokenName; // PrToekn, DToken
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
    uint256 public percent = 25;
    uint256 public _SemiAnnualFee = percent / 100; // it can be updated later  percent
    uint256 public numControlKey;
    uint256 public constant MIN_DTrust = 40 * 10**18;
    uint256[] public tokenIds;
    address payable public manager;
    address payable public settlor;
    address payable public trustee;
    address public immutable burnValley;
    string public name;
    string public symbol;
    string private _uri;

    IERC20 public constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    // storage//////////////////////////
    mapping(uint256 => ControlKey) controlKeys;
    mapping(uint256 => TokenType) public tokenType; // id -> tokenType
    mapping(uint256 => uint256) public tokenSupply; // id -> tokensupply
    mapping(uint256 => uint256) public tokenPrices; // id -> tokenPrice
    mapping(address => mapping(uint256 => uint256)) private _orderBook; // address -> id -> amount of asset
    mapping(address => uint256) public usdcPerUser;
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
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(address indexed user, uint256 DTrustAmount, uint256 usdcAmount);
    event UsersRemoved(address[] users);
    event UsersWhitelisted(address[] users, uint256[] amounts);
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
        address payable _deployerAddress
    ) ERC1155(_newURI) {
        manager = _deployerAddress;
        name = _contractName;
        symbol = _contractSymbol;
        burnValley = address(new BurnValley());
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
        uint256[] memory _amounts
    ) public onlyManager() {
        safeBatchTransferFrom(msg.sender, _target, _ids, _amounts, "");
        for (uint256 i = 0; i < _ids.length; i++) {}
    }

    function mint(
        uint256 _id,
        string memory _tokenName,
        uint256 _amount
    ) public onlyManager() {
        _mint(manager, _id, _amount, "");
        tokenSupply[_id] = _amount;

        TokenType memory newToken = tokenType[_id];
        newToken.tokenId = _id;
        newToken.tokenName = _tokenName;
        tokenIds.push(_id);
    }

    function mintBatch(
        uint256[] memory _ids,
        string[] memory _tokenNames,
        uint256[] memory _amounts
    ) public onlyManager() {
        _mintBatch(manager, _ids, _amounts, "");
        for (uint256 i = 0; i < _ids.length; i++) {
            tokenSupply[_ids[i]] = _amounts[i];

            TokenType memory newToken = tokenType[_ids[i]];
            newToken.tokenId = _ids[i];
            newToken.tokenName = _tokenNames[i];
            tokenIds.push(_ids[i]);
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

    function allowance(address owner, address spender)
        public
        pure
        returns (uint256)
    {
        return 1;
    }

    function approve(address spender, uint256 value)
        public
        pure
        returns (bool)
    {
        return true;
    }

    function DOMAIN_SEPARATOR() public pure returns (bytes32) {
        bytes32 byteText = "HelloStackOverFlow";
        return byteText;
    }

    function PERMIT_TYPEHASH() public pure returns (bytes32) {
        bytes32 byteText = "HelloStackOverFlow";
        return byteText;
    }

    function nonces(address owner) public pure returns (uint256) {
        return 1;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {}

    function skim(address to) public {}

    function sync() public {}

    function initialize(address, address) public {}

    function burn(address to)
        public
        returns (uint256 amount0, uint256 amount1)
    {}

    function swap(uint256 DTrustAmount, uint256 _id) public {
        require(DTrustAmount >= MIN_DTrust, "swap: Less DTrust then required!");

        address user = _msgSender();
        require(usdcPerUser[user] > 0, "swap: User not allowed to swap!");

        // Transfer user tokens to burn valley contract
        safeTransferFrom(user, burnValley, _id, DTrustAmount, "");

        // Save amount which user will receive
        uint256 usdcAmount = usdcPerUser[user];
        usdcPerUser[user] = 0;

        USDC.safeTransfer(user, usdcAmount);

        // Transfer new tokens to sender
        emit Swap(user, DTrustAmount, usdcAmount);
    }

    function whitelistUsers(
        address[] calldata users,
        uint256[] calldata amounts
    ) external onlyOwner {
        uint256 usersCount = users.length;
        require(
            usersCount == amounts.length,
            "whitelistUsers: Arrays are not equal!"
        );
        require(usersCount > 0, "whitelistUsers: Empty arrays!");

        for (uint256 i = 0; i < usersCount; i++) {
            address user = users[i];
            uint256 amount = amounts[i];

            // Update contract storage with provided values
            usdcPerUser[user] = amount;
        }

        emit UsersWhitelisted(users, amounts);
    }

    function removeUsers(address[] calldata users) external onlyOwner {
        uint256 usersCount = users.length;
        require(usersCount > 0, "removeUsers: Empty array!");

        for (uint256 i = 0; i < usersCount; i++) {
            address user = users[i];
            usdcPerUser[user] = 0;
        }

        emit UsersRemoved(users);
    }

    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function withdrawUsdc(address receiver) external onlyOwner {
        USDC.safeTransfer(receiver, USDC.balanceOf(address(this)));
    }

    function withdrawUsdc(address receiver, uint256 amount) external onlyOwner {
        USDC.safeTransfer(receiver, amount);
    }

    function totalSupply() public view returns (uint256) {}

    function balanceOf(address owner) public view returns (uint256) {}

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {}

    function transfer(address to, uint256 value) public returns (bool) {}

    function updateSemiAnnualFee(uint256 _percent) public onlyManager() {
        percent = _percent;
    }

    function paySemiAnnualFeeForFirstTwoYear(
        uint256 _id,
        address _target,
        bool _hasPromoter
    ) public onlyManager() {
        uint256 semiAnnualFee = _orderBook[_target][_id].mul(
            _SemiAnnualFee.div(100)
        );
        TokenType memory t = tokenType[_id];

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
        onlyManager()
    {
        uint256 semiAnnualFee = _orderBook[_target][_id].mul(
            _SemiAnnualFee.div(100)
        );

        // pay annual fee
        tokenSupply[_id] = tokenSupply[_id].add(semiAnnualFee);

        _AnualFeeTotal.add(semiAnnualFee);
    }

    function generateControlKey(
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

    function getControlKey(uint256 _controlKeyId)
        public
        view
        returns (ControlKey memory existControlKey)
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

    function handleBurnableControlKey(uint256 _controlKeyId) public {
        require(_controlKeyId >= 0, "Control Key must be more than 0");
        require(
            _controlKeyId <= numControlKey,
            "ControlKey must be less than total"
        );
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

    function destroyControlKey(uint256 _controlKeyId) public {
        require(_controlKeyId >= 0, "Control Key must be more than 0");
        require(
            _controlKeyId <= numControlKey,
            "ControlKey must be less than total"
        );

        ControlKey memory existControlKey = controlKeys[_controlKeyId];
        require(existControlKey.burnable, "Can not destroy.");

        delete controlKeys[_controlKeyId];
    }
}
