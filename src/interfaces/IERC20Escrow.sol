// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EscrowTypes} from "../libraries/EscrowTypes.sol";

interface IERC20Escrow {
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

    function getToken() external view returns (IERC20);

    function getArbiterFee() external view returns (uint256);

    function getPayment() external view returns (uint256);

    function getState() external view returns (EscrowTypes.State);

    function getMaxFee() external pure returns (uint256);
}
