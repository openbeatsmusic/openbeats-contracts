/// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Supply} from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
/// No need to resetRoyalty in burn since playlist has no burn implemented
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "./libraries/TransferHelper.sol";

contract Playlist is ERC1155, ERC1155Supply, ERC2981 {
    struct Royalty {
        uint24 id;
        uint64 amount;
    }

    /// Maximum number of playlists uint24 = 16,777,215;
    /// NFT id => balance
    mapping(uint24 => uint256) public balanceOfPlaylist;

    // Id of next minted nft
    uint24 private _id = 0;

    /// OpenBeats
    address public openbeats;
    // Set royalty to 5%
    uint16 private royalty = 5;
    /// Payment token
    address public currency;
    /// Monthly plan
    uint64 public plan = 4 * 1e18;
    /// Maximum royalties paid per month
    uint64 private maxAmount = 3 * 1e18;
    /// OpenBeats fee
    uint64 public fee = 1 * 1e18;
    /// Total feesEarned
    uint96 private feesEarned;
    uint8 public royaltyLength = 30;

    constructor(address _currency, address _openbeats)
        ERC1155("https://api.openbeats.xyz/openbeats/v1/playlist/metadata/{id}")
    {
        currency = _currency;
        openbeats = _openbeats;
        _setDefaultRoyalty(_openbeats, royalty * 100);
    }

    /**
     * @dev See {ERC1155Supply-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override (ERC1155, ERC1155Supply){
        ERC1155Supply._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function getFeesEarned() public view returns (uint256) {
        return feesEarned;
    }

    function mint(uint24 id, uint24 supply) public {
        require(id == _id, "Wrong id");
        super._mint(_msgSender(), id, supply, "");
        _id += 1;
    }


    function payPlan(address from, Royalty[] calldata royalties) public {
        uint64 _maxAmount;
        require(royalties.length <= royaltyLength, "Length");

        for (uint8 i = 0; i < royalties.length; i++) {
            unchecked {
                _maxAmount += royalties[i].amount;
            }
        }

        require(_maxAmount <= maxAmount, "MaxAmount");

        unchecked {
            feesEarned += fee;
        }
        for (uint8 i = 0; i < royalties.length; i++) {
            /// Cannot overflow because the sum of all playlist balances can't exceed the max uint256 value.
            unchecked {
                balanceOfPlaylist[royalties[i].id] += royalties[i].amount;
            }
        }
        TransferHelper.safeTransferFrom(currency, from, address(this), plan);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
