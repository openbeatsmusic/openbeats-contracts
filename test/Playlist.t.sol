// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "forge-std/Test.sol";
import "../src/Playlist.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

// USDC is 6 decimals
contract MockERC20 is ERC20("", "", 6) {}

contract PlaylistTest is Test {
    address alice = address(0xABCD);
    IERC20 paymentToken;
    uint256 tokenAmount;
    uint256 monthlyFee = 4 * 1e6;
    Playlist public playlist;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    function setUp() public {
        playlist = new Playlist();
        tokenAmount = playlist.TOKEN_AMOUNT();
        paymentToken = IERC20(address(new MockERC20()));
        setUpBalances();
    }

    // TODO: frh -> set more accounts
    function setUpBalances() public {
        deal(address(paymentToken), address(alice), monthlyFee * 2);
    }

    function payMonthlyFee(address from) public {
        vm.prank(from);
        paymentToken.transfer(address(playlist), monthlyFee);
    }

    function testDealERC20() public {
        deal(address(paymentToken), address(alice), monthlyFee);
        assertEq(paymentToken.balanceOf(address(alice)), monthlyFee);
    }

    function testMint() public {
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(alice, address(0), alice, 0, tokenAmount);
        vm.prank(alice);
        playlist.mint(0);
        assertEq(playlist.balanceOf(alice, 0), tokenAmount);
    }

    function testPayMonthlyFee() public {
        payMonthlyFee(alice);
        assertEq(paymentToken.balanceOf(address(playlist)), monthlyFee);
    }
}
