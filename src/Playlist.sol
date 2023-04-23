// solhint-disable not-rely-on-time
/// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ERC1155} from "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Supply} from "openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
/// No need to resetRoyalty in burn since playlist has no burn implemented
import {ERC2981} from "openzeppelin-contracts/contracts/token/common/ERC2981.sol";
import "./libraries/TransferHelper.sol";
import {Escrow} from "./Escrow.sol";

contract Playlist is ERC1155, ERC1155Supply, ERC2981, Ownable {
    struct Royalty {
        uint24 id;
        uint64 amount;
    }

    /// NFT id => monthCounter =>  treasuryOfPlaylist
    mapping(uint24 => mapping(uint24 => uint256)) public treasuryOfPlaylist;

    /// NFT id => Address => _lastMonthIncDeposited
    mapping(uint24 => mapping(address => uint24)) private _lastMonthIncDeposited;
    /// NFT id => Address => firstNoDepositedMonth => _balanceOfLastMonth
    mapping(uint24 => mapping(address => mapping(uint24 => uint256))) private _balanceOfLastMonth;

    address public currency;
    uint64 public fee = 1 * 1e18;
    uint24 public monthCounter = 1;
    string public name = "OpenBeats";
    uint64 public plan = 4 * 1e18;
    string public symbol = "OB";

    Escrow private immutable _escrow;
    uint96 private _feesEarned;
    /// Maximum royalties paid per month
    uint64 private _maxAmount = 3 * 1e18;
    /// Id of next minted nft
    uint24 private _nextId = 0;
    /// Set royalty to 5%
    uint16 private _royalty = 5;
    uint256 private _timestamp;

    /// Royalties are sent to owner of the contract
    constructor(address currency_) ERC1155("https://api.openbeats.xyz/openbeats/v1/playlist/metadata/{id}") {
        _escrow = new Escrow(currency_);
        currency = currency_;
        _setDefaultRoyalty(super.owner(), _royalty * 100);
        _timestamp = block.timestamp;
    }

    /// Maximum number of playlists uint24 = 16,777,215;
    function mint(uint24 id, uint24 supply) public {
        require(id == _nextId, "Wrong id");
        _nextId += 1;
        super._mint(_msgSender(), id, supply, "");
    }

    function payPlan(address from, Royalty[30] calldata royalties) public onlyOwner {
        uint64 maxAmount;

        for (uint8 i = 0; i < royalties.length; i++) {
            unchecked {
                maxAmount += royalties[i].amount;
            }
        }
        require(maxAmount <= _maxAmount, "MaxAmount");

        uint256 timestampDiff = block.timestamp - _timestamp;
        if (timestampDiff >= 30 days) {
            monthCounter += 1;
            _timestamp = block.timestamp;
        }

        unchecked {
            _feesEarned += fee;
        }
        for (uint8 i = 0; i < royalties.length; i++) {
            /// Cannot overflow because the sum of all playlist balances can't exceed the max uint256 value.
            unchecked {
                treasuryOfPlaylist[royalties[i].id][monthCounter] += royalties[i].amount;
            }
        }
        TransferHelper.safeTransferFrom(currency, from, address(this), plan);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param payee The creditor's address.
     */
    function depositsOf(address payee) public view returns (uint256) {
        return _escrow.depositsOf(payee);
    }

    function getFeesEarned() public view onlyOwner returns (uint256) {
        return _feesEarned;
    }

    /// @dev Override and disable this function
    function renounceOwnership() public view override onlyOwner {
        revert("Cannot renounce ownership");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
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
    ) internal override(ERC1155, ERC1155Supply) {
        ERC1155Supply._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        /// Last month for calculations, since fees are still flowing on monthCounter
        uint24 lastMonth = monthCounter - 1;

        /// If mint
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint24 id = uint24(ids[i]);
                _balanceOfLastMonth[id][to][lastMonth] = uint24(amounts[i]);
                _lastMonthIncDeposited[id][to] = lastMonth;
            }
        }
        /// If transfer or sale
        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint24 id = uint24(ids[i]);

                uint24 fromLastMonth = _lastMonthIncDeposited[id][from];
                bool shouldDeposit = (monthCounter - fromLastMonth) > 1 ? true : false;

                if (shouldDeposit) {
                    uint256 amount = 0;
                    for (uint24 m = fromLastMonth; m < monthCounter; ++m) {
                        amount +=
                            treasuryOfPlaylist[id][m] * _balanceOfLastMonth[id][from][fromLastMonth] / totalSupply(id);
                    }
                    _balanceOfLastMonth[id][from][fromLastMonth] = 0;
                    _escrow.deposit(amount, from);
                } else {
                    _balanceOfLastMonth[id][from][lastMonth] = 0;
                }
                delete _lastMonthIncDeposited[id][from];

                /// After all the calculations set the info of receiver (to)
                _balanceOfLastMonth[id][to][lastMonth] = uint24(amounts[i]);
                _lastMonthIncDeposited[id][to] = lastMonth;
            }
        }
    }
}
