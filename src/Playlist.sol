// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "./libraries/TransferHelper.sol";

contract Playlist is ERC1155 {
    // TODO: frh -> check how I should change this
    // TODO: frh -> check if payment token will be used for withdrawals
    uint256 public constant TOKEN_AMOUNT = 10000;
    uint256 public monthlyFee = 4 * 1e6;
    address public paymentToken;

    constructor(address _paymentToken) ERC1155("https://api.openbeats.xyz/openbeats/v1/playlist/getbyid/{id}") {
        paymentToken = _paymentToken;
    }

    // TODO: frh -> check if mint could be gasless
    function mint(uint256 id) public {
        super._mint(_msgSender(), id, TOKEN_AMOUNT, "");
    }
}
