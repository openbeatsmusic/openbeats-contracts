// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract Playlist is ERC1155 {
    uint256 public constant TOKEN_AMOUNT = 10000;

    constructor() ERC1155("https://api.openbeats.xyz/openbeats/v1/playlist/getbyid/{id}") {}

    function mint(uint256 id) public {
        super._mint(_msgSender(), id, TOKEN_AMOUNT, "");
    }
}
