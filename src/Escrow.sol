/// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./libraries/TransferHelper.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 *
 * In this case the owner is the ProxyContract, not the implementation.
 */
contract Escrow is Ownable {
    address private _currency;

    mapping(address => uint256) private _deposits;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    constructor(address currency) {
        _currency = currency;
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param amount The funds.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(uint256 amount, address payee) public virtual onlyOwner {
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        TransferHelper.safeTransferFrom(_currency, super.owner(), payee, payment);

        emit Withdrawn(payee, payment);
    }

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }
}
