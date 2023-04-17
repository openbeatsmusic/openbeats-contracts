/// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "./libraries/TransferHelper.sol";

contract Playlist is ERC1155 {
    struct Royalty {
        uint24 id;
        uint256 amount;
    }

    /// Maximum number of playlists uint24 = 16,777,215;
    /// NFT id => balance
    mapping(uint24 => uint256) public balanceOfPlaylist;

    /// Payment token
    address public currency;
    /// Monthly plan
    uint256 public plan = 4 * 1e18;
    /// Maximum royalties paid per month
    uint256 private maxAmount = 3 * 1e18;
    /// OpenBeats fee
    uint256 public fee = 1 * 1e18;
    /// Total feesEarned
    uint256 private feesEarned;
    uint256 public royaltyLength = 30;

    constructor(address _currency) ERC1155("https://api.openbeats.xyz/openbeats/v1/playlist/getbyid/{id}") {
        currency = _currency;
    }

    function mint(uint256 id, uint256 supply) public {
        super._mint(_msgSender(), id, supply, "");
    }

    function getFeesEarned() public view returns (uint256) {
        return feesEarned;
    }

    function payPlan(address from, Royalty[] calldata royalties) public {
        uint256 _maxAmount;
        require(royalties.length <= royaltyLength, "Length");

        for (uint256 i = 0; i < royalties.length; i++) {
            unchecked {
                _maxAmount += royalties[i].amount;
            }
        }

        require(_maxAmount <= maxAmount, "MaxAmount");

        unchecked {
            feesEarned += fee;
        }
        for (uint256 i = 0; i < royalties.length; i++) {
            /// Cannot overflow because the sum of all playlist balances can't exceed the max uint256 value.
            unchecked {
                balanceOfPlaylist[royalties[i].id] += royalties[i].amount;
            }
        }
        TransferHelper.safeTransferFrom(currency, from, address(this), plan);
    }
}
