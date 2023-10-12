// SPDX-License-Identifier: MIT
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
