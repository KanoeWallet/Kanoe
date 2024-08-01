//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./SubscriptionsStructs.sol";

interface ISubscriptions {
	function addPayment(
		address account,
		uint256 payedPeriods,
		uint256 planId,
		uint256 paytokenPrice,
		address paytokenAddress
	) external;

	function getSubscriptionsList(
		uint256 startIndex,
		uint256 endIndex
	) external view returns (SubscriptionStruct[] memory);

	function getPaymentsList(
		uint256 startIndex,
		uint256 endIndex
	) external view returns (PaymentStruct[] memory);

	function getMaxSubscriptionId() external view returns (uint256);

	function getMaxPaymentId() external view returns (uint256);

	function getSubscriptionById(
		uint256 id
	) external view returns (SubscriptionStruct memory);

	function getUserSubscription(
		address account
	) external view returns (SubscriptionStruct memory);
}
