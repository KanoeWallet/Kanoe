// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import "./OpenZeppelinHelpers/IERC20.sol";
import "./OpenZeppelinHelpers/Ownable.sol";
import "./LocalHelpers/IPlans.sol";
import "./LocalHelpers/ISubscriptions.sol";

contract SubscriptionLogic is Ownable {
	IPlans private plansContract;
	ISubscriptions private subscriptionsContract;
	address private paymentHolder;
	address private systemWallet;

	event PlansContractChanged(
		address indexed oldPlanContract,
		address indexed newPlanContract
	);
	event SubscriptionContractChanged(
		address indexed oldSubscriptionContract,
		address indexed newSubscriptionContract
	);
	event SystemWalletChanged(
		address indexed oldSystemWallet,
		address indexed newSystemWallet
	);
	event PaymentMade(
		address indexed account,
		uint256 planId,
		uint256 periodsCount,
		uint256 amount
	);
	event SubscriptionAutoExtended(
		address indexed account,
		uint256 planId,
		uint256 amount
	);

	/* ********************************* */

	constructor(
		address _plansContract,
		address _subscriptionsContract,
		address _paymentHolder,
		address _systemWallet
	) {
		plansContract = IPlans(_plansContract);
		subscriptionsContract = ISubscriptions(_subscriptionsContract);
		paymentHolder = _paymentHolder;
		systemWallet = _systemWallet;
	}

	/**
	 * @dev Returns the plan by the given ID.
	 * @param planId The ID of the plan.
	 */
	function getPlanById(
		uint256 planId
	) external view returns (PlanStruct memory) {
		return plansContract.getPlanById(planId);
	}

	/**
	 * @dev Returns the list of all plans.
	 */
	function getPlansList() external view returns (PlanStruct[] memory) {
		return plansContract.getPlansList();
	}

	/**
	 * @dev Returns the maximum payment ID.
	 */
	function getMaxPaymentId() external view returns (uint256) {
		return subscriptionsContract.getMaxPaymentId();
	}

	/**
	 * @dev Returns a sublist of payments from startIndex to endIndex (inclusive).
	 * @param startIndex The starting index of the sublist.
	 * @param endIndex The ending index of the sublist.
	 */
	function getPaymentsList(
		uint256 startIndex,
		uint256 endIndex
	) external view returns (PaymentStruct[] memory) {
		return subscriptionsContract.getPaymentsList(startIndex, endIndex);
	}

	/**
	 * @dev Returns updates since the given last known payment ID.
	 * @param lastKnownPaymentId The last known payment ID.
	 */
	function getUpdates(
		uint256 lastKnownPaymentId
	) external view returns (SubscriptionStruct[] memory) {
		uint256 lastPayment = subscriptionsContract.getMaxPaymentId();
		uint256 count = lastPayment > lastKnownPaymentId
			? lastPayment - lastKnownPaymentId
			: 0;
		SubscriptionStruct[] memory _subs = new SubscriptionStruct[](count);
		if (count > 0) {
			PaymentStruct[] memory _payments = this.getPaymentsList(
				lastKnownPaymentId,
				lastPayment - 1
			);
			for (uint256 i = 0; i < _payments.length; i++) {
				_subs[i] = this.getUserSubscription(_payments[i].payer);
			}
		}
		return _subs;
	}

	/**
	 * @dev Auto-extend subscription by system wallet
	 * @param account The address of the user.
	 */
	function payExtend(address account) external onlyAdmin {
		SubscriptionStruct memory subscription = subscriptionsContract
			.getUserSubscription(account);
		PlanStruct memory plan = plansContract.getPlanById(subscription.planId);
		IERC20(plan.paytokenAddress).transferFrom(
			account,
			paymentHolder,
			plan.paytokenPrice
		);
		subscriptionsContract.addPayment(
			account,
			1,
			subscription.planId,
			plan.paytokenPrice,
			plan.paytokenAddress
		);
		emit SubscriptionAutoExtended(
			account,
			subscription.planId,
			plan.paytokenPrice
		);
	}

	/**
	 * @dev Allows a user to pay for a subscription plan for a given number of periods.
	 * @param planId The ID of the plan.
	 * @param periodsCount The number of periods to pay for.
	 */
	function pay(uint256 planId, uint256 periodsCount) external {
		PlanStruct memory plan = plansContract.getPlanById(planId);
		uint256 amount = plan.paytokenPrice * periodsCount;
		IERC20(plan.paytokenAddress).transferFrom(
			msg.sender,
			paymentHolder,
			amount
		);
		subscriptionsContract.addPayment(
			msg.sender,
			periodsCount,
			planId,
			amount,
			plan.paytokenAddress
		);
		emit PaymentMade(msg.sender, planId, periodsCount, amount);
	}

	/**
	 * @dev Returns the subscription of the given user.
	 * @param account The address of the user.
	 */
	function getUserSubscription(
		address account
	) external view returns (SubscriptionStruct memory) {
		return subscriptionsContract.getUserSubscription(account);
	}

	/**
	 * @dev Changes the address of the plans contract. Only the owner can call this function.
	 * @param _plansContract The new address of the plans contract.
	 */

	function changePlansContract(address _plansContract) external onlyOwner {
		address oldPlansContract = address(plansContract);
		plansContract = IPlans(_plansContract);
		emit PlansContractChanged(oldPlansContract, _plansContract);
	}

	/**
	 * @dev Changes the address of the subscriptions contract. Only the owner can call this function.
	 * @param _subscriptionsContract The new address of the subscriptions contract.
	 */
	function changeSubscriptionContract(
		address _subscriptionsContract
	) external onlyOwner {
		address oldSubscriptionsContract = address(subscriptionsContract);
		subscriptionsContract = ISubscriptions(_subscriptionsContract);
		emit SubscriptionContractChanged(
			oldSubscriptionsContract,
			_subscriptionsContract
		);
	}

	/**
	 * @dev Changes the address of the system wallet. Only the owner can call this function.
	 * @param newSystemWallet The new address of the system wallet.
	 */
	function changeSystemWallet(address newSystemWallet) external onlyOwner {
		address oldSystemWallet = systemWallet;
		systemWallet = newSystemWallet;
		emit SystemWalletChanged(oldSystemWallet, newSystemWallet);
	}

	/**
	 * @dev Modifier to restrict access to only the system wallet.
	 */
	modifier onlyAdmin() {
		if (msg.sender != systemWallet) {
			revert("Only admin");
		}
		_;
	}
}
