/// TODO: frh -> Deploy on same vanity address https://0xfoobar.substack.com/p/vanity-addresses?nthPub=22&profile-setup-message=post-subscribe-prompt
/// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import "forge-std/Script.sol";
import "../src/tokens/MockDAI.sol";
import {LibString} from "solmate/utils/LibString.sol";

contract MockDAIScript is Script {
    string privateKeyChain;

    UChildDAI internal dai;

    function setUp() public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        privateKeyChain = string.concat("PRIVATE_KEY_", LibString.toString(chainId));
        this;
    }

    function deployTestnet() public {
        dai = new UChildDAI();
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint(privateKeyChain);
        vm.startBroadcast(deployerPrivateKey);

        deployTestnet();

        vm.stopBroadcast();
    }
}
