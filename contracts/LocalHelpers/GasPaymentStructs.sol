// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

struct GasPayment {
	uint256 id;
	uint256 requestId;
	uint256 coinAmount;
	uint256 timestamp;
	address payer;
}

enum ApproveState {
	NotApproved,
	PartiallyApproved,
	Approved
}

struct OneUserTokenInfo {
	address token;
	uint256 balance;
	ApproveState state;
}

struct OneShortNFTCollectionAllowance {
	address token;
	bool isApproved;
}

struct OneNFTallowance {
	uint256 id;
	bool isApproved;
}

struct OneUserCollectionInfo {
	address token;
	bool isApprovedForAll;
	ApproveState state;
	OneNFTallowance[] individualNFT;
}

struct OneSendCollection {
	address token;
	uint256[] ids;
	address[] successors;
}
