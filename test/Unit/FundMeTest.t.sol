// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 20 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // Next line should revert, testing that revert works
        fundMe.fund();
    }

    modifier funded() {
        vm.prank(USER); // Next TX will be sent by user
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(address(USER));
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(
            (startingOwnerBalance + startingFundMeBalance),
            endingOwnerBalance
        );
        assertEq(endingFundMeBalance, 0);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint256 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // Setup prank address and deal ether in one go!
            hoax(address(i), SEND_VALUE);
            // Fund this address that is hoaxed, as it is also being pranked
            fundMe.fund{value: SEND_VALUE}();
        }

        // Act
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // Assert
        assert(
            (startingOwnerBalance + startingFundMeBalance) ==
                fundMe.getOwner().balance
        );
        assert(address(fundMe).balance == 0);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        // Arrange
        uint256 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // Setup prank address and deal ether in one go!
            hoax(address(i), SEND_VALUE);
            // Fund this address that is hoaxed, as it is also being pranked
            fundMe.fund{value: SEND_VALUE}();
        }

        // Act
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        // Assert
        assert(
            (startingOwnerBalance + startingFundMeBalance) ==
                fundMe.getOwner().balance
        );
        assert(address(fundMe).balance == 0);
    }

    /* How to work with addresses outside our system?
    1. Unit
        - Testing a specific part of our code
    2. Integration
        - Testing how our code works with other parts of our code
    3. Forked
        -Testing our code on a simulated real environment
    4. Staging
        - Testing our code in a real environment that is not prod */
}
