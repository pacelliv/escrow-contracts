// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IEscrowFactory} from "./interfaces/IEscrowFactory.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Errors} from "./libraries/Errors.sol";
import {Events} from "./libraries/Events.sol";
import {NativeEscrow} from "./NativeEscrow.sol";
import {ERC20Escrow} from "./ERC20Escrow.sol";

/// @title EscrowFactory
/// @author Eugenio P. Flores V.
/// @notice Contract with factory patterns to create escrow contracts.
/// @dev Implements the CREATE2 opcode to deploy new escrows.
contract EscrowFactory is IEscrowFactory {
    using SafeERC20 for IERC20;

    // ================================ CORE FACTORY FUNCTIONS ================================ //

    /// @inheritdoc	IEscrowFactory
    function createNativeEscrow(
        address grantee,
        address arbiter,
        uint256 arbiterFee,
        uint256 payment,
        bytes32 salt,
        uint256 duration
    ) external payable returns (address) {
        if (payment != msg.value) {
            revert Errors.EscrowFactory__ValuesMismatch();
        }

        address expectedAddress = computeNativeEscrowAddress(
            msg.sender,
            grantee,
            arbiter,
            arbiterFee,
            payment,
            salt,
            duration,
            type(NativeEscrow).creationCode
        );

        (bool status, ) = expectedAddress.call{value: payment}("");
        if (!status) {
            revert Errors.EscrowFactory__CallFailed();
        }

        NativeEscrow escrow = new NativeEscrow{salt: salt}(duration, msg.sender, grantee, arbiter, arbiterFee, payment);

        if (address(escrow) != expectedAddress) {
            revert Errors.EscrowFactory__AddressesMismatch();
        }

        emit Events.NewNativeEscrow(address(escrow), msg.sender, grantee, arbiter, arbiterFee, payment, duration);
        return address(escrow);
    }

    /// @inheritdoc	IEscrowFactory
    function createERC20Escrow(
        address grantee,
        address arbiter,
        address token,
        uint256 arbiterFee,
        uint256 payment,
        bytes32 salt,
        uint256 duration
    ) external returns (address) {
        address expectedAddress = computeERC20EscrowAddress(
            msg.sender,
            grantee,
            arbiter,
            token,
            arbiterFee,
            payment,
            salt,
            duration,
            type(ERC20Escrow).creationCode
        );

        IERC20(token).safeTransferFrom(msg.sender, expectedAddress, payment);

        ERC20Escrow escrow = new ERC20Escrow{salt: salt}(
            duration,
            msg.sender,
            grantee,
            arbiter,
            token,
            arbiterFee,
            IERC20(token).balanceOf(expectedAddress)
        );

        if (address(escrow) != expectedAddress) {
            revert Errors.EscrowFactory__AddressesMismatch();
        }

        emit Events.NewERC20Escrow(
            address(escrow),
            msg.sender,
            grantee,
            arbiter,
            token,
            arbiterFee,
            IERC20(token).balanceOf(expectedAddress),
            duration
        );
        return address(escrow);
    }

    // ================================ CREATE2 HELPERS ================================ //

    /// @dev See https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2
    function computeNativeEscrowAddress(
        address grantor,
        address grantee,
        address arbiter,
        uint256 arbiterFee,
        uint256 payment,
        bytes32 salt,
        uint256 duration,
        bytes memory bytecode
    ) public view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                salt,
                                keccak256(
                                    abi.encodePacked(
                                        bytecode,
                                        abi.encode(duration, grantor, grantee, arbiter, arbiterFee, payment)
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    /// @dev See https://docs.soliditylang.org/en/latest/control-structures.html#salted-contract-creations-create2
    function computeERC20EscrowAddress(
        address grantor,
        address grantee,
        address arbiter,
        address token,
        uint256 arbiterFee,
        uint256 payment,
        bytes32 salt,
        uint256 duration,
        bytes memory bytecode
    ) public view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                salt,
                                keccak256(
                                    abi.encodePacked(
                                        bytecode,
                                        abi.encode(duration, grantor, grantee, arbiter, token, arbiterFee, payment)
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }
}
