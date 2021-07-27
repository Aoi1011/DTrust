// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Burnable.sol";

import "./libraries/Address.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";

import "./Context.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract BurnValley {
  event TokensDestroyed(address burner, uint256 amount);

  function burnAllTokens(address _token) external {
    IERC20Burnable token = IERC20Burnable(_token);

    uint256 balance = token.balanceOf(address(this));
    token.burn(balance);

    emit TokensDestroyed(msg.sender, balance);
  }
}

abstract contract Swap is Ownable, Pausable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  address public immutable burnValley;
  uint256 public constant MIN_DTrust = 40 * 10**18;

  IERC20 public DTrust; //DTrust smart contract
  IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

  mapping(address => uint256) public usdcPerUser;

  event UsersRemoved(address[] users);
  event UsersWhitelisted(address[] users, uint256[] amounts);
  event TokensSwapped(address indexed user, uint256 DTrustAmount, uint256 usdcAmount);


  //  ------------------------
  //  CONSTRUCTOR
  //  ------------------------


   constructor() {
    // Deploy burn valley contract for locking tokens
    burnValley = address(new BurnValley());
	}


  //  ------------------------
  //  USER METHODS
  //  ------------------------

	function swap(uint256 DTrustAmount) external whenNotPaused {
		require(DTrustAmount >= MIN_DTrust, "swap: Less DTrust then required!");

    address user = _msgSender();
    require(usdcPerUser[user] > 0, "swap: User not allowed to swap!");

    // Transfer user tokens to burn valley contract
    DTrust.safeTransferFrom(user, burnValley, DTrustAmount);

    // Save amount which user will receive
    uint256 usdcAmount = usdcPerUser[user];
    usdcPerUser[user] = 0;

    USDC.safeTransfer(user, usdcAmount);

    // Transfer new tokens to sender
		emit TokensSwapped(user, DTrustAmount, usdcAmount);
	}

  //  ------------------------
  //  OWNER METHODS
  //  ------------------------

  function whitelistUsers(address[] calldata users, uint256[] calldata amounts) external onlyOwner {
    uint256 usersCount = users.length;
    require(usersCount == amounts.length, "whitelistUsers: Arrays are not equal!");
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
}
