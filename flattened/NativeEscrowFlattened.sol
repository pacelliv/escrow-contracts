// Sources flattened with hardhat v2.17.2 https://hardhat.org

// SPDX-License-Identifier: MIT

// File src/libraries/EscrowTypes.sol

// SPDX-License-Idenfitier: MIT
pragma solidity ^0.8.21;

library EscrowTypes {
    enum State {
        CREATED,
        CONFIRMED,
        DISPUTED,
        RESOLVED
    }
}


// File src/interfaces/INativeEscrow.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.21;

interface INativeEscrow {
    /// @notice Confirm the receipt from the grantee.
    /// @dev Can only be called by the grantor.
    function confirmReceipt() external;

    /// @notice Withdraw the locked tokens in the Escrow contract.
    /// @dev Can only be called by the grantor after expiration of the Escrow.
    function withdraw() external;

    /// @notice Starts a dispute in case of dissatisfaction from one of the transactional parties.
    /// @dev Can only be called by the grantor or grantee.
    /// @dev Can only be called if the Escrow has not expired.
    function startDispute() external;

    /// @notice Resolves a dispute.
    /// @param grantorRefund Amount of token that the grantor will be refunded. This value goes from 0 to 100.
    /// @dev Can only be called by the arbiter.
    /// @dev Can only be called if the Escrow is in a `DISPUTED` state.
    function resolveDispute(uint256 grantorRefund) external;

    function getDuration() external view returns (uint256);

    function getGrantor() external view returns (address);

    function getGrantee() external view returns (address);

    function getArbiter() external view returns (address);

    function getArbiterFee() external view returns (uint256);

    function getPayment() external view returns (uint256);

    function getState() external view returns (EscrowTypes.State);

    function getMaxFee() external pure returns (uint256);
}


// File src/libraries/Errors.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.21;

library Errors {
    // ================================ FACTORY ERRORS ================================ //

    error EscrowFactory__AddressesMismatch();
    error EscrowFactory__ValuesMismatch();
    error EscrowFactory__CallFailed();

    // ================================ ESCROW ERRORS ================================ //

    error Escrow__RepeatedParticipant();
    error Escrow__MustDeployWithTokenBalance();
    error Escrow__EscrowNotExpired(uint256 currentTimestamp, uint256 duration);
    error Escrow__EscrowExpired();
    error Escrow__CallFailed();
    error Escrow__ZeroDuration();
    error Escrow__AddressZero();
    error Escrow__ZeroAmount();
    error Escrow__InsufficientBalance(uint256 grantorTokenBalance, uint256 payment);
    error Escrow__IncorrectRefunds();
    error Escrow__Unauthorized();
    error Escrow__InWrongState(EscrowTypes.State expectedState, EscrowTypes.State currentState);
    error Escrow__FeeExceedMax(uint256 arbiterFee, uint256 maxFee);
}


// File src/libraries/Events.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.21;

library Events {
    // ================================ FACTORY EVENTS ================================ //

    /// @notice Emitted after the creating of a new NativeEscrow.
    /// @param escrow Topic with the address of the new NativeEscrow.
    /// @param grantor Topic with the address of the grantor.
    /// @param grantee Topic with the address of grantee.
    /// @param arbiter Non-indexed parameter with the address of the arbiter.
    /// @param arbiterFee Non-indexed parameter with the amount of tokens awarded to the arbiter.
    /// @param payment Non-indexed parameter with the payment locked in the escrow contract.
    /// @param duration Non-indexed parameter with the duration of the escrow.
    event NewNativeEscrow(
        address indexed escrow,
        address indexed grantor,
        address indexed grantee,
        address arbiter,
        uint256 arbiterFee,
        uint256 payment,
        uint256 duration
    );

    /// @notice Emitted after the creating of a new ERC20Escrow.
    /// @param escrow Topic with the address of the new ERC20Escrow.
    /// @param grantor Topic with the address of the grantor.
    /// @param grantee Topic with the address of grantee.
    /// @param arbiter Non-indexed parameter with the address of the arbiter.
    /// @param token Non-indexed parameter with the address of the token used as payment.
    /// @param arbiterFee Non-indexed parameter with the amount of tokens awarded to the arbiter.
    /// @param payment Non-indexed parameter with the payment locked in the escrow contract.
    /// @param duration Non-indexed parameter with the duration of the escrow.
    event NewERC20Escrow(
        address indexed escrow,
        address indexed grantor,
        address indexed grantee,
        address arbiter,
        address token,
        uint256 arbiterFee,
        uint256 payment,
        uint256 duration
    );

    // ================================ ESCROW EVENTS ================================ //

    /// @notice Emitted after the receipt is confirmed by the grantor.
    /// @param grantor Topic with the address of the grantor.
    /// @param grantee Topic with the address of the grantee.
    /// @param payment Non-indexed parameter with the payment sent to the grantee.
    event ReceiptConfirmed(address indexed grantor, address indexed grantee, uint256 payment);

    /// @notice Emitted after a dispute was started.
    /// @param disputer Topic with the address of the instantiator of the dispute.
    event Dispute(address disputer);

    /// @notice Emitted after the grantor withdraws the payment from the Escrow contract.
    /// @param payment Non-indexed paramater with the amount of tokens withdrew.
    event Withdraw(uint256 payment);

    /// @notice Emitted after a dispute is resolved.
    /// @param arbiter Topic with the address of the arbiter.
    /// @param grantor Topic with the address of the grantor.
    /// @param grantee Topic with the address of the grantee.
    /// @param arbiterAward Non-indexed parameter with the amount of tokens awarded to the arbiter.
    /// @param grantorRefund Non-ndexed parameter with the amount of tokens refunded to the grantor.
    /// @param granteeAward Non-indexed parameter with the amount of tokens awarded to the grantee.
    event Resolved(
        address indexed arbiter,
        address indexed grantor,
        address indexed grantee,
        uint256 arbiterAward,
        uint256 grantorRefund,
        uint256 granteeAward
    );
}


// File src/NativeEscrow.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.21;




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
