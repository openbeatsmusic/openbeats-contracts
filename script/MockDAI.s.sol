// TODO: frh ->
// 1. remove warnings in mockDAI sol,
// 2. know how to pass diferent param for env keys from script
// 3. Know how to deploy to a fixed address
// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "forge-std/Script.sol";
import "../src/tokens/MockDAI.sol";

contract MockDAIScript is Script {
    UChildDAI internal dai;

    function setUp() public view {
        this;
    }

    function deployTestnet() public {
        dai = new UChildDAI();
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        deployTestnet();

        vm.stopBroadcast();
    }
}
