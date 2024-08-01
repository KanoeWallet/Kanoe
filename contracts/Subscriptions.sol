// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "./OpenZeppelinHelpers/Counters.sol";
import "./LocalHelpers/SubscriptionsStructs.sol";

contract Subscriptions {
	using Counters for Counters.Counter;

	Counters.Counter private subscriptionIds;
	SubscriptionStruct[] private subscriptions;

	Counters.Counter private paymentIds;
	PaymentStruct[] private payments;

	mapping(address => uint256) public userSubscription;
	mapping(address => bool) public allowedManager;

	/* ********************************* */

	constructor() {
		allowedManager[msg.sender] = true;
	}

	/**
	 * @dev Returns the maximum subscription ID.
	 */
	function getMaxSubscriptionId() external view returns (uint256) {
		return subscriptionIds.current();
	}

	/**
	 * @dev Returns the maximum payment ID.
	 */
	function getMaxPaymentId() external view returns (uint256) {
		return paymentIds.current();
	}

	/**
	 * @dev Returns the subscription by the given ID.
	 * Reverts if the subscription does not exist.
	 * @param id The ID of the subscription.
	 */
	function getSubscriptionById(
		uint256 id
	) public view returns (SubscriptionStruct memory) {
		uint256 maxId = subscriptionIds.current();
		if (maxId == 0) {
			revert("No any subscriptions");
		}
		if (id == 0 || id > maxId) {
			revert("Invalid subscription ID");
		}
		return subscriptions[id - 1];
	}

	/**
	 * @dev Returns the subscription of the given user.
	 * @param account The address of the user.
	 */
	function getUserSubscription(
		address account
	) external view returns (SubscriptionStruct memory) {
		uint256 subsId = userSubscription[account];
		return getSubscriptionById(subsId);
	}

	/**
	 * @dev Returns a sublist of subscriptions from startIndex to endIndex (inclusive).
	 * Reverts if indices are out of bounds.
	 * @param startIndex The starting index of the sublist.
	 * @param endIndex The ending index of the sublist.
	 */
	function getSubscriptionsList(
		uint256 startIndex,
		uint256 endIndex
	) external view returns (SubscriptionStruct[] memory) {
		SubscriptionStruct[] memory list = new SubscriptionStruct[](
			endIndex - startIndex + 1
		);
		for (uint256 i = startIndex; i <= endIndex; i++) {
			list[i - startIndex] = subscriptions[i];
		}
		return list;
	}

	/**
	 * @dev Returns a sublist of subscriptions from startIndex to endIndex (inclusive).
	 * Reverts if indices are out of bounds.
	 * @param startIndex The starting index of the sublist.
	 * @param endIndex The ending index of the sublist.
	 */
	function getPaymentsList(
		uint256 startIndex,
		uint256 endIndex
	) external view returns (PaymentStruct[] memory) {
		if (endIndex < startIndex) {
			revert("Invalid index range");
		}
		if (endIndex >= payments.length) {
			revert("EndIndex out of bounds");
		}
		PaymentStruct[] memory list = new PaymentStruct[](
			endIndex - startIndex + 1
		);
		for (uint256 i = startIndex; i <= endIndex; i++) {
			list[i - startIndex] = payments[i];
		}
		return list;
	}

	/**
	 * @dev Adds a new payment. Only allowed managers can call this function.
	 * @param account The address of the user making the payment.
	 * @param payedPeriods The number of periods paid for.
	 * @param planId The ID of the plan being paid for.
	 * @param paytokenPrice The price of the payment token.
	 * @param paytokenAddress The address of the payment token.
	 */
	function addPayment(
		address account,
		uint256 payedPeriods,
		uint256 planId,
		uint256 paytokenPrice,
		address paytokenAddress
	) external onlyAllowed {
		// add payment to log
		paymentIds.increment();
		uint256 newPayId = paymentIds.current();
		payments.push(
			PaymentStruct(
				newPayId,
				planId,
				payedPeriods,
				account,
				paytokenAddress,
				paytokenPrice * payedPeriods,
				block.timestamp
			)
		);

		// check subscription existance
		uint256 subId = userSubscription[account];
		if (subId > 0) {
			// existing subscription
			uint256 oldSubPlan = subscriptions[subId - 1].planId;
			if (oldSubPlan == planId) {
				// same plan ID
				extendSubscriptionById(subId, payedPeriods);
				return;
			}
		}

		// new subscription or different plan ID
		addSubscription(account, planId, payedPeriods);
		return;
	}

	/* ********************************* */

	/**
	 * @dev Extends the subscription by the given ID.
	 * @param subId The ID of the subscription to extend.
	 * @param payedPeriods The number of periods to extend by.
	 */
	function extendSubscriptionById(
		uint256 subId,
		uint256 payedPeriods
	) private {
		subscriptions[subId - 1].endTime += payedPeriods * 90 days;
	}

	/**
	 * @dev Adds a new subscription.
	 * @param account The address of the user.
	 * @param planId The ID of the plan.
	 * @param payedPeriods The number of periods paid for.
	 */
	function addSubscription(
		address account,
		uint256 planId,
		uint256 payedPeriods
	) private {
		subscriptionIds.increment();
		uint256 newId = subscriptionIds.current();
		subscriptions.push(
			SubscriptionStruct(
				newId,
				account,
				new address[](0),
				planId,
				block.timestamp,
				payedPeriods * 90 days + block.timestamp
			)
		);
		userSubscription[account] = newId;
	}

	/**
	 * @dev Changes the allowed status of a manager. Only allowed managers can call this function.
	 * @param _manager The address of the manager.
	 * @param isAllowed The new allowed status of the manager.
	 */
	function changeAllowed(
		address _manager,
		bool isAllowed
	) external onlyAllowed {
		allowedManager[_manager] = isAllowed;
	}

	/**
	 * @dev Modifier to restrict access to allowed managers.
	 */
	modifier onlyAllowed() {
		require(allowedManager[msg.sender] == true, "Not allowed");
		_;
	}
}
