// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "./OpenZeppelinHelpers/ERC20.sol";

contract Token is ERC20 {

	constructor(string memory name_, string memory symbol_, uint256 amount_) ERC20(name_, symbol_) {
		_mint(msg.sender, amount_ * 10**decimals());
	}

}
