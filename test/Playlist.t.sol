// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "forge-std/Test.sol";
import "../src/Playlist.sol";
import "./utils/SigUtils.sol";
import "../src/tokens/MockDAI.sol";

contract PlaylistTest is Test {
    uint256 tokenAmount;
    uint256 monthlyFee = 4 * 1e6;
    Playlist public playlist;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    SigUtils internal sigUtils;
    UChildDAI internal dai;

    uint256 internal alicePrivateKey;
    address alice;

    function setUp() public {
        dai = new UChildDAI();
        playlist = new Playlist(address(dai));
        tokenAmount = playlist.TOKEN_AMOUNT();
        sigUtils = new SigUtils(dai.getDomainSeperator());

        /// We get alice private keys to be able to sign, alice = (private keys [0] of anvil)
        alicePrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        alice = vm.addr(alicePrivateKey);

        setUpBalances();
    }

    /// TODO: frh -> set more accounts
    function setUpBalances() public {
        deal(address(dai), address(alice), monthlyFee * 2);
    }

    function testDealERC20() public {
        deal(address(dai), address(alice), monthlyFee);
        assertEq(dai.balanceOf(address(alice)), monthlyFee);
    }

    function testMint() public {
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(alice, address(0), alice, 0, tokenAmount);
        vm.prank(alice);
        playlist.mint(0);
        assertEq(playlist.balanceOf(alice, 0), tokenAmount);
    }

    function testPayMonthlyFeeForUser() public {
        vm.prank(alice);
        SigUtils.Permit memory permit = SigUtils.Permit({
            holder: alice,
            spender: address(playlist),
            nonce: 0,
            // TODO: frh -> change this date and set date of contract at start test
            expiry: 1714514400,
            allowed: true
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

        vm.prank(address(playlist));
        dai.permit(permit.holder, permit.spender, permit.nonce, permit.expiry, permit.allowed, v, r, s);
        assertEq(dai.allowance(alice, address(playlist)), type(uint256).max);

        /// transferFrom should be called from spender
        vm.prank(address(playlist));
        dai.transferFrom(alice, address(playlist), monthlyFee);
    }

    function testPaymentTokenAddress() public {
        assertEq(playlist.paymentToken(), address(dai));
    }
}
