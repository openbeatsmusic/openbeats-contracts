// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "forge-std/Test.sol";
import "src/Playlist.sol";
import "src/PlaylistProxy.sol";
import "./utils/SigUtils.sol";
import "src/tokens/MockDAI.sol";

contract PlaylistTest is Test {
    address public alice;
    uint256 public aliceBalance = 1000 * 1e18;
    uint256 public alicePrivateKey;

    UChildDAI public dai;

    // Set up date to 03/31/23 for more realistic testing
    uint256 public currentDate = 1_680_220_800;
    uint64 public plan = 4 * 1e18;
    Playlist public playlist;
    uint24 public tokenAmount = 10000;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    function setUp() public {
        setUpDate();
        dai = new UChildDAI();

        /// We get alice private keys to be able to sign, alice = (private keys [0] of anvil)
        alicePrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        alice = vm.addr(alicePrivateKey);
        setUpProxy();

        setUpPermit();
        deal(address(dai), alice, aliceBalance);
    }

    function setUpDate() public {
        vm.warp(currentDate);
    }

    function setUpPermit() public {
        vm.prank(alice);
        SigUtils sigUtils = new SigUtils(dai.getDomainSeperator());
        SigUtils.Permit memory permit =
            SigUtils.Permit({holder: alice, spender: address(playlist), nonce: 0, expiry: 1714514400, allowed: true});

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePrivateKey, digest);

        dai.permit(permit.holder, permit.spender, permit.nonce, permit.expiry, permit.allowed, v, r, s);
    }

    function setUpProxy() public {
        vm.startPrank(alice);
        address implementation = address(new Playlist());
        address playlistProxy = address(new PlaylistProxy(implementation, ""));
        playlist = Playlist(playlistProxy);
        playlist.initialize(address(dai));
        vm.stopPrank();
    }

    function test_Init() public {
        assertEq(playlist.getInitializedVersion(), 1);
        assertEq(playlist.name(), "OpenBeats");
        assertEq(playlist.symbol(), "OB");
    }

    function test_Mint() public {
        uint24 id = 0;
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(alice, address(0), alice, id, tokenAmount);
        vm.prank(alice);
        playlist.mint(id, tokenAmount);
        assertEq(playlist.balanceOf(alice, id), tokenAmount);
        assertEq(playlist.depositsOf(alice), 0);
    }

    function test_PayPlan() public {
        uint8 royaltyLength = 30;
        uint64 royaltyAmount = plan / royaltyLength * 3 / 4;
        Playlist.Royalty[30] memory royalties;
        royalties[0] = Playlist.Royalty(0, royaltyAmount);
        royalties[1] = Playlist.Royalty(1, royaltyAmount);
        royalties[2] = Playlist.Royalty(2, royaltyAmount);
        royalties[3] = Playlist.Royalty(3, royaltyAmount);
        royalties[4] = Playlist.Royalty(4, royaltyAmount);
        royalties[5] = Playlist.Royalty(5, royaltyAmount);
        royalties[6] = Playlist.Royalty(6, royaltyAmount);
        royalties[7] = Playlist.Royalty(7, royaltyAmount);
        royalties[8] = Playlist.Royalty(8, royaltyAmount);
        royalties[9] = Playlist.Royalty(9, royaltyAmount);
        royalties[10] = Playlist.Royalty(10, royaltyAmount);
        royalties[11] = Playlist.Royalty(11, royaltyAmount);
        royalties[12] = Playlist.Royalty(12, royaltyAmount);
        royalties[13] = Playlist.Royalty(13, royaltyAmount);
        royalties[14] = Playlist.Royalty(14, royaltyAmount);
        royalties[15] = Playlist.Royalty(15, royaltyAmount);
        royalties[16] = Playlist.Royalty(16, royaltyAmount);
        royalties[17] = Playlist.Royalty(17, royaltyAmount);
        royalties[18] = Playlist.Royalty(18, royaltyAmount);
        royalties[19] = Playlist.Royalty(19, royaltyAmount);
        royalties[20] = Playlist.Royalty(20, royaltyAmount);
        royalties[21] = Playlist.Royalty(21, royaltyAmount);
        royalties[22] = Playlist.Royalty(22, royaltyAmount);
        royalties[23] = Playlist.Royalty(23, royaltyAmount);
        royalties[24] = Playlist.Royalty(24, royaltyAmount);
        royalties[25] = Playlist.Royalty(25, royaltyAmount);
        royalties[26] = Playlist.Royalty(26, royaltyAmount);
        royalties[27] = Playlist.Royalty(27, royaltyAmount);
        royalties[28] = Playlist.Royalty(28, royaltyAmount);
        royalties[29] = Playlist.Royalty(29, royaltyAmount);

        vm.startPrank(alice);
        for (uint8 i = 0; i < royaltyLength; i++) {
            playlist.mint(i, tokenAmount);
        }
        assertEq(dai.balanceOf(alice), aliceBalance);
        playlist.payPlan(alice, royalties);
        assertEq(playlist.getFeesEarned(), plan * 1 / 4);
        vm.stopPrank();

        for (uint8 i = 0; i < royaltyLength; i++) {
            assertEq(playlist.treasuryOfPlaylist(i, playlist.monthCounter()), royaltyAmount);
        }
        assertEq(dai.balanceOf(alice), aliceBalance - plan);
    }

    function test_Owner() public {
        assertEq(playlist.owner(), alice);
    }

    function test_Paused() public {
        vm.startPrank(alice);
        assertEq(playlist.paused(), false);
        playlist.setPaused(true);
        assertEq(playlist.paused(), true);
        playlist.setPaused(false);
        assertEq(playlist.paused(), false);
        vm.stopPrank();
    }

    function test_RevertWhen_AmountExceedPlan() public {
        Playlist.Royalty[30] memory royalties;
        vm.prank(alice);
        royalties[0] = Playlist.Royalty(0, plan);
        vm.expectRevert("MaxAmount");
        playlist.payPlan(alice, royalties);
    }

    function test_RevertWhen_CallerIsNotOwner() public {
        Playlist.Royalty[30] memory royalties;
        royalties[0] = Playlist.Royalty(0, plan / 4 * 3);
        vm.expectRevert("Ownable: caller is not the owner");
        vm.startPrank(address(2));
        playlist.payPlan(alice, royalties);
        vm.expectRevert("Ownable: caller is not the owner");
        playlist.getFeesEarned();
        vm.expectRevert("Ownable: caller is not the owner");
        playlist.setPaused(true);
        vm.stopPrank();
    }

    function test_RevertWhen_InitializeAgain() public {
        vm.expectRevert("Initializable: contract is already initialized");
        playlist.initialize(address(dai));
    }

    function test_RevertWhen_Paused() public {
        uint24 id = 0;
        vm.startPrank(alice);
        playlist.mint(id, tokenAmount);
        playlist.setPaused(true);
        vm.expectRevert("Token transfers paused");
        playlist.mint(1, tokenAmount);
        vm.expectRevert("Token transfers paused");
        playlist.safeTransferFrom(alice, address(3), id, 3333, "");
        vm.stopPrank();
    }

    function test_RevertWhen_RenounceOwnership() public {
        vm.prank(alice);
        vm.expectRevert("Cannot renounce ownership");
        playlist.renounceOwnership();
        assertEq(playlist.owner(), alice);
    }

    function test_RevertWhen_UpgradeNotApproved() public {
        vm.startPrank(address(2));
        address newImplementation = address(new Playlist());
        vm.expectRevert("Ownable: caller is not the owner");
        playlist.upgradeTo(newImplementation);
        vm.stopPrank();
    }

    function test_RoyaltyInfo() public {
        (address receiver, uint256 _royaltyAmount) = playlist.royaltyInfo(0, 100);
        assertEq(receiver, playlist.owner());
        assertEq(_royaltyAmount, 5);
    }

    function test__SafeBatchTransferFrom() public {
        uint24 id0 = 0;
        uint24 id1 = 1;
        uint256 amount0 = 3333;
        uint256 amount1 = 2856;
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = id0;
        ids[1] = id1;
        amounts[0] = amount0;
        amounts[1] = amount1;
        Playlist.Royalty[30] memory royalties0;
        royalties0[0] = Playlist.Royalty(id0, plan * 3 / 4);
        Playlist.Royalty[30] memory royalties1;
        royalties1[0] = Playlist.Royalty(id1, plan * 3 / 4);

        vm.startPrank(alice);
        playlist.mint(id0, tokenAmount);
        playlist.mint(id1, tokenAmount);

        for (uint8 i = 0; i < 3; i++) {
            playlist.payPlan(alice, royalties0);
            playlist.payPlan(alice, royalties1);
            skip(30 days);
        }
        playlist.safeBatchTransferFrom(alice, address(3), ids, amounts, "");
        assertEq(playlist.depositsOf(alice), plan * 3 / 4 * 4);

        skip(5 days);

        for (uint8 i = 0; i < 3; i++) {
            playlist.payPlan(alice, royalties0);
            playlist.payPlan(alice, royalties1);
            skip(30 days);
        }
        vm.stopPrank();
        vm.prank(address(3));
        playlist.safeBatchTransferFrom(address(3), alice, ids, amounts, "");
        assertEq(playlist.depositsOf(address(address(3))), plan * 3 / 4 * 4 * (amount0 + amount1) / tokenAmount);

        vm.prank(alice);
        playlist.safeBatchTransferFrom(alice, address(4), ids, amounts, "");
        assertEq(playlist.depositsOf(address(4)), 0);

        vm.prank(address(4));
        playlist.safeBatchTransferFrom(address(4), address(5), ids, amounts, "");
        assertEq(playlist.depositsOf(address(4)), 0);
        assertEq(playlist.depositsOf(address(5)), 0);
    }

    function test__SafeTransferFrom() public {
        uint24 id = 0;
        uint256 amount = 3333;
        Playlist.Royalty[30] memory royalties;
        royalties[0] = Playlist.Royalty(id, plan * 3 / 4);

        vm.startPrank(alice);
        playlist.mint(id, tokenAmount);

        for (uint8 i = 0; i < 3; i++) {
            playlist.payPlan(alice, royalties);
            skip(30 days);
        }
        playlist.safeTransferFrom(alice, address(3), id, amount, "");
        assertEq(playlist.depositsOf(alice), plan * 3 / 4 * 2);

        skip(5 days);

        for (uint8 i = 0; i < 3; i++) {
            playlist.payPlan(alice, royalties);
            skip(30 days);
        }
        vm.stopPrank();
        vm.prank(address(3));
        playlist.safeTransferFrom(address(3), alice, id, amount, "");
        assertEq(playlist.depositsOf(address(address(3))), plan * 3 / 4 * 4 * amount / tokenAmount);

        vm.prank(alice);
        playlist.safeTransferFrom(alice, address(4), id, amount, "");
        assertEq(playlist.depositsOf(address(4)), 0);

        vm.prank(address(4));
        playlist.safeTransferFrom(address(4), address(5), id, amount, "");
        assertEq(playlist.depositsOf(address(4)), 0);
        assertEq(playlist.depositsOf(address(5)), 0);
    }

    function test_EIP165() public {
        bytes4 interfaceIdERC1155 = 0xd9b67a26;
        bytes4 interfaceIdERC2981 = 0x2a55205a;
        assertEq(playlist.supportsInterface(interfaceIdERC1155), true);
        assertEq(playlist.supportsInterface(interfaceIdERC2981), true);
    }

    function test_UpgradeApproved() public {
        vm.startPrank(alice);
        address newImplementation = address(new Playlist());
        playlist.upgradeTo(newImplementation);
        assertEq(playlist.name(), "OpenBeats");
        assertEq(playlist.symbol(), "OB");
        vm.stopPrank();
        // If new state, should be done with:
        // playlist.reinitialize(address(2));
        // assertEq(playlist.getInitializedVersion(), 2);
        // When reinitializing contract a reinitialize function should be implemented, which would like:
        // /// @dev Initialize sets first version of the contract, later versions should use reinitializer
        // /// @dev Royalties are sent to owner of the contract
        // function reinitialize(address currency_) external reinitializer(2) {
        //     currency = currency_;
        //     monthCounter = 1;
        //     paused = false;
        //     _escrow = new Escrow(currency_);
        //     _nextId = 0;
        //     _timestamp = block.timestamp;
        //     __ERC1155_init("https://api.openbeats.xyz/openbeats/v1/playlist/metadata/{id}");
        //     __ERC1155Supply_init();
        //     __ERC2981_init();
        //     __Ownable_init();
        //     __UUPSUpgradeable_init();
        //     _setDefaultRoyalty(super.owner(), 500);
        // }
    }
}
