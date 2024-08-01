// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

struct SubscriptionStruct {
	uint256 id;
	address account;
	address[] extraAccounts;
	uint256 planId;
	uint256 startTime;
	uint256 endTime;
}

struct PaymentStruct {
	uint256 id;
	uint256 planId;
	uint256 payedPeriods;
	address payer;
	address paytokenAddress;
	uint256 paytokenAmount;
	uint256 timestamp;
}