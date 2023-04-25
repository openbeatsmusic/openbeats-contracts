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
    uint256 public plan = 4 * 1e18;
    Playlist public playlist;
    uint256 public tokenAmount = 10000;

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
        uint256 id = 0;
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(alice, address(0), alice, id, tokenAmount);
        vm.prank(alice);
        playlist.mint(id, tokenAmount);
        assertEq(playlist.balanceOf(alice, id), tokenAmount);
        assertEq(playlist.depositsOf(alice), 0);
    }

    function test_PayPlan() public {
        uint256 royaltyLength = 30;
        uint256 royaltyAmount = plan / royaltyLength * 3 / 4;
        uint256[] memory ids = new uint256[](30);
        uint256[] memory amounts = new uint256[](30);
        ids[0] = 1;
        ids[1] = 0;
        ids[2] = 2;
        ids[3] = 3;
        ids[4] = 4;
        ids[5] = 5;
        ids[6] = 6;
        ids[7] = 7;
        ids[8] = 8;
        ids[9] = 9;
        ids[10] = 10;
        ids[11] = 11;
        ids[12] = 12;
        ids[13] = 13;
        ids[14] = 14;
        ids[15] = 15;
        ids[16] = 16;
        ids[17] = 17;
        ids[18] = 18;
        ids[19] = 19;
        ids[20] = 20;
        ids[21] = 21;
        ids[22] = 22;
        ids[23] = 23;
        ids[24] = 24;
        ids[25] = 25;
        ids[26] = 26;
        ids[27] = 27;
        ids[28] = 28;
        ids[29] = 29;
        amounts[0] = royaltyAmount;
        amounts[1] = royaltyAmount;
        amounts[2] = royaltyAmount;
        amounts[3] = royaltyAmount;
        amounts[4] = royaltyAmount;
        amounts[5] = royaltyAmount;
        amounts[6] = royaltyAmount;
        amounts[7] = royaltyAmount;
        amounts[8] = royaltyAmount;
        amounts[9] = royaltyAmount;
        amounts[10] = royaltyAmount;
        amounts[11] = royaltyAmount;
        amounts[12] = royaltyAmount;
        amounts[13] = royaltyAmount;
        amounts[14] = royaltyAmount;
        amounts[15] = royaltyAmount;
        amounts[16] = royaltyAmount;
        amounts[17] = royaltyAmount;
        amounts[18] = royaltyAmount;
        amounts[19] = royaltyAmount;
        amounts[20] = royaltyAmount;
        amounts[21] = royaltyAmount;
        amounts[22] = royaltyAmount;
        amounts[23] = royaltyAmount;
        amounts[24] = royaltyAmount;
        amounts[25] = royaltyAmount;
        amounts[26] = royaltyAmount;
        amounts[27] = royaltyAmount;
        amounts[28] = royaltyAmount;
        amounts[29] = royaltyAmount;

        vm.startPrank(alice);
        for (uint256 i = 0; i < royaltyLength; i++) {
            playlist.mint(i, tokenAmount);
        }
        assertEq(dai.balanceOf(alice), aliceBalance);
        playlist.payPlan(alice, ids, amounts);
        assertEq(playlist.getFeesEarned(), plan * 1 / 4);
        vm.stopPrank();

        for (uint256 i = 0; i < royaltyLength; i++) {
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
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = 0;
        amounts[0] = plan;
        vm.prank(alice);
        vm.expectRevert("MaxAmount");
        playlist.payPlan(alice, ids, amounts);
    }

    function test_RevertWhen_CallerIsNotOwner() public {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = 0;
        amounts[0] = plan / 4 * 3;
        vm.expectRevert("Ownable: caller is not the owner");
        vm.startPrank(address(2));
        playlist.payPlan(alice, ids, amounts);
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
        uint256 id = 0;
        vm.startPrank(alice);
        playlist.mint(id, tokenAmount);
        playlist.setPaused(true);
        vm.expectRevert("Token transfers paused");
        playlist.mint(1, tokenAmount);
        vm.expectRevert("Token transfers paused");
        playlist.safeTransferFrom(alice, address(3), id, 3333, "");
        vm.stopPrank();
    }

    function test_RevertWhen_PayPlanArrayMismatch() public {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = 0;
        amounts[0] = plan / 4 * 3;
        amounts[1] = plan / 4 * 3;
        vm.prank(alice);
        vm.expectRevert("Array mismatch");
        playlist.payPlan(alice, ids, amounts);
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
        uint256 id0 = 0;
        uint256 id1 = 1;
        uint256 transferAmount0 = 3333;
        uint256 transferAmount1 = 2856;
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        uint256[] memory transferAmounts = new uint256[](2);
        ids[0] = id0;
        ids[1] = id1;
        amounts[0] = plan * 3 / 4 / 2;
        amounts[1] = plan * 3 / 4 / 2;
        transferAmounts[0] = transferAmount0;
        transferAmounts[1] = transferAmount1;

        vm.startPrank(alice);
        playlist.mint(id0, tokenAmount);
        playlist.mint(id1, tokenAmount);

        for (uint256 i = 0; i < 3; i++) {
            playlist.payPlan(alice, ids, amounts);
            playlist.payPlan(alice, ids, amounts);
            skip(30 days);
        }
        playlist.safeBatchTransferFrom(alice, address(3), ids, transferAmounts, "");
        assertEq(playlist.depositsOf(alice), plan * 3 / 4 * 4);

        skip(5 days);

        for (uint256 i = 0; i < 3; i++) {
            playlist.payPlan(alice, ids, amounts);
            playlist.payPlan(alice, ids, amounts);
            skip(30 days);
        }
        vm.stopPrank();
        vm.prank(address(3));
        playlist.safeBatchTransferFrom(address(3), alice, ids, transferAmounts, "");
        assertEq(
            playlist.depositsOf(address(address(3))),
            plan * 3 / 4 * 4 * (transferAmount0 + transferAmount1) / tokenAmount
        );

        vm.prank(alice);
        playlist.safeBatchTransferFrom(alice, address(4), ids, transferAmounts, "");
        assertEq(playlist.depositsOf(address(4)), 0);

        vm.prank(address(4));
        playlist.safeBatchTransferFrom(address(4), address(5), ids, transferAmounts, "");
        assertEq(playlist.depositsOf(address(4)), 0);
        assertEq(playlist.depositsOf(address(5)), 0);
    }

    function test__SafeTransferFrom() public {
        uint256 transferAmount = 3333;
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = 0;
        amounts[0] = plan / 4 * 3;

        vm.startPrank(alice);
        playlist.mint(ids[0], tokenAmount);

        for (uint256 i = 0; i < 3; i++) {
            playlist.payPlan(alice, ids, amounts);
            skip(30 days);
        }
        playlist.safeTransferFrom(alice, address(3), ids[0], transferAmount, "");
        assertEq(playlist.depositsOf(alice), plan * 3 / 4 * 2);

        skip(5 days);

        for (uint256 i = 0; i < 3; i++) {
            playlist.payPlan(alice, ids, amounts);
            skip(30 days);
        }
        vm.stopPrank();
        vm.prank(address(3));
        playlist.safeTransferFrom(address(3), alice, ids[0], transferAmount, "");
        assertEq(playlist.depositsOf(address(address(3))), plan * 3 / 4 * 4 * transferAmount / tokenAmount);

        vm.prank(alice);
        playlist.safeTransferFrom(alice, address(4), ids[0], transferAmount, "");
        assertEq(playlist.depositsOf(address(4)), 0);

        vm.prank(address(4));
        playlist.safeTransferFrom(address(4), address(5), ids[0], transferAmount, "");
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
