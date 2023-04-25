/// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "forge-std/Script.sol";
import "src/Playlist.sol";
import "src/PlaylistProxy.sol";
import {LibString} from "solmate/utils/LibString.sol";

contract DeployPlaylist is Script {
    address public currency;

    function setUp() public {
        uint256 chainId;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
        currency = vm.envAddress(string.concat("CURRENCY_", LibString.toString(chainId)));
        this;
    }

    function run() public {
        vm.startBroadcast();

        address implementation = address(new Playlist());
        address playlistProxy = address(new PlaylistProxy(implementation, ""));
        Playlist playlist = Playlist(playlistProxy);
        playlist.initialize(currency);

        vm.stopBroadcast();
    }
}
