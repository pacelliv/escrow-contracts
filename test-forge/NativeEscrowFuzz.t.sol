// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/ERC20Escrow.sol";
import "../src/EscrowFactory.sol";
import "../src/interfaces/IERC20Escrow.sol";
import "../src/mocks/WETH9Mock.sol";
import "../src/libraries/Errors.sol";
import "../src/libraries/EscrowTypes.sol";

contract NativeEscrowFuzz is Test {
    EscrowFactory public factory;
    uint256 public constant BALANCE = 1 ether;

    function setUp() public {
        factory = new EscrowFactory();
    }

    function testFuzz_CreateNativeEscrow(
        address grantor,
        address grantee,
        address arbiter,
        uint256 arbiterFee,
        uint96 payment,
        bytes32 salt,
        uint256 duration
    ) public {
        assumeNotZeroAddress(grantor);
        assumeNotZeroAddress(grantee);
        assumeNotZeroAddress(arbiter);
        vm.assume(arbiterFee != 0);
        vm.assume(arbiterFee <= 12);
        vm.assume(duration != 0);
        vm.assume(duration < type(uint256).max);
        vm.assume(grantor != grantee);
        vm.assume(grantor != arbiter);
        vm.assume(grantee != arbiter);
        vm.assume(payment > arbiterFee);
        vm.assume(salt > 0);

        address actualAddress = factory.createNativeEscrow{value: payment}(
            grantee,
            arbiter,
            arbiterFee,
            payment,
            salt,
            duration
        );
        address expectedAddress = factory.computeNativeEscrowAddress(
            address(this),
            grantee,
            arbiter,
            arbiterFee,
            payment,
            salt,
            duration,
            type(NativeEscrow).creationCode
        );
        assertEq(actualAddress, expectedAddress);
        assertEq(actualAddress.balance, payment);
    }

    function testFuzz_OnlyArbiterCanResolveDispute(
        address grantor,
        address grantee,
        address arbiter,
        uint256 arbiterFee,
        uint96 payment,
        bytes32 salt,
        uint256 duration,
        address caller
    ) public {
        assumeNotZeroAddress(grantor);
        assumeNotZeroAddress(grantee);
        assumeNotZeroAddress(arbiter);
        vm.assume(arbiterFee != 0);
        vm.assume(arbiterFee <= 12);
        vm.assume(duration != 0);
        vm.assume(duration < type(uint256).max);
        vm.assume(grantor != grantee);
        vm.assume(grantor != arbiter);
        vm.assume(grantee != arbiter);
        vm.assume(payment > arbiterFee);
        vm.assume(salt > 0);

        vm.deal(grantor, payment);
        vm.startPrank(grantor);

        address escrowAddress = factory.createNativeEscrow{value: payment}(
            grantee,
            arbiter,
            arbiterFee,
            payment,
            salt,
            duration
        );

        NativeEscrow escrow = NativeEscrow(escrowAddress);
        escrow.startDispute();

        vm.startPrank(caller);
        vm.expectRevert(Errors.Escrow__Unauthorized.selector);
        escrow.resolveDispute(50);

        vm.startPrank(arbiter);
        escrow.resolveDispute(50);

        uint256 arbiterPayment = (payment * arbiterFee) / 100;
        uint256 grantorAndGranteePayment = ((payment - arbiterPayment) * 50) / 100;

        assertEq(arbiter.balance, arbiterPayment);
        assertApproxEqAbs(grantor.balance, grantorAndGranteePayment, 10);
        assertApproxEqAbs(grantee.balance, grantorAndGranteePayment, 10);
    }

    function testFuzz__OnlyGrantorOrGranteeCanStartDispute(
        address grantor,
        address grantee,
        address arbiter,
        uint256 arbiterFee,
        uint96 payment,
        bytes32 salt,
        uint256 duration
    ) public {
        assumeNotZeroAddress(grantor);
        assumeNotZeroAddress(grantee);
        assumeNotZeroAddress(arbiter);
        vm.assume(arbiterFee != 0);
        vm.assume(arbiterFee <= 12);
        vm.assume(duration != 0);
        vm.assume(duration < type(uint256).max);
        vm.assume(grantor != grantee);
        vm.assume(grantor != arbiter);
        vm.assume(grantee != arbiter);
        vm.assume(payment > arbiterFee);
        vm.assume(salt > 0);

        vm.deal(grantor, payment);
        vm.startPrank(grantor);
        address escrowAddress = factory.createNativeEscrow{value: payment}(
            grantee,
            arbiter,
            arbiterFee,
            payment,
            salt,
            duration
        );

        NativeEscrow escrow = NativeEscrow(escrowAddress);

        vm.startPrank(arbiter);
        vm.expectRevert(Errors.Escrow__Unauthorized.selector);
        escrow.startDispute();

        assertEq(uint8(escrow.getState()), uint8(EscrowTypes.State.CREATED));

        vm.startPrank(grantor);
        escrow.startDispute();

        assertEq(uint8(escrow.getState()), uint8(EscrowTypes.State.DISPUTED));
    }

    function testFuzz__OnlyGrantorCanConfirmReceipt(
        address grantor,
        address grantee,
        address arbiter,
        uint256 arbiterFee,
        uint96 payment,
        bytes32 salt,
        uint256 duration
    ) public {
        assumeNotZeroAddress(grantor);
        assumeNotZeroAddress(grantee);
        assumeNotZeroAddress(arbiter);
        vm.assume(arbiterFee != 0);
        vm.assume(arbiterFee <= 12);
        vm.assume(duration != 0);
        vm.assume(duration < type(uint256).max);
        vm.assume(grantor != grantee);
        vm.assume(grantor != arbiter);
        vm.assume(grantee != arbiter);
        vm.assume(payment > arbiterFee);
        vm.assume(salt > 0);

        vm.deal(grantor, payment);
        vm.startPrank(grantor);
        address escrowAddress = factory.createNativeEscrow{value: payment}(
            grantee,
            arbiter,
            arbiterFee,
            payment,
            salt,
            duration
        );

        NativeEscrow escrow = NativeEscrow(escrowAddress);

        vm.warp(block.timestamp + duration);

        vm.startPrank(grantee);
        vm.expectRevert(Errors.Escrow__Unauthorized.selector);
        escrow.confirmReceipt();

        assertEq(uint8(escrow.getState()), uint8(EscrowTypes.State.CREATED));

        vm.startPrank(grantor);
        escrow.confirmReceipt();

        assertEq(uint8(escrow.getState()), uint8(EscrowTypes.State.CONFIRMED));
        assertEq(grantee.balance, payment);
    }

    function testFuzz__OnlyGrantorCanWithdraw(
        address grantor,
        address grantee,
        address arbiter,
        uint256 arbiterFee,
        uint96 payment,
        bytes32 salt,
        uint256 duration
    ) public {
        assumeNotZeroAddress(grantor);
        assumeNotZeroAddress(grantee);
        assumeNotZeroAddress(arbiter);
        vm.assume(arbiterFee != 0);
        vm.assume(arbiterFee <= 12);
        vm.assume(duration != 0);
        vm.assume(duration < type(uint256).max);
        vm.assume(grantor != grantee);
        vm.assume(grantor != arbiter);
        vm.assume(grantee != arbiter);
        vm.assume(payment > arbiterFee);
        vm.assume(salt > 0);

        vm.deal(grantor, payment);
        vm.startPrank(grantor);
        address escrowAddress = factory.createNativeEscrow{value: payment}(
            grantee,
            arbiter,
            arbiterFee,
            payment,
            salt,
            duration
        );

        NativeEscrow escrow = NativeEscrow(escrowAddress);

        vm.warp(block.timestamp + duration);

        vm.startPrank(grantee);
        vm.expectRevert(Errors.Escrow__Unauthorized.selector);
        escrow.withdraw();

        vm.startPrank(grantor);
        escrow.withdraw();

        assertEq(grantor.balance, payment);
        assertEq(uint8(escrow.getState()), uint8(EscrowTypes.State.RESOLVED));
        assertEq(address(escrow).balance, 0);
    }
}
