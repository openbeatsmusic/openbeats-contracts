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
import {ReentrancyGuardUpgradeable} from
    "openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./libraries/TransferHelper.sol";
import {Escrow} from "./Escrow.sol";

contract Playlist is
    ERC1155Upgradeable,
    ERC1155SupplyUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    /// NFT id => monthCounter =>  treasuryOfPlaylist
    mapping(uint256 => mapping(uint256 => uint256)) public treasuryOfPlaylist;

    /// _lastMonthIncDeposited refers to the last month in which the account deposited earnings
    /// NFT id => Address => _lastMonthIncDeposited
    mapping(uint256 => mapping(address => uint256)) private _lastMonthIncDeposited;

    /// Balance of month refers to the token balance that the account had that month
    /// NFT id => Address => firstNoDepositedMonth => _balanceOfMonth
    mapping(uint256 => mapping(address => mapping(uint256 => uint256))) private _balanceOfMonth;

    address public currency;
    bool public paused;
    uint256 public monthCounter;
    bytes32 public immutable name = "OpenBeats";
    bytes32 public immutable symbol = "OB";

    Escrow private _escrow;
    /// Id of next minted nft
    uint256 private _nextId;
    uint256 private _timestamp;

    /// @notice Not a treasury event yet since we have that info in the backend
    event EarningsDeposited(uint256 indexed id, address indexed account, uint256 weiAmount);

    /// @dev Avoid leaving a contract uninitialized => An uninitialized contract can be taken over by an attacker
    constructor() {
        _disableInitializers();
    }

    /// @dev Initialize sets first version of the contract, later versions should use reinitializer
    /// @dev Royalties are sent to owner of the contract, 5% royalties set
    function initialize(address currency_) external initializer {
        currency = currency_;
        /// MonthCounter should always be >= 2
        monthCounter = 2;
        paused = false;
        _escrow = new Escrow(currency_);
        _nextId = 0;
        _timestamp = block.timestamp;
        __ERC1155_init("https://api.openbeats.xyz/openbeats/v1/playlist/metadata/{id}");
        __ERC1155Supply_init();
        __ERC2981_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        _setDefaultRoyalty(super.owner(), 500);
    }

    function depositEarnings(uint256[] calldata ids) public nonReentrant {
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            _depositEarnings(_msgSender(), id);
        }
    }

    function mint(uint256 id, uint256 supply) public {
        require(id == _nextId, "Wrong id");
        _nextId += 1;
        super._mint(_msgSender(), id, supply, "");
    }

    function payFirstPlan(address from) public onlyOwner {
        require(!paused, "Contract paused");
        uint256 plan = 4 * 1e18;

        uint256 timestampDiff = block.timestamp - _timestamp;
        if (timestampDiff >= 30 days) {
            unchecked {
                monthCounter += 1;
            }
            _timestamp = block.timestamp;
        }

        TransferHelper.safeTransferFrom(currency, from, super.owner(), plan);
    }

    function payPlan(address from, uint256[] calldata ids, uint256[] calldata amounts) public onlyOwner {
        require(!paused, "Contract paused");
        require(ids.length == amounts.length, "Array mismatch");
        require(ids.length <= 30, "Exceeded length");

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

        uint256 _monthCounter = monthCounter;
        unchecked {
            for (uint256 i = 0; i < ids.length; i++) {
                uint256 id = ids[i];
                /// Cannot overflow because the sum of all playlist balances can't exceed the max uint256 value.
                treasuryOfPlaylist[id][_monthCounter] += amounts[i];
            }
        }
        // We send the funds directly to the escrow
        TransferHelper.safeTransferFrom(currency, from, address(_escrow), _maxAmount);
        TransferHelper.safeTransferFrom(currency, from, super.owner(), plan - _maxAmount);
    }

    function withdraw() public nonReentrant {
        require(!paused, "Contract paused");
        _escrow.withdraw(_msgSender());
    }

    /// @dev Pauses the contract transfers and mints
    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    /// @dev Returns the payments owed to an address.
    /// @param payee The creditor's address.
    function depositsOf(address payee) public view returns (uint256) {
        return _escrow.depositsOf(payee);
    }

    /// Earnings since last deposit of earnings
    function earningsOf(address account, uint256 id) public view returns (uint256) {
        uint256 lastMonthIncDeposited = _lastMonthIncDeposited[id][account];
        uint256 newMonthNoDeposit = lastMonthIncDeposited + 1;
        bool shouldDeposit = (monthCounter - lastMonthIncDeposited) > 1 ? true : false;
        /// If nothing is found then _lastMonthIncDeposited[id][account] is 0
        if (lastMonthIncDeposited == 0 || !shouldDeposit) {
            return 0;
        }
        uint256 earnings = 0;
        for (uint256 m = newMonthNoDeposit; m < monthCounter; ++m) {
            earnings +=
                treasuryOfPlaylist[id][m] * _balanceOfMonth[id][account][lastMonthIncDeposited] / totalSupply(id);
        }
        return earnings;
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
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) nonReentrant {
        /// Contract paused for mints and transfers
        require(!paused, "Contract paused");
        ERC1155SupplyUpgradeable._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        /// Last month for calculations, since fees are still flowing on monthCounter
        uint256 lastMonth = monthCounter - 1;

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];

            /// If transfer
            if (from != address(0)) {
                _depositEarnings(from, id);

                /// We delete this mapping and set _balanceOfMonth as 0 so _balanceOfMonth can never be accessed after
                /// the transfer since it needs _lastMonthIncDeposited to be accessed
                delete _lastMonthIncDeposited[id][from];
                delete _balanceOfMonth[id][from][lastMonth];
            }

            /// After all the calculations set the info of receiver (to). Could be a mint or transfer.
            _balanceOfMonth[id][to][lastMonth] = amounts[i];
            _lastMonthIncDeposited[id][to] = lastMonth;
        }
    }

    function _depositEarnings(address account, uint256 id) private {
        require(!paused, "Contract paused");
        /// Last month for calculations, since fees are still flowing on monthCounter
        uint256 lastMonth = monthCounter - 1;
        uint256 earnings = earningsOf(account, id);
        uint256 lastMonthIncDeposited = _lastMonthIncDeposited[id][account];

        if (earnings > 0) {
            /// Setting lastMonthIncDeposited if deposit is called. No reentrancy here since with current monthCounter
            /// not possible to get earnings, this will be deleted if transfer
            _balanceOfMonth[id][account][lastMonth] = _balanceOfMonth[id][account][lastMonthIncDeposited];
            delete _balanceOfMonth[id][account][lastMonthIncDeposited];
            /// Set last month of deposit, this would be deleted afterwards if it comes from a transferFrom so no gas
            /// penalization
            _lastMonthIncDeposited[id][account] = monthCounter - 1;
            _escrow.deposit(earnings, account);

            emit EarningsDeposited(id, account, earnings);
        }
    }
}
