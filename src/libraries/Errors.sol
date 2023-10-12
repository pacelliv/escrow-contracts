// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EscrowTypes} from "./EscrowTypes.sol";

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
