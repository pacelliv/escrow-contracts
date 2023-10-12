// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {INativeEscrow} from "./interfaces/INativeEscrow.sol";
import {Errors} from "./libraries/Errors.sol";
import {EscrowTypes} from "./libraries/EscrowTypes.sol";
import {Events} from "./libraries/Events.sol";

/// @title NativeEscrow
/// @notice Escrow contract for transactions between grantor, grantee and arbiter.
/// @notice Payment is in the form of native tokens.
/// @dev Designed based on the audited Escrow contract from the CodeHawks Escrow Contract - Competition.
/// @dev Some findings from the final report were implemented in this design.
/// References:
/// - Audited contract: https://github.com/Cyfrin/2023-07-escrow/blob/main/src/Escrow.sol
/// - Final report: https://www.codehawks.com/report/cljyfxlc40003jq082s0wemya
contract NativeEscrow is INativeEscrow {
    /// @dev Maximum fee to pay to the arbiter.
    uint256 private constant _MAX_FEE = 12;

    /// @dev Used for calculations.
    uint256 private constant PRECISION = 100;

    /// @dev Duration of the escrow in seconds.
    uint256 private immutable _duration;

    /// @dev Account that transfer ownership of the payment.
    address private immutable _grantor;

    /// @dev Recipient of the payment.
    address private immutable _grantee;

    /// @dev Account that resolves disputes.
    address private immutable _arbiter;

    /// @dev Percentage deducted from the payment to pay to the arbiter.
    uint256 private immutable _arbiterFee;

    /// @dev Amount of tokens to used as payment.
    uint256 private immutable _payment;

    /// @dev State of the escrow.
    EscrowTypes.State private _currentState;

    /// @dev Reverts if the expected state is not equal to the current state.
    modifier onlyState(EscrowTypes.State expectedState) {
        if (expectedState != _currentState) {
            revert Errors.Escrow__InWrongState(expectedState, _currentState);
        }
        _;
    }

    // ================================ CONSTRUCTOR ================================ //

    /// @dev Sets the values for the state variables: `duration`, `grantor`, `grantee`, `arbiter`,
    /// `arbiterFee` and `payment`.
    /// @dev The payment must be transferred to this contract prior to its deployment with CREATE2.
    constructor(
        uint256 duration,
        address grantor,
        address grantee,
        address arbiter,
        uint256 arbiterFee,
        uint256 payment
    ) {
        if (duration == 0) {
            revert Errors.Escrow__ZeroDuration();
        }
        if (arbiterFee == 0) {
            revert Errors.Escrow__ZeroAmount();
        }
        if (grantee == address(0) || arbiter == address(0)) {
            revert Errors.Escrow__AddressZero();
        }
        if (arbiterFee > _MAX_FEE) {
            revert Errors.Escrow__FeeExceedMax(arbiterFee, _MAX_FEE);
        }
        if (grantor == arbiter || grantor == grantee || grantee == arbiter) {
            revert Errors.Escrow__RepeatedParticipant();
        }

        _duration = block.timestamp + duration;
        _grantor = grantor;
        _grantee = grantee;
        _arbiter = arbiter;
        _arbiterFee = arbiterFee;
        _payment = payment;
    }

    /// @inheritdoc INativeEscrow
    function withdraw() external onlyState(EscrowTypes.State.CREATED) {
        if (!_checkCaller(msg.sender, _grantor)) {
            revert Errors.Escrow__Unauthorized();
        }
        if (block.timestamp < _duration) {
            revert Errors.Escrow__EscrowNotExpired(block.timestamp, _duration);
        }
        _currentState = EscrowTypes.State.RESOLVED;
        emit Events.Withdraw(_payment);
        (bool status, ) = _grantor.call{value: address(this).balance}("");
        if (!status) {
            revert Errors.Escrow__CallFailed();
        }
    }

    // ================================ CORE ESCROW FUNCTIONS ================================ //

    /// @inheritdoc INativeEscrow
    function confirmReceipt() external onlyState(EscrowTypes.State.CREATED) {
        _expired();
        if (!_checkCaller(msg.sender, _grantor)) {
            revert Errors.Escrow__Unauthorized();
        }
        _currentState = EscrowTypes.State.CONFIRMED;
        emit Events.ReceiptConfirmed(_grantor, _grantee, _payment);
        (bool status, ) = _grantee.call{value: address(this).balance}("");
        if (!status) {
            revert Errors.Escrow__CallFailed();
        }
    }

    /// @inheritdoc INativeEscrow
    function startDispute() external onlyState(EscrowTypes.State.CREATED) {
        _expired();
        if (!_checkCaller(msg.sender, _grantor) && !_checkCaller(msg.sender, _grantee)) {
            revert Errors.Escrow__Unauthorized();
        }
        _currentState = EscrowTypes.State.DISPUTED;
        emit Events.Dispute(msg.sender);
    }

    /// @inheritdoc INativeEscrow
    function resolveDispute(uint256 grantorRefund) external onlyState(EscrowTypes.State.DISPUTED) {
        if (!_checkCaller(msg.sender, _arbiter)) {
            revert Errors.Escrow__Unauthorized();
        }

        _currentState = EscrowTypes.State.RESOLVED;

        uint256 arbiterPayment = (_payment * _arbiterFee) / PRECISION;

        (bool statusArbiterPayment, ) = _arbiter.call{value: arbiterPayment}("");
        if (!statusArbiterPayment) {
            revert Errors.Escrow__CallFailed();
        }

        uint256 remainderBalance = _payment - arbiterPayment;

        uint256 grantorAmount;
        if (grantorRefund > 0) {
            grantorAmount = (remainderBalance * grantorRefund) / PRECISION;
            (bool statusGrantorRefund, ) = _grantor.call{value: grantorAmount}("");
            if (!statusGrantorRefund) {
                revert Errors.Escrow__CallFailed();
            }
        }

        if (remainderBalance > 0) {
            (bool statusGranteePayment, ) = _grantee.call{value: remainderBalance - grantorAmount}("");
            if (!statusGranteePayment) {
                revert Errors.Escrow__CallFailed();
            }
        }

        emit Events.Resolved(
            _arbiter,
            _grantor,
            _grantee,
            arbiterPayment,
            grantorAmount,
            remainderBalance - grantorAmount
        );
    }

    // ================================ GETTER FUNCTIONS ================================ //

    function getDuration() external view returns (uint256) {
        return _duration;
    }

    function getGrantor() external view returns (address) {
        return _grantor;
    }

    function getGrantee() external view returns (address) {
        return _grantee;
    }

    function getArbiter() external view returns (address) {
        return _arbiter;
    }

    function getArbiterFee() external view returns (uint256) {
        return _arbiterFee;
    }

    function getPayment() external view returns (uint256) {
        return _payment;
    }

    function getState() external view returns (EscrowTypes.State) {
        return _currentState;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getMaxFee() external pure returns (uint256) {
        return _MAX_FEE;
    }

    // ================================ INTERNAL FUNCTIONS ================================ //

    /// @dev Reverts if the current block timestamp is greater than the `_duration` of the Escrow.
    function _expired() internal view {
        if (block.timestamp > _duration) {
            revert Errors.Escrow__EscrowExpired();
        }
    }

    /// @dev Check if the `caller` is equal to `expectedCaller`.
    /// @return Return `true` is `caller` equal to `expectedCaller`, return `false` otherwise.
    function _checkCaller(address caller, address expectedCaller) internal pure returns (bool) {
        return caller == expectedCaller;
    }
}
