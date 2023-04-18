// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "forge-std/Test.sol";
import "src/Playlist.sol";
import "./utils/SigUtils.sol";
import "src/tokens/MockDAI.sol";

contract PlaylistTest is Test {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 public constant INTERFACE_ID_ERC2981 = 0x2a55205a;

    uint24 tokenAmount = 10000;
    uint24 id = 0;
    uint64 plan = 4 * 1e18;
    uint8 royaltyLength = 30;
    uint64 royaltyAmount = plan / royaltyLength * 3 / 4;

    uint8 OpenBeatsCreatorRoyalties = 5;
    uint8 tokenSalePrice = 100;

    uint256 internal alicePrivateKey;
    address alice;
    address OpenBeats = address(2);

    Playlist public playlist;
    Playlist.Royalty[] royalties;

    SigUtils internal sigUtils;
    UChildDAI internal dai;

    function setUp() public {
        dai = new UChildDAI();
        playlist = new Playlist(address(dai), OpenBeats);
        sigUtils = new SigUtils(dai.getDomainSeperator());

        /// We get alice private keys to be able to sign, alice = (private keys [0] of anvil)
        alicePrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        alice = vm.addr(alicePrivateKey);

        setUpBalances();
        setUpPermit();
        setUpMint();
        setUpRoyalties();
    }

    function setUpBalances() public {
        deal(address(dai), address(alice), plan);
    }

    function setUpPermit() public {
        vm.prank(alice);
        SigUtils.Permit memory permit =
            SigUtils.Permit({holder: alice, spender: address(playlist), nonce: 0, expiry: 1714514400, allowed: true});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

        dai.permit(permit.holder, permit.spender, permit.nonce, permit.expiry, permit.allowed, v, r, s);
    }

    function setUpMint() public {
        vm.startPrank(alice);
        for (uint8 i = 0; i < royaltyLength; i++) {
            playlist.mint(i, tokenAmount);
        }
        vm.stopPrank();
    }

    function setUpRoyalties() public {
        for (uint8 i = 0; i < royaltyLength; i++) {
            royalties.push(Playlist.Royalty(i, royaltyAmount));
        }
    }

    function test_DealERC20() public {
        deal(address(dai), address(alice), plan);
        assertEq(dai.balanceOf(address(alice)), plan);
    }

    function test_Mint() public {
        uint24 _id = 1 + uint24(royaltyLength);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(alice, address(0), alice, _id, tokenAmount);
        vm.prank(alice);
        playlist.mint(_id, tokenAmount);
        assertEq(playlist.balanceOf(alice, id), tokenAmount);
    }

    function test_PayPlan() public {
        assertEq(dai.balanceOf(address(alice)), plan);
        playlist.payPlan(alice, royalties);
        assertEq(playlist.getFeesEarned(), plan * 1 / 4);
        for (uint8 i = 0; i < royaltyLength; i++) {
            assertEq(playlist.balanceOfPlaylist(i), royaltyAmount);
        }
        assertEq(dai.balanceOf(address(alice)), 0);
    }

    function test_RevertWhen_RoyaltiesExceedLength() public {
        royalties.push(Playlist.Royalty(31, 50));
        vm.expectRevert("Length");
        playlist.payPlan(alice, royalties);
    }

    function test_RevertWhen_AmountExceedPlan() public {
        royalties.pop();
        royalties.push(Playlist.Royalty(30, plan));
        vm.expectRevert("MaxAmount");
        playlist.payPlan(alice, royalties);
    }

    function test_RoyaltyInfo() public {
        (address receiver, uint256 royaltyAmount) = playlist.royaltyInfo(id, tokenSalePrice);
        assertEq(receiver, OpenBeats);
        assertEq(royaltyAmount, OpenBeatsCreatorRoyalties);
    }

    function test_SupportsInterface() public {
        assertEq(playlist.supportsInterface(INTERFACE_ID_ERC1155), true);
        assertEq(playlist.supportsInterface(INTERFACE_ID_ERC2981), true);
    }
}
