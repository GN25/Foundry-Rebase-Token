//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {RebaseToken} from "src/RebaseToken.sol";
import {Vault} from "src/Vault.sol";
import {IRebaseToken} from "src/interfaces/IRebaseToken.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RebaseTokenFuzzTest is Test {
    RebaseToken rebaseToken;
    Vault vault;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() public {
        vm.startPrank(owner);
        rebaseToken = new RebaseToken();
        vault = new Vault(IRebaseToken(address(rebaseToken)));
        rebaseToken.grantMintAndBurnRole(address(vault));
        vm.stopPrank();
    }

    function addRewardsToVault(uint256 amount) public {
        (bool success,) = payable(address(vault)).call{value: amount}("");
    }

    function testDepositLinear(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);

        vm.startPrank(user);
        vm.deal(user, amount);

        vault.deposit{value: amount}();

        uint256 startBalance = rebaseToken.balanceOf(user);
        assertEq(startBalance, amount);

        vm.warp(block.timestamp + 1 hours);
        uint256 midBalance = rebaseToken.balanceOf(user);
        assertGt(midBalance, startBalance);

        vm.warp(block.timestamp + 1 hours);
        uint256 endBalance = rebaseToken.balanceOf(user);

        assertApproxEqAbs(endBalance - midBalance, midBalance - startBalance, 1);
        vm.stopPrank();
    }

    function testREdeemStraightAway(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);

        vm.startPrank(user);
        vm.deal(user, amount);

        vault.deposit{value: amount}();

        assertEq(rebaseToken.balanceOf(user), amount);

        vault.redeem(type(uint256).max);

        assertEq(rebaseToken.balanceOf(user), 0);
        assertEq(address(user).balance, amount);

        vm.stopPrank();
    }

    function testRedeemAfterTimePassed(uint256 depositAmount, uint256 time) public {
        time = bound(time, 1000, type(uint96).max);
        depositAmount = bound(depositAmount, 1e5, type(uint96).max);

        vm.prank(user);
        vm.deal(user, depositAmount);
        vault.deposit{value: depositAmount}();

        vm.warp(block.timestamp + time);
        uint256 balanceAfterSomeTime = rebaseToken.balanceOf(user);

        vm.deal(owner, balanceAfterSomeTime - depositAmount);
        vm.prank(owner);
        addRewardsToVault(balanceAfterSomeTime - depositAmount);

        vm.prank(user);
        vault.redeem(type(uint256).max);

        uint256 ethBalance = address(user).balance;

        assertEq(ethBalance, balanceAfterSomeTime);
        assertGt(ethBalance, depositAmount);
    }

    function testTransfer(uint256 amount, uint256 amountToSend) public {
        amount = bound(amount, 2e5, type(uint96).max);
        amountToSend = bound(amountToSend, 1e5, amount - 1e5);

        vm.prank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();

        address user2 = makeAddr("user2");
        uint256 userBalance = rebaseToken.balanceOf(user);
        uint256 user2Balance = rebaseToken.balanceOf(user2);

        assertEq(userBalance, amount);
        assertEq(user2Balance, 0);

        vm.prank(owner);
        rebaseToken.setInterestRate(4e10);

        vm.prank(user);
        rebaseToken.transfer(user2, amountToSend);

        uint256 userBalanceAfterTransfer = rebaseToken.balanceOf(user);
        uint256 user2BalanceAfterTransfer = rebaseToken.balanceOf(user2);

        assertEq(userBalanceAfterTransfer, userBalance - amountToSend);
        assertEq(user2BalanceAfterTransfer, amountToSend);

        assertEq(rebaseToken.getUserInterestRate(user), 5e10);
        assertEq(rebaseToken.getUserInterestRate(user2), 5e10);
    }

    function testCannotSetInterestRate(uint256 interestRate) public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        rebaseToken.setInterestRate(interestRate);
    }

    function testCannotCallMintAndBurn(uint256 amount, address to) public {
        vm.prank(user);
        vm.expectRevert();
        rebaseToken.burn(to, amount);

        uint256 interestRate = rebaseToken.getInterestRate();

        vm.prank(user);
        vm.expectRevert();
        rebaseToken.mint(to, amount, interestRate);
    }

    function testGetPrincipleAmount(uint256 amount, uint256 time) public {
        amount = bound(amount, 1e5, type(uint96).max);
        time = bound(time, 1e5, type(uint32).max);

        vm.prank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();

        vm.warp(block.timestamp + time);

        assertEq(rebaseToken.principleBalanceOf(user), amount);
    }

    function testInterestRatesCanOnlyDecrease(uint256 rate) public {
        uint256 currentRate = rebaseToken.getInterestRate();
        rate = bound(rate, currentRate, type(uint96).max);

        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(RebaseToken.RebaseToken__InterestRateCanOnlyDecrease.selector, currentRate, rate)
        );
        rebaseToken.setInterestRate(rate);
    }
}
