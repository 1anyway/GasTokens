// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import "forge-std/Test.sol";
import {Utils} from "./utils/Utils.sol";
import "../../contracts/GasToken.sol";
import {console} from "forge-std/console.sol";

contract GasTokenTest is Test {
    event Approval(address owner, address spender, uint256 amount);
    event Transfer(address sender, address recipient, uint256 amount);
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
        assertEq(gasToken.totalSupply(), 1e27);
        assertEq(gasToken.getEffectiveTotal(), 1e27);
        assertEq(gasToken.getEarningFactor(), 1e18);
    }

    function test_transfer_TransferTokens() public {
        // vm.expectEmit(true, true, true, true);
        // emit Transfer(address(this), alice, 10 ether);
        gasToken.transfer(alice, 10 ether);
        uint256 balanceAliceAfter = gasToken.balanceOf(alice);
        uint256 earningFactorAlice = gasToken.getSnapshot(alice);
        uint256 earningFactor = gasToken.getEarningFactor();
        console.log("Tx 1");
        assertGt(balanceAliceAfter, 9.6e18);
        assertEq(earningFactorAlice, 1 ether);
        assertGt(earningFactor, 1 ether);
        gasToken.transfer(bob, 100 ether);
        uint256 balanceBobAfter = gasToken.balanceOf(bob);
        uint256 balanceAliceAfter2 = gasToken.balanceOf(alice);
        earningFactorAlice = gasToken.getSnapshot(alice);
        earningFactor = gasToken.getEarningFactor();
        console.log("Tx 2");
        assertGt(balanceAliceAfter2, balanceAliceAfter);
        assertGt(balanceBobAfter, 9.6e19);
        emit log_uint(earningFactorAlice);
        emit log_uint(earningFactor);
        gasToken.transfer(charlie, 1000 ether);
        balanceAliceAfter = gasToken.balanceOf(alice);
        balanceBobAfter = gasToken.balanceOf(bob);
        uint256 balanceCharlieAfter = gasToken.balanceOf(charlie);
        earningFactorAlice = gasToken.getSnapshot(alice);
        earningFactor = gasToken.getEarningFactor();
        console.log("Tx 3");
        emit log_uint(balanceAliceAfter);
        emit log_uint(balanceBobAfter);
        emit log_uint(balanceCharlieAfter);
        emit log_uint(earningFactorAlice);
        emit log_uint(earningFactor);
        gasToken.transfer(dennis, 10000 ether);
        balanceAliceAfter = gasToken.balanceOf(alice);
        balanceBobAfter = gasToken.balanceOf(bob);
        balanceCharlieAfter = gasToken.balanceOf(charlie);
        uint256 balanceDennisAfter = gasToken.balanceOf(dennis);
        earningFactorAlice = gasToken.getSnapshot(alice);
        earningFactor = gasToken.getEarningFactor();
        console.log("Tx 4");
        emit log_uint(balanceAliceAfter);
        emit log_uint(balanceBobAfter);
        emit log_uint(balanceCharlieAfter);
        emit log_uint(balanceDennisAfter);
        emit log_uint(earningFactorAlice);
        emit log_uint(earningFactor);
    }

    function test_excludeAccount_Transfer() public {
        gasToken.excludeAccount(address(this));
        gasToken.transfer(alice, 10 ether);
        uint256 balanceAliceAfter = gasToken.balanceOf(alice);
        uint256 earningFactorAlice = gasToken.getSnapshot(alice);
        uint256 earningFactor = gasToken.getEarningFactor();

    }


    function test_transferFrom_Success() public {
        // vm.expectEmit(true, true, true, true);
        // emit Approval(address(this), alice, 10 ether);
        gasToken.approve(alice, 10 ether);
        vm.prank(alice);
        // vm.expectEmit(true, true, true, true);
        // emit Transfer(address(this), alice, 10 ether);
        // vm.expectEmit(true, true, true, true);
        // emit Approval(address(this), alice, 0);
        gasToken.transferFrom(address(this), alice, 10 ether);
    }

    function test_transferFrom_Reflection_Success() public {

    }

    function test_increaseAllowance_Success() public {
        gasToken.increaseAllowance(alice, 10 ether);
    }

    function test_decreaseAllowance_Success() public {
        gasToken.increaseAllowance(alice, 10 ether);
        gasToken.decreaseAllowance(alice, 5 ether);
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