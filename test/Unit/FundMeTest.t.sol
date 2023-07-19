//SPDX-License-Identifier:MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    //address alice = makeAddr("alice");
    //emit log_address(alice); // 0x328809bc894f92807417d2dad6b7c998c1afdac6
    address USER = makeAddr("user");

    uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); //Give the new user some money!
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerisMsgSender() public {
        console.log(fundMe.getOwner());
        console.log(msg.sender);

        assertEq(fundMe.getOwner(), msg.sender); //these should i.e getter functions!!!
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // everything after this line should revert for the test to pass
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //the next TX will be sent by USER
        //so, fundMe.fund will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyUserCanWithdraw() public funded {
        vm.prank(USER);
        vm.expectRevert(); //expectRevert coz USER can't withdraw, only the Owner can withdraw
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        uint256 gasStart = gasleft(); //how much gas is left in the tx call //1000
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); //fundMe should be sent by the Owner //200
        fundMe.withdraw();
        uint256 gasEnd = gasleft(); //800
        //how much gas is left in the tx call after calling withdraw()

        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; //sol fn for current gas price
        console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0); // coz the Owner should have withdrawn the entirity
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // 1 coz often the 0th address gets reverted or something in tests
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank
            //vm.deal || these two are needed to create an account and make it have some funds
            //fund the fundMe

            //but use hoax for a combo of prank and deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner()); //fundMe should be sent by the Owner to withdraw
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // 1 coz often the 0th address gets reverted or something in tests
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank
            //vm.deal || these two are needed to create an account and make it have some funds
            //fund the fundMe

            //but use hoax for a combo of prank and deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.startPrank(fundMe.getOwner()); //fundMe should be sent by the Owner to withdraw
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //Assert
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            fundMe.getOwner().balance
        );
    }
}

// // Sets the *next* call's msg.sender to be the input address
//     function prank(address) external; until stopPrank is called

// us -> FundMe.test -> FundMe
// thus, owner of FundMe is FundMeTest  , so test with "this" instead of msg.sender
