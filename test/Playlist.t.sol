// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "forge-std/Test.sol";
import "../src/Playlist.sol";

contract PlaylistTest is Test {
    address alice = address(0xABCD);

    uint256 tokenAmount;

    Playlist public playlist;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    function setUp() public {
        playlist = new Playlist();
        tokenAmount = playlist.TOKEN_AMOUNT();
    }

    function testMint() public {
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(alice, address(0), alice, 0, tokenAmount);
        vm.prank(alice);
        playlist.mint(0);
        assertEq(playlist.balanceOf(alice, 0), tokenAmount);
    }
}
