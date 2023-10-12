// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/ERC20Escrow.sol";
import "../src/EscrowFactory.sol";
import "../src/interfaces/IERC20Escrow.sol";
import "../src/mocks/WETH9Mock.sol";
import "../src/libraries/Errors.sol";

contract EscrowFactoryFuzzTest is Test {
    WETH9 public weth;
    EscrowFactory public factory;
    uint256 public constant BALANCE = 1 ether;

    function setUp() public {
        factory = new EscrowFactory();
        weth = new WETH9();
    }

    function testFuzz_CreateEscrow(
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

        weth.deposit{value: payment}();
        weth.approve(address(factory), payment);

        assert(weth.balanceOf(address(this)) == payment);

        address actualAddress = factory.createERC20Escrow(
            grantee,
            arbiter,
            address(weth),
            arbiterFee,
            payment,
            salt,
            duration
        );
        address expectedAddress = factory.computeERC20EscrowAddress(
            address(this),
            grantee,
            arbiter,
            address(weth),
            arbiterFee,
            payment,
            salt,
            duration,
            type(ERC20Escrow).creationCode
        );
        assertEq(actualAddress, expectedAddress);
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
        weth.deposit{value: payment}();
        weth.approve(address(factory), payment);
        address escrowAddress = factory.createERC20Escrow(
            grantee,
            arbiter,
            address(weth),
            arbiterFee,
            payment,
            salt,
            duration
        );

        ERC20Escrow escrow = ERC20Escrow(escrowAddress);
        escrow.startDispute();

        vm.startPrank(caller);
        vm.expectRevert(Errors.Escrow__Unauthorized.selector);
        escrow.resolveDispute(50);

        vm.startPrank(arbiter);
        escrow.resolveDispute(50);
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
        weth.deposit{value: payment}();
        weth.approve(address(factory), payment);
        address escrowAddress = factory.createERC20Escrow(
            grantee,
            arbiter,
            address(weth),
            arbiterFee,
            payment,
            salt,
            duration
        );

        ERC20Escrow escrow = ERC20Escrow(escrowAddress);

        vm.startPrank(arbiter);
        vm.expectRevert(Errors.Escrow__Unauthorized.selector);
        escrow.startDispute();

        vm.startPrank(grantor);
        escrow.startDispute();

        assertEq(weth.balanceOf(escrowAddress), payment);
        assertEq(weth.balanceOf(grantor), 0);
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
        weth.deposit{value: payment}();
        weth.approve(address(factory), payment);
        address escrowAddress = factory.createERC20Escrow(
            grantee,
            arbiter,
            address(weth),
            arbiterFee,
            payment,
            salt,
            duration
        );

        ERC20Escrow escrow = ERC20Escrow(escrowAddress);

        vm.warp(block.timestamp + duration);

        vm.startPrank(grantee);
        vm.expectRevert(Errors.Escrow__Unauthorized.selector);
        escrow.confirmReceipt();

        vm.startPrank(grantor);
        escrow.confirmReceipt();

        assertEq(weth.balanceOf(grantee), payment);
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
        weth.deposit{value: payment}();
        weth.approve(address(factory), payment);
        address escrowAddress = factory.createERC20Escrow(
            grantee,
            arbiter,
            address(weth),
            arbiterFee,
            payment,
            salt,
            duration
        );

        ERC20Escrow escrow = ERC20Escrow(escrowAddress);

        vm.warp(block.timestamp + duration);

        vm.startPrank(grantee);
        vm.expectRevert(Errors.Escrow__Unauthorized.selector);
        escrow.withdraw();

        vm.startPrank(grantor);
        escrow.withdraw();

        assertEq(weth.balanceOf(grantor), payment);
    }
}
