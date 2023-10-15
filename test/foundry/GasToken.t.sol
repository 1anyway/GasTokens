// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import {Utils} from "./utils/Utils.sol";
import "../../contracts/GasToken.sol";
import {console} from "forge-std/console.sol";

contract GasTokenTest is Test {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    GasToken public gasToken;

    address public constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; // wrapped ETH

    uint256 public ethereumFork;
    string public ETHEREUM_RPC_URL = vm.envString("ETHEREUM_RPC_URL");
    uint256 public constant BLOCK_NUM = 17210000;

    Utils internal utils;
    address payable[] internal users;
    address internal treasury;
    address internal alice;
    address internal bob;
    address internal charlie;
    address internal dennis;
    address internal marketing;
    address internal staking;

    function setUp() public {
        ethereumFork = vm.createSelectFork(ETHEREUM_RPC_URL, BLOCK_NUM);

        utils = new Utils();
        users = utils.createUsers(7);
        treasury = users[0];
        alice = users[1];
        bob = users[2];
        charlie = users[3];
        dennis = users[4];
        marketing = users[5];

        gasToken = new GasToken();
    }

    function test_Deployment_Success() public {
        assertEq(gasToken.TAX_FEE(), 4);
        assertEq(gasToken.DENOMINATOR(), 100);
        assertEq(gasToken.name(), 'GasToken');
        assertEq(gasToken.symbol(), "GAS");
        assertEq(gasToken.decimals(), 18);
        // assertEq(gasToken.totalSupply(), 1e27);
        // assertEq(gasToken.getEffectiveTotal(), 1e27);
        assertEq(gasToken.getEarningFactor(), 1e18);
    }

    function test_transfer_ReflectionPresent_Success() public {
        gasToken.excludeAccount(address(this));
        gasToken.transfer(alice, 10000 ether);
        gasToken.transfer(bob, 20000 ether);
        gasToken.transfer(charlie, 30000 ether);
        uint256 balanceAliceBefore = gasToken.balanceOf(alice);
        uint256 balanceBobBefore = gasToken.balanceOf(bob);
        uint256 balanceCharlieBefore = gasToken.balanceOf(charlie);
        console.log("action 0");
        emit log_uint(balanceAliceBefore);
        emit log_uint(balanceBobBefore);
        emit log_uint(balanceCharlieBefore);
        vm.prank(charlie);
        console.log("action 1");
        gasToken.transfer(alice, 1000 ether);
        uint256 balanceAliceAfter = gasToken.balanceOf(alice);
        uint256 balanceBobAfter = gasToken.balanceOf(bob);
        uint256 balanceCharlieAfter = gasToken.balanceOf(charlie);
        emit log_uint(balanceAliceAfter);
        emit log_uint(balanceBobAfter);
        emit log_uint(balanceCharlieAfter);
        vm.prank(bob);
        console.log("action 2");
        gasToken.transfer(alice, 2000 ether);
        uint256 balanceAliceAfter2 = gasToken.balanceOf(alice);
        uint256 balanceBobAfter2 = gasToken.balanceOf(bob);
        uint256 balanceCharlieAfter2 = gasToken.balanceOf(charlie);
        emit log_uint(balanceAliceAfter2);
        emit log_uint(balanceBobAfter2);
        emit log_uint(balanceCharlieAfter2);
        vm.prank(alice);
        console.log("action 3");
        gasToken.transfer(charlie, 3000 ether);
        uint256 balanceAliceAfter3 = gasToken.balanceOf(alice);
        uint256 balanceBobAfter3 = gasToken.balanceOf(bob);
        uint256 balanceCharlieAfter3 = gasToken.balanceOf(charlie);
        emit log_uint(balanceAliceAfter3);
        emit log_uint(balanceBobAfter3);
        emit log_uint(balanceCharlieAfter3);
    }

    function test_transfer_ReflectionPresent() public {
        gasToken.excludeAccount(address(this));
        gasToken.transfer(alice, 10000 ether);
        gasToken.transfer(bob, 20000 ether);
        gasToken.transfer(charlie, 20000 ether);
        gasToken.transfer(dennis, 1000 ether);
        uint256 balanceAliceBefore = gasToken.balanceOf(alice);
        uint256 balanceBobBefore = gasToken.balanceOf(bob);
        uint256 balanceCharlieBefore = gasToken.balanceOf(charlie);
        uint256 balanceDennisBefore = gasToken.balanceOf(dennis);
        console.log("action 0");
        emit log_uint(balanceAliceBefore);
        emit log_uint(balanceBobBefore);
        emit log_uint(balanceCharlieBefore);
        emit log_uint(balanceDennisBefore);
        vm.prank(charlie);
        console.log("action 1");
        gasToken.transfer(alice, 1000 ether);
        uint256 balanceAliceAfter = gasToken.balanceOf(alice);
        uint256 balanceBobAfter = gasToken.balanceOf(bob);
        uint256 balanceCharlieAfter = gasToken.balanceOf(charlie);
        uint256 balanceDennisAfter = gasToken.balanceOf(dennis);
        emit log_uint(balanceAliceAfter);
        emit log_uint(balanceBobAfter);
        emit log_uint(balanceCharlieAfter);
        emit log_uint(balanceDennisAfter);
        vm.prank(bob);
        console.log("action 2");
        gasToken.transfer(alice, 2000 ether);
        uint256 balanceAliceAfter2 = gasToken.balanceOf(alice);
        uint256 balanceBobAfter2 = gasToken.balanceOf(bob);
        uint256 balanceCharlieAfter2 = gasToken.balanceOf(charlie);
        uint256 balanceDennisAfter2 = gasToken.balanceOf(dennis);
        emit log_uint(balanceAliceAfter2);
        emit log_uint(balanceBobAfter2);
        emit log_uint(balanceCharlieAfter2);
        emit log_uint(balanceDennisAfter2);
        gasToken.excludeAccount(dennis);
        vm.prank(alice);
        console.log("action 3");
        gasToken.transfer(bob, 2000 ether);
        uint256 balanceAliceAfter3 = gasToken.balanceOf(alice);
        uint256 balanceBobAfter3 = gasToken.balanceOf(bob);
        uint256 balanceCharlieAfter3 = gasToken.balanceOf(charlie);
        uint256 balanceDennisAfter3 = gasToken.balanceOf(dennis);
        emit log_uint(balanceAliceAfter3);
        emit log_uint(balanceBobAfter3);
        emit log_uint(balanceCharlieAfter3);
        emit log_uint(balanceDennisAfter3);
        vm.prank(alice);
        console.log("action 4");
        gasToken.transfer(charlie, 1000 ether);
        uint256 balanceAliceAfter4 = gasToken.balanceOf(alice);
        uint256 balanceBobAfter4 = gasToken.balanceOf(bob);
        uint256 balanceCharlieAfter4 = gasToken.balanceOf(charlie);
        uint256 balanceDennisAfter4 = gasToken.balanceOf(dennis);
        emit log_uint(balanceAliceAfter4);
        emit log_uint(balanceBobAfter4);
        emit log_uint(balanceCharlieAfter4);
        emit log_uint(balanceDennisAfter4);
    }

    function test_transfer_TransferTokens() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), alice, 10 ether);
        gasToken.transfer(alice, 10 ether);
        uint256 balanceAliceAfter = gasToken.balanceOf(alice);
        uint256 earningFactorAlice = gasToken.getSnapshot(alice);
        uint256 earningFactor = gasToken.getEarningFactor();
        console.log("action 1");
        assertGt(balanceAliceAfter, 9.6e18);
        assertEq(earningFactorAlice, 1 ether);
        assertGt(earningFactor, 1 ether);
        console.log("action2");
        gasToken.transfer(bob, 100 ether);
        uint256 balanceBobAfter = gasToken.balanceOf(bob);
        uint256 balanceAliceAfter2 = gasToken.balanceOf(alice);
        uint256 earningFactorAlice2 = gasToken.getSnapshot(alice);
        uint256 earningFactor2 = gasToken.getEarningFactor();
        assertGt(balanceAliceAfter2, balanceAliceAfter);
        assertGt(balanceBobAfter, 9.6e19);
        assertEq(earningFactorAlice, earningFactorAlice2);
        assertGt(earningFactor2, earningFactor);
        gasToken.transfer(charlie, 1000 ether);
        uint256 balanceAliceAfter3 = gasToken.balanceOf(alice);
        uint256 balanceBobAfter2 = gasToken.balanceOf(bob);
        uint256 balanceCharlieAfter = gasToken.balanceOf(charlie);
        uint256 earningFactorAlice3 = gasToken.getSnapshot(alice);
        uint256 earningFactor3 = gasToken.getEarningFactor();
        assertGt(balanceAliceAfter3, balanceAliceAfter2);
        assertGt(balanceBobAfter2, balanceBobAfter);
        assertGt(balanceCharlieAfter, 9.6e20);
        assertEq(earningFactorAlice3, earningFactorAlice2);
        assertGt(earningFactor3, earningFactor2);
        gasToken.transfer(dennis, 10000 ether);
        uint256 balanceAliceAfter4 = gasToken.balanceOf(alice);
        uint256 balanceBobAfter3 = gasToken.balanceOf(bob);
        uint256 balanceCharlieAfter2 = gasToken.balanceOf(charlie);
        uint256 balanceDennisAfter = gasToken.balanceOf(dennis);
        uint256 earningFactorAlice4 = gasToken.getSnapshot(alice);
        uint256 earningFactor4 = gasToken.getEarningFactor();
        assertGt(balanceAliceAfter4, balanceAliceAfter3);
        assertGt(balanceBobAfter3, balanceBobAfter2);
        assertGt(balanceCharlieAfter2, balanceCharlieAfter);
        assertGt(balanceDennisAfter, 9.6e21);
        assertEq(earningFactorAlice4, earningFactorAlice3);
        assertGt(earningFactor4, earningFactor3);
    }

    function test_excludeAccount_Transfer() public {
        gasToken.excludeAccount(address(this));
        gasToken.transfer(alice, 10 ether);
        uint256 balanceAliceAfter = gasToken.balanceOf(alice);
        uint256 earningFactorSender = gasToken.getSnapshot(address(this));
        uint256 earningFactorAlice = gasToken.getSnapshot(alice);
        uint256 earningFactor = gasToken.getEarningFactor();
        assertEq(earningFactorSender, 1 ether);
        assertEq(balanceAliceAfter, 10 ether);
        assertEq(earningFactorAlice, 1 ether);
        assertEq(earningFactor, 1 ether);
        gasToken.transfer(bob, 100 ether);
    }

    function test_transferFrom_Success() public {
        vm.expectEmit(true, true, true, true);
        emit Approval(address(this), alice, 10 ether);
        gasToken.approve(alice, 10 ether);
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit Approval(address(this), alice, 0);
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), alice, 10 ether);
        gasToken.transferFrom(address(this), alice, 10 ether);
    }

    function test_transferFrom_Reflection_Success() public {
        gasToken.approve(alice, 10 ether);
        vm.prank(alice);
        gasToken.transferFrom(address(this), bob, 10 ether);
        uint256 balanceBobAfter = gasToken.balanceOf(bob);
        uint256 earningFactorSender = gasToken.getSnapshot(address(this));
        uint256 earningFactorBob = gasToken.getSnapshot(bob);
        uint256 earningFactor = gasToken.getEarningFactor();
        assertGt(balanceBobAfter, 9.6e18);
        assertEq(earningFactorSender, 1 ether);
        assertEq(earningFactorBob, 1 ether);
        assertGt(earningFactor, 1 ether);
    }

    function test_increaseAllowance_Success() public {
        gasToken.increaseAllowance(alice, 10 ether);
        assertEq(gasToken.allowance(address(this), alice), 10 ether);
        vm.prank(alice);
        gasToken.transferFrom(address(this), bob, 10 ether);
    }

    function test_decreaseAllowance_Success() public {
        gasToken.increaseAllowance(alice, 10 ether);
        assertEq(gasToken.allowance(address(this), alice), 10 ether);
        gasToken.decreaseAllowance(alice, 5 ether);
        assertEq(gasToken.allowance(address(this), alice), 5 ether);
        vm.prank(alice);
        gasToken.transferFrom(address(this), bob, 5 ether);
    }

    function test_includeAccount_Success() public {

    }

    function test_excludeAccount_Success() public {

    }

    function test_transfer_Reflection() public {
        gasToken.transfer(treasury, 11573 ether);
        vm.startPrank(treasury);
        gasToken.transfer(alice, 10 ether);
        uint256 balanceAliceAfter = gasToken.balanceOf(alice);
        uint256 earningFactorAlice = gasToken.getSnapshot(alice);
        uint256 earningFactor = gasToken.getEarningFactor();
        console.log("Tx 1");
        emit log_uint(balanceAliceAfter);
        emit log_uint(earningFactorAlice);
        emit log_uint(earningFactor);
        gasToken.transfer(bob, 100 ether);
        uint256 balanceBobAfter = gasToken.balanceOf(bob);
        balanceAliceAfter = gasToken.balanceOf(alice);
        earningFactorAlice = gasToken.getSnapshot(alice);
        earningFactor = gasToken.getEarningFactor();
        console.log("Tx 2");
        emit log_uint(balanceAliceAfter);
        emit log_uint(earningFactorAlice);
        emit log_uint(earningFactor);
        emit log_uint(balanceBobAfter);
        gasToken.transfer(charlie, 1000 ether);
        balanceAliceAfter = gasToken.balanceOf(alice);
        earningFactorAlice = gasToken.getSnapshot(alice);
        earningFactor = gasToken.getEarningFactor();
        balanceBobAfter = gasToken.balanceOf(bob);
        uint256 balanceCharlieAfter = gasToken.balanceOf(charlie);
        console.log("Tx 3");
        emit log_uint(balanceAliceAfter);
        emit log_uint(earningFactorAlice);
        emit log_uint(earningFactor);
        emit log_uint(balanceBobAfter);
        emit log_uint(balanceCharlieAfter);
        emit log_uint(gasToken.balanceOf(treasury));
        gasToken.transfer(dennis, 10000 ether);
        balanceAliceAfter = gasToken.balanceOf(alice);
        earningFactorAlice = gasToken.getSnapshot(alice);
        earningFactor = gasToken.getEarningFactor();
        balanceBobAfter = gasToken.balanceOf(bob);
        balanceCharlieAfter = gasToken.balanceOf(charlie);
        uint256 balanceDennisAfter = gasToken.balanceOf(dennis);
        console.log("Tx 4");
        emit log_uint(balanceAliceAfter);
        emit log_uint(earningFactorAlice);
        emit log_uint(earningFactor);
        emit log_uint(balanceBobAfter);
        emit log_uint(balanceCharlieAfter);
        emit log_uint(balanceDennisAfter);
    }

    function testGasCostsInTransferToken() public {
        gasToken.transfer(alice, 10 ether);
    }
}