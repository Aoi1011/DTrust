// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/ownership/Ownable.sol";

// library SafeMath {
//     /**
//      * @dev Returns the addition of two unsigned integers, reverting on
//      * overflow.
//      *
//      * Counterpart to Solidity's `+` operator.
//      *
//      * Requirements:
//      *
//      * - Addition cannot overflow.
//      */
//     function add(uint256 a, uint256 b) internal pure returns (uint256) {
//         uint256 c = a + b;
//         require(c >= a, "SafeMath: addition overflow");

//         return c;
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting on
//      * overflow (when the result is negative).
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      *
//      * - Subtraction cannot overflow.
//      */
//     function sub(uint256 a, uint256 b) internal pure returns (uint256) {
//         return sub(a, b, "SafeMath: subtraction overflow");
//     }

//     /**
//      * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
//      * overflow (when the result is negative).
//      *
//      * Counterpart to Solidity's `-` operator.
//      *
//      * Requirements:
//      *
//      * - Subtraction cannot overflow.
//      */
//     function sub(
//         uint256 a,
//         uint256 b,
//         string memory errorMessage
//     ) internal pure returns (uint256) {
//         require(b <= a, errorMessage);
//         uint256 c = a - b;

//         return c;
//     }

//     /**
//      * @dev Returns the multiplication of two unsigned integers, reverting on
//      * overflow.
//      *
//      * Counterpart to Solidity's `*` operator.
//      *
//      * Requirements:
//      *
//      * - Multiplication cannot overflow.
//      */
//     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
//         // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
//         // benefit is lost if 'b' is also tested.
//         // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
//         if (a == 0) {
//             return 0;
//         }

//         uint256 c = a * b;
//         require(c / a == b, "SafeMath: multiplication overflow");

//         return c;
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers. Reverts on
//      * division by zero. The result is rounded towards zero.
//      *
//      * Counterpart to Solidity's `/` operator. Note: this function uses a
//      * `revert` opcode (which leaves remaining gas untouched) while Solidity
//      * uses an invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function div(uint256 a, uint256 b) internal pure returns (uint256) {
//         return div(a, b, "SafeMath: division by zero");
//     }

//     /**
//      * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
//      * division by zero. The result is rounded towards zero.
//      *
//      * Counterpart to Solidity's `/` operator. Note: this function uses a
//      * `revert` opcode (which leaves remaining gas untouched) while Solidity
//      * uses an invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function div(
//         uint256 a,
//         uint256 b,
//         string memory errorMessage
//     ) internal pure returns (uint256) {
//         require(b > 0, errorMessage);
//         uint256 c = a / b;
//         // assert(a == b * c + a % b); // There is no case in which this doesn't hold

//         return c;
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * Reverts when dividing by zero.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
//         return mod(a, b, "SafeMath: modulo by zero");
//     }

//     /**
//      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
//      * Reverts with custom message when dividing by zero.
//      *
//      * Counterpart to Solidity's `%` operator. This function uses a `revert`
//      * opcode (which leaves remaining gas untouched) while Solidity uses an
//      * invalid opcode to revert (consuming all remaining gas).
//      *
//      * Requirements:
//      *
//      * - The divisor cannot be zero.
//      */
//     function mod(
//         uint256 a,
//         uint256 b,
//         string memory errorMessage
//     ) internal pure returns (uint256) {
//         require(b != 0, errorMessage);
//         return a % b;
//     }
// }

// contract Pausable is Context {
//     /**
//      * @dev Emitted when the pause is triggered by `account`.
//      */
//     event Paused(address account);

//     /**
//      * @dev Emitted when the pause is lifted by `account`.
//      */
//     event Unpaused(address account);

//     bool private _paused;

//     /**
//      * @dev Initializes the contract in unpaused state.
//      */
//     constructor() {
//         _paused = false;
//     }

