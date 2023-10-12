// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

interface IEscrowFactory {
    /// @notice Create new ERC20Escrow contracts.
    /// @dev `msg.sender` will be the grantor in the Escrow contract.
    /// @dev Implements the CREATE2 opcode.
    /// @param grantee Address of the recipient of the payment.
    /// @param arbiter Address of the account that acts as a judge to resolve disputes.
    /// @param arbiterFee Percentage from the payment locked in the Escrow to pay the arbiter for resolving a dispute.
    /// @param payment Amount of tokens locked in the Escrow to pay to the grantee.
    /// @param salt Unique value provided by the caller.
    /// @param duration Duration of the escrow.
    /// @return Address of the created escrow.
    function createNativeEscrow(
        address grantee,
        address arbiter,
        uint256 arbiterFee,
        uint256 payment,
        bytes32 salt,
        uint256 duration
    ) external payable returns (address);

    /// @notice Create new ERC20Escrow contracts.
    /// @dev `msg.sender` will be the grantor in the Escrow contract.
    /// @dev Implements the CREATE2 opcode.
    /// @param grantee Address of the recipient of the payment.
    /// @param arbiter Address of the account that acts as a judge to resolve disputes.
    /// @param token Address of the token used as payment.
    /// @param arbiterFee Percentage from the payment locked in the Escrow to pay the arbiter for resolving a dispute.
    /// @param payment Amount of tokens locked in the Escrow to pay to the grantee.
    /// @param salt Unique value provided by the caller.
    /// @param duration Duration of the escrow.
    /// @return Address of the created escrow.
    function createERC20Escrow(
        address grantee,
        address arbiter,
        address token,
        uint256 arbiterFee,
        uint256 payment,
        bytes32 salt,
        uint256 duration
    ) external returns (address);
}
