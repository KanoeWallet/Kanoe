// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

struct OneTrigger {
	address addr;
	bool isEnabled;
}

struct PlanLimits {
	uint256 successorsMaxCount;
	uint256 inheritancesMaxCount;
	uint256 tokensMaxCount;
	uint256 stableMaxSum;
	uint256 maxWalletsCount;
}

struct PlanStruct {
	uint256 id;
	uint256 paytokenPrice;
	address paytokenAddress;
	bool isActive;
	PlanLimits limits;
	string title;
}