//     /**
//      * @dev Returns true if the contract is paused, and false otherwise.
//      */
//     function paused() public view returns (bool) {
//         return _paused;
//     }

//     /**
//      * @dev Modifier to make a function callable only when the contract is not paused.
//      *
//      * Requirements:
//      *
//      * - The contract must not be paused.
//      */
//     modifier whenNotPaused() {
//         require(!_paused, "Pausable: paused");
//         _;
//     }

//     /**
//      * @dev Modifier to make a function callable only when the contract is paused.
//      *
//      * Requirements:
//      *
//      * - The contract must be paused.
//      */
//     modifier whenPaused() {
//         require(_paused, "Pausable: not paused");
//         _;
//     }

//     /**
//      * @dev Triggers stopped state.
//      *
//      * Requirements:
//      *
//      * - The contract must not be paused.
//      */
//     function _pause() internal virtual whenNotPaused {
//         _paused = true;
//         emit Paused(_msgSender());
//     }

//     /**
//      * @dev Returns to normal state.
//      *
//      * Requirements:
//      *
//      * - The contract must be paused.
//      */
//     function _unpause() internal virtual whenPaused {
//         _paused = false;
//         emit Unpaused(_msgSender());
//     }
// }

// contract DTrustToken is ERC20 {
//     using SafeMath for uint256;

//     mapping(address => uint256) balances;
//     mapping(address => mapping(address => uint256)) allowed;

//     uint256 totalSupply_;

//     constructor(
//         string memory _name,
//         string memory _symbol,
//         uint256 _totalSupply
//     ) public ERC20(_name, _symbol) {
//         totalSupply_ = _totalSupply;
//     }

//     function totalSupply() public view override returns (uint256) {
//         return totalSupply_;
//     }

//     function balanceOf(address tokenOwner)
//         public
//         view
//         override
//         returns (uint256)
//     {
//         return balances[tokenOwner];
//     }

//     function transfer(address receiver, uint256 numTokens)
//         public
//         override
//         returns (bool)
//     {
//         require(numTokens <= balances[msg.sender]);
//         balances[msg.sender] = balances[msg.sender].sub(numTokens);
//         balances[receiver] = balances[receiver].add(numTokens);
//         emit Transfer(msg.sender, receiver, numTokens);
//         return true;
//     }

//     function approve(address delegate, uint256 numTokens)
//         public
//         override
//         returns (bool)
//     {
//         allowed[msg.sender][delegate] = numTokens;
//         emit Approval(msg.sender, delegate, numTokens);
//         return true;
//     }

//     function allowance(address owner, address delegate)
//         public
//         view
//         override
//         returns (uint256)
//     {
//         return allowed[owner][delegate];
//     }

//     function transferFrom(
//         address owner,
//         address buyer,
//         uint256 numTokens
//     ) public override returns (bool) {
//         require(numTokens <= balances[owner]);
//         require(numTokens <= allowed[owner][msg.sender]);
//         balances[owner] = balances[owner].sub(numTokens);
//         allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
//         balances[buyer] = balances[buyer].add(numTokens);
//         Transfer(owner, buyer, numTokens);
//         return true;
//     }

//     function _mint(address account, uint256 amount) internal virtual override {
//         require(account != address(0), "ERC20: mint to the zero address");
//         _beforeTokenTransfer(address(0), account, amount);
//         totalSupply_ = totalSupply_.add(amount);
//         balances[account] = balances[account].add(amount);
//         emit Transfer(address(0), account, amount);
//     }

//     function _burn(address account, uint256 amount) internal virtual override {
//         require(account != address(0), "ERC20: burn from the zero address");

//         _beforeTokenTransfer(account, address(0), amount);

//         balances[account] = balances[account].sub(
//             amount,
//             "ERC20: burn amount exceeds balance"
//         );
//         totalSupply_ = totalSupply_.sub(amount);
//         emit Transfer(account, address(0), amount);
//     }
// }
