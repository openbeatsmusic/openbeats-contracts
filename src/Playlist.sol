// solhint-disable not-rely-on-time
/// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ERC1155Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/ERC1155/ERC1155Upgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {ERC1155SupplyUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
/// No need to resetRoyalty in burn since playlist has no burn implemented
import {ERC2981Upgradeable} from "openzeppelin-contracts-upgradeable/contracts/token/common/ERC2981Upgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./libraries/TransferHelper.sol";
import {Escrow} from "./Escrow.sol";

contract Playlist is
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    /// NFT id => monthCounter =>  treasuryOfPlaylist
    mapping(uint256 => mapping(uint256 => uint256)) public treasuryOfPlaylist;

    /// NFT id => Address => _lastMonthIncDeposited
    mapping(uint256 => mapping(address => uint256)) private _lastMonthIncDeposited;
    /// NFT id => Address => firstNoDepositedMonth => _balanceOfLastMonth
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) private _balanceOfLastMonth;

    address public currency;
    bool public paused;
    uint256 public monthCounter;
    bytes32 public immutable name = "OpenBeats";
    bytes32 public immutable symbol = "OB";

    Escrow private _escrow;
    uint96 private _feesEarned;
    /// Id of next minted nft
    uint256 private _nextId;
    uint256 private _timestamp;

    /// @dev Avoid leaving a contract uninitialized => An uninitialized contract can be taken over by an attacker
    constructor() {
        _disableInitializers();
    }

    /// @dev Initialize sets first version of the contract, later versions should use reinitializer
    /// @dev Royalties are sent to owner of the contract, 5% royalties set
    function initialize(address currency_) external initializer {
        currency = currency_;
        monthCounter = 1;
        paused = false;
        _escrow = new Escrow(currency_);
        _nextId = 0;
        _timestamp = block.timestamp;
        __ERC1155_init("https://api.openbeats.xyz/openbeats/v1/playlist/metadata/{id}");
        __ERC1155Supply_init();
        __ERC2981_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        _setDefaultRoyalty(super.owner(), 500);
    }

    function mint(uint256 id, uint256 supply) public {
        require(id == _nextId, "Wrong id");
        _nextId += 1;
        super._mint(_msgSender(), id, supply, "");
    }

    function payFirstPlan(address from) public onlyOwner {
        uint96 fee = 4 * 1e18;
        uint256 plan = 4 * 1e18;

        uint256 timestampDiff = block.timestamp - _timestamp;
        if (timestampDiff >= 30 days) {
            unchecked {
                monthCounter += 1;
            }
            _timestamp = block.timestamp;
        }

        unchecked {
            _feesEarned += fee;
        }

        TransferHelper.safeTransferFrom(currency, from, address(this), plan);
    }

    function payPlan(address from, uint256[] calldata ids, uint256[] calldata amounts) public onlyOwner {
        require(ids.length == amounts.length, "Array mismatch");
        require(ids.length <= 30, "Exceeded length");

        uint96 fee = 1 * 1e18;
        uint256 plan = 4 * 1e18;
        uint256 maxAmount = 3 * 1e18;
        uint256 _maxAmount;
        unchecked {
            for (uint256 i = 0; i < amounts.length; i++) {
                _maxAmount += amounts[i];
            }
        }
        require(_maxAmount <= maxAmount, "MaxAmount");

        uint256 timestampDiff = block.timestamp - _timestamp;
        if (timestampDiff >= 30 days) {
            unchecked {
                monthCounter += 1;
            }
            _timestamp = block.timestamp;
        }

        unchecked {
            _feesEarned += fee;
        }
        uint256 _monthCounter = monthCounter;
        unchecked {
            for (uint256 i = 0; i < ids.length; i++) {
                uint256 id = ids[i];
                /// Cannot overflow because the sum of all playlist balances can't exceed the max uint256 value.
                treasuryOfPlaylist[id][_monthCounter] += amounts[i];
            }
        }
        TransferHelper.safeTransferFrom(currency, from, address(this), plan);
    }

    /// @dev Pauses the contract transfers, sales and mints
    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    /// @dev Returns the payments owed to an address.
    /// @param payee The creditor's address.
    function depositsOf(address payee) public view returns (uint256) {
        return _escrow.depositsOf(payee);
    }

    function getFeesEarned() public view onlyOwner returns (uint256) {
        return _feesEarned;
    }

    /// @dev Returns the highest version that has been initialized. See {reinitializer}.
    function getInitializedVersion() public view returns (uint8) {
        return Initializable._getInitializedVersion();
    }

    /// @dev Override and disable this function
    function renounceOwnership() public view override onlyOwner {
        revert("Cannot renounce ownership");
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /// @dev Function to determine who is allowed to upgrade this contract.
    /// @param _newImplementation: unused in access check
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        require(!paused, "Token transfers paused");
        ERC1155SupplyUpgradeable._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        /// Last month for calculations, since fees are still flowing on monthCounter
        uint256 lastMonth = monthCounter - 1;

        /// If mint
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                _balanceOfLastMonth[id][to][lastMonth] = amounts[i];
                _lastMonthIncDeposited[id][to] = lastMonth;
            }
        }
        /// If transfer or sale
        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];

                uint256 fromLastMonth = _lastMonthIncDeposited[id][from];
                bool shouldDeposit = (monthCounter - fromLastMonth) > 1 ? true : false;

                if (shouldDeposit) {
                    uint256 amount = 0;
                    for (uint256 m = fromLastMonth; m < monthCounter; ++m) {
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
                _balanceOfLastMonth[id][to][lastMonth] = amounts[i];
                _lastMonthIncDeposited[id][to] = lastMonth;
            }
        }
    }
}
