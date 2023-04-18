/// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "forge-std/Script.sol";
import "src/tokens/MockDAI.sol";

contract DeployMockDAI is Script {
    function run() external {
        vm.startBroadcast();

        new UChildDAI();

        vm.stopBroadcast();
    }
}
