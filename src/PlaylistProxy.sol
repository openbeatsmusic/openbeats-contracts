// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @dev Playlist  Proxy Access Contract
contract PlaylistProxy is ERC1967Proxy {
    // solhint-disable-next-line no-empty-blocks
    constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data) {}
}
