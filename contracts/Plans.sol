// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "./OpenZeppelinHelpers/Ownable.sol";
import "./OpenZeppelinHelpers/Counters.sol";
import "./LocalHelpers/PlansStructs.sol";

contract Plans is Ownable {
	using Counters for Counters.Counter;

	Counters.Counter private planIds;
	PlanStruct[] private plans;


	constructor() {}

	/**
	 * @dev Returns plan ID of last added plan or 0 if none was added.
	 */
	function getPlanId() external view returns (uint256) {
		return planIds.current();
	}

	/**
	 * @dev Returns the plan by the given ID.
	 * Reverts if the plan does not exist.
	 * @param id The ID of the plan.
	 */
	function getPlanById(uint256 id) external view returns (PlanStruct memory) {
		uint256 maxId = planIds.current();
		if (maxId == 0) {
			revert("No any subscriptions");
		}
		if (id == 0 || id > maxId) {
			revert("Invalid plan ID");
		}
		return plans[id - 1];
	}

	/**
	 * @dev Returns the list of all plans.
	 */
	function getPlansList() external view returns (PlanStruct[] memory) {
		return this.getPlansList(0, plans.length - 1);
	}

	/**
	 * @dev Returns a sublist of plans from startIndex to endIndex (inclusive).
	 * Reverts if indices are out of bounds.
	 * @param startIndex The starting index of the sublist.
	 * @param endIndex The ending index of the sublist.
	 */
	function getPlansList(
		uint256 startIndex,
		uint256 endIndex
	) external view returns (PlanStruct[] memory) {
		if (endIndex < startIndex) {
			revert("Invalid index range");
		}
		if (endIndex >= plans.length) {
			revert("EndIndex out of bounds");
		}
		PlanStruct[] memory list = new PlanStruct[](endIndex - startIndex + 1);
		for (uint256 i = startIndex; i <= endIndex; i++) {
			list[i - startIndex] = plans[i];
		}
		return list;
	}

	/* ********************************* */

	/**
	 * @dev Adds a new plan. Only the owner can call this function.
	 * @param title The title of the plan.
	 * @param paytokenAddress The address of the payment token.
	 * @param paytokenPrice The price of the plan.
	 * @param limits The user's limits of the plan.
	 */
	function addPlan(
		string memory title,
		address paytokenAddress,
		uint256 paytokenPrice,
		PlanLimits memory limits
	) external onlyOwner {
		planIds.increment();
		uint256 newId = planIds.current();
		plans.push(
			PlanStruct(
				newId,
				paytokenPrice,
				paytokenAddress,
				true,
				limits,
				title
			)
		);
	}

	/**
	 * @dev Toggles the active status of a plan. Only the owner can call this function.
	 * @param planId The ID of the plan to toggle.
	 * @param isActive The new active status of the plan.
	 */
	function togglePlan(uint256 planId, bool isActive) external onlyOwner {
		uint256 length = plans.length;
		for (uint256 i = 0; i < length; i++) {
			if (plans[i].id == planId) {
				plans[i].isActive = isActive;
				return;
			}
		}
		revert("Plan ID not found");
	}
}
