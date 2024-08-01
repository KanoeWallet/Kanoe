//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./PlansStructs.sol";

interface IPlans {
	function getPlanById(
		uint256 planId
	) external view returns (PlanStruct memory);

	function getPlansList(
		uint256 startIndex,
		uint256 endIndex
	) external view returns (PlanStruct[] memory);

	function getPlansList() external view returns (PlanStruct[] memory);
}
