// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;
import "@nomiclabs/buidler/console.sol"; // advance debugging
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol"; // --> safe ERC1155 internals
import "./dTrustToken.sol";

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
            msg.sender
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

    uint256 private _AnualFeeTotal;
    uint256 public _Fee = 0.25; // it can be updated later
    address payable public manager;
    address addressDTrustToken;
    string public name;
    string public symbol;
    string private _uri;
    mapping(uint256 => uint256) public tokenSupply; // id -> tokensupply
    mapping(uint256 => uint256) public tokenPrices; // id -> tokenPrice
    mapping(address => mapping(uint256 => uint256)) private _orderBook; // address -> id -> amount


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
        address payable _deployerAddress
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

    function mint(uint256 _id, uint256 _amount) public onlyManager() {
        _mint(manager, _id, _amount, "");
        tokenSupply[_id] = _amount;
    }

    function mintBatch(uint256[] memory _ids, uint256[] memory _amounts)
        public
        onlyManager()
    {
        _mintBatch(manager, _ids, _amounts, "");
        for (uint256 i = 0; i < _ids.length; i++) {
            tokenSupply[_ids[i]] = _amounts[i];
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

    function setAddressDTrustToken(address _addressDTrustToken) public {
        addressDTrustToken = _addressDTrustToken;
    }

    function updateSemiAnnualFee(uint256 _fee) public onlyManager() {
        _Fee = _fee;
    }

    function paySemiAnnualFeeForFirstYear(
        address assetHolder,
        uint256 _assetAmount,
        bool hasPromoter,
        uint256 _id
    ) public onlyManager() returns (bool) {
        require(_assetAmount > 0, "Assset amount should be more than 0");

        uint256 semiAnnualFee = _assetAmount.sub(_Fee);
        // pay annual fee
        if (hasPromoter) {
            // Prmote token
            mint(_id, semiAnnualFee);
            _AnualFeeTotal.add(semiAnnualFee);
            return true;
        } else {
            // DTrustToken
            dTrustToken token = dTrustToken(addressDTrustToken);
            token._mint(assetHolder, semiAnnualFee);
            _AnualFeeTotal.add(semiAnnualFee);
            return true;
        }
        return false;
    }

    function paySemiAnnualFeeForSubsequentYear(
        address assetHolder,
        uint256 _assetAmount
    ) public onlyManager() returns (bool) {
        require(_assetAmount > 0, "Assset amount should be more than 0");
        uint256 semiAnnualFee = _assetAmount.sub(_Fee);
        dTrustToken token;
        token._mint(assetHolder, semiAnnualFee);
        _AnualFeeTotal.add(semiAnnualFee);
        return true;
    }
}
