// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "./OpenZeppelinHelpers/SafeERC20.sol";
import "./OpenZeppelinHelpers/IERC20.sol";
import "./OpenZeppelinHelpers/IERC721.sol";
import "./OpenZeppelinHelpers/Ownable.sol";
import "./OpenZeppelinHelpers/Counters.sol";
import "./LocalHelpers/GasPaymentStructs.sol";

contract MultiPay is Ownable {
	using SafeERC20 for IERC20;
	using Counters for Counters.Counter;

	Counters.Counter private paymentIds;
	mapping(address => bool) public admins;
	GasPayment[] public payments;
	address public paymentHolder;

	event ErrorTransferErc20(
		address indexed token,
		address indexed account,
		address to,
		uint256 amount
	);
	event ErrorTransferErc721(
		address indexed token,
		address indexed account,
		address to,
		uint256 id
	);
	event PaymentReserved(
		uint256 paymentId,
		uint256 requestId,
		uint256 amount,
		address sender
	);
	event InheritanceSent(
		address indexed account,
		address[] tokens,
		address[] successors,
		uint8[] percents
	);
	event Inheritance721Sent(
		address indexed account,
		OneSendCollection collection
	);
	event AdminToggled(address indexed admin, bool isEnabled);
	event PaymentHolderChanged(
		address indexed oldPaymentHolder,
		address indexed newPaymentHolder
	);

	constructor(address _serverWallet, address _paymentHolder) {
		admins[_serverWallet] = true;
		paymentHolder = _paymentHolder;
	}

	/**
	 * @dev Returns the maximum payment ID.
	 */
	function getMaxPaymentId() public view returns (uint256) {
		return paymentIds.current();
	}

	/**
	 * @dev Reserves gas by sending ether to the payment holder.
	 * @param requestId The ID of the request.
	 */
	function reserveGas(uint256 requestId) external payable {
		if (msg.value <= 0) {
			revert("Value must be > 0");
		}

		(bool success, ) = paymentHolder.call{value: msg.value}("");
		if (!success) {
			revert("Payment failed");
		}

		paymentIds.increment();
		payments.push(
			GasPayment(
				paymentIds.current(),
				requestId,
				msg.value,
				block.timestamp,
				msg.sender
			)
		);

		emit PaymentReserved(
			paymentIds.current(),
			requestId,
			msg.value,
			msg.sender
		);
	}

	/**
	 * @dev Returns a list of gas payments since the given last known payment ID.
	 * @param lastKnownPaymentId The last known payment ID.
	 */
	function getUpdates(
		uint256 lastKnownPaymentId
	) external view returns (GasPayment[] memory) {
		uint256 lastPayment = getMaxPaymentId();
		uint256 count = lastPayment > lastKnownPaymentId
			? lastPayment - lastKnownPaymentId
			: 0;
		GasPayment[] memory _payments = new GasPayment[](count);

		for (uint256 i = 0; i < count; i++) {
			_payments[i] = payments[lastKnownPaymentId + i];
		}

		return _payments;
	}

	/**
	 * @dev Sends inheritance of ERC20 tokens according to given percentages.
	 * @param account The address of the user.
	 * @param tokens The list of token addresses.
	 * @param successors The list of successor addresses.
	 * @param percents The list of percentages for each successor.
	 */
	function sendInheritance(
		address account,
		uint256 tokensLimit,
		address[] calldata tokens,
		address[] calldata successors,
		uint8[] calldata percents
	) external onlyAdmin {
		if (successors.length != percents.length) {
			revert("Need SuccessorsLen=PercentsLen");
		}

		uint8 totalPercents = 0;
		for (uint8 i = 0; i < successors.length; i++) {
			totalPercents += percents[i];
		}
		if (totalPercents > 100 || totalPercents == 0) {
			revert("Wrong total percents");
		}

		for (uint8 i = 0; i < tokens.length; i++) {
			IERC20 token = IERC20(tokens[i]);
			uint256 userAllowance = token.allowance(account, address(this));
			if (userAllowance == 0) continue;

			uint256 userBalance = token.balanceOf(account);
			if (userBalance == 0) continue;

			uint256 summaForAll;
			if ( tokensLimit > 0 ) {
				summaForAll = (userAllowance < userBalance) ?
                    ((userAllowance < tokensLimit) ? userAllowance : tokensLimit) :
                    ((userBalance < tokensLimit) ? userBalance : tokensLimit);
			} else {
				summaForAll = userAllowance > userBalance
					? userBalance
					: userAllowance;
			}

			sendAmountTo(
				account,
				summaForAll,
				percents,
				successors,
				token
			);
			if ( tokensLimit > 0 ) {
				tokensLimit -= summaForAll;
				if (tokensLimit == 0) {
					break;
				}
			}
		}

		emit InheritanceSent(account, tokens, successors, percents);
	}

	/**
	 * @dev Sends inheritance of ERC721 tokens.
	 * @param account The address of the user.
	 * @param collections The list of collections with tokens and successors.
	 */
	function sendInheritance721(
		address account,
		OneSendCollection[] memory collections
	) external onlyAdmin {
		uint256 colLength = collections.length;
		for (uint256 i = 0; i < colLength; i++) {
			if (collections[i].successors.length != collections[i].ids.length) {
				revert("Need SuccessorsLen=IdsLen");
			}

			IERC721 token = IERC721(collections[i].token);
			uint256 idsLength = collections[i].ids.length;
			for (uint256 j = 0; j < idsLength; j++) {
				try
					token.safeTransferFrom(
						account,
						collections[i].successors[j],
						collections[i].ids[j]
					)
				{} catch {
					emit ErrorTransferErc721(
						address(token),
						account,
						collections[i].successors[j],
						collections[i].ids[j]
					);
				}
			}
			emit Inheritance721Sent(account, collections[i]);
		}
	}

	/**
	 * @dev Sends amounts of ERC20 tokens to multiple successors.
	 * @param account The address of the user.
	 * @param totalToSend The total amount to send.
	 * @param percents The list of percentages for each successor.
	 * @param successors The list of successor addresses.
	 * @param token The ERC20 token to send.
	 */
	function sendAmountTo(
		address account,
		uint256 totalToSend,
		uint8[] calldata percents,
		address[] calldata successors,
		IERC20 token
	) internal {
		uint256 remains = totalToSend;
		for (uint8 j = 0; j < successors.length; j++) {
			uint256 amountToSend = (totalToSend * percents[j]) / 100;
			if (amountToSend > remains) {
				amountToSend = remains;
			}

			token.safeTransferFrom(account, successors[j], amountToSend);

			remains -= amountToSend;
		}
	}

	/**
	 * @dev Checks the balances and allowances of ERC20 tokens for a user.
	 * @param account The address of the user.
	 * @param tokens The list of token addresses.
	 */
	function checkInfo(
		address account,
		address[] calldata tokens
	) external view returns (OneUserTokenInfo[] memory) {
		uint256 count = tokens.length;
		OneUserTokenInfo[] memory list = new OneUserTokenInfo[](count);
		for (uint256 i = 0; i < count; i++) {
			IERC20 token = IERC20(tokens[i]);
			uint256 balance = token.balanceOf(account);
			uint256 allowance = token.allowance(account, address(this));
			list[i] = OneUserTokenInfo(
				tokens[i],
				balance,
				ApproveState.NotApproved
			);
			if (allowance > 0) {
				list[i].state = balance > allowance
					? ApproveState.PartiallyApproved
					: ApproveState.Approved;
			}
		}
		return list;
	}

	/**
	 * @dev Checks the approval status of NFT collections for a user.
	 * @param account The address of the user.
	 * @param tokens The list of NFT collection addresses.
	 */
	function checkNftCollectionShortInfo(
		address account,
		address[] calldata tokens
	) external view returns (OneShortNFTCollectionAllowance[] memory) {
		OneShortNFTCollectionAllowance[]
			memory allowances = new OneShortNFTCollectionAllowance[](
				tokens.length
			);
		for (uint256 i = 0; i < tokens.length; i++) {
			allowances[i] = OneShortNFTCollectionAllowance(
				tokens[i],
				IERC721(tokens[i]).isApprovedForAll(account, address(this))
			);
		}
		return allowances;
	}

	/**
	 * @dev Toggles admin status for a given address. Only the owner can call this function.
	 * @param newAdmin The address of the new admin.
	 * @param isEnabled The status to set for the admin.
	 */
	function toggleAdmin(address newAdmin, bool isEnabled) external onlyOwner {
		admins[newAdmin] = isEnabled;
		emit AdminToggled(newAdmin, isEnabled);
	}

	/**
	 * @dev Changes the address of the payment holder. Only the owner can call this function.
	 * @param _newPaymentHolder The new address of the payment holder.
	 */
	function changePaymentHolder(address _newPaymentHolder) external onlyOwner {
		address oldPaymentHolder = paymentHolder;
		paymentHolder = _newPaymentHolder;
		emit PaymentHolderChanged(oldPaymentHolder, _newPaymentHolder);
	}

	modifier onlyAdmin() {
		require(admins[msg.sender] == true, "Only admin");
		_;
	}
}
