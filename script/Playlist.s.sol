/// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "forge-std/Script.sol";
import "src/Playlist.sol";
import {LibString} from "solmate/utils/LibString.sol";

contract DeployPlaylist is Script {
    address public currency;
    address public openbeats;

    function setUp() public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        currency = vm.envAddress(string.concat("CURRENCY_", LibString.toString(chainId)));
        openbeats = vm.envAddress(string.concat("OB_ADDRESS_", LibString.toString(chainId)));
        this;
    }

    function run() external {
        vm.startBroadcast();

        new Playlist(currency, openbeats);

        vm.stopBroadcast();
    }
}
