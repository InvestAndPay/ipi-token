/**
 * SPDX-License-Identifier: LGPL
 *
 * Copyright (c) Invest & Pay International(Singapore) Pte. Ltd., 2020-2022
 *
 */
pragma solidity ^0.6.0;

import "./ERC1155/ERC1155.sol";
import "./Bill/BillCommon.sol";
import "./Common/MultiOwnable.sol";
import "./math/SafeMath.sol";
import "./Common/Pausable.sol";
import "./BillManager.sol";

/// @title IPIToken
/// @author Juu17
contract IPIToken is ERC1155, MultiOwnable, Pausable {
    using SafeMath for uint256;

    event Issue(uint256 indexed id, uint256 indexed amount);
    event IssueInterest(uint256 indexed id, uint256 indexed amount);
    event Dispatch(uint256 indexed id, address[] indexed addrs, uint256[] amounts);
    event Redeem(address indexed _to, uint256[] indexed oldIds, uint256[] newIds, uint256[] amounts);
    event Deprecate(address newAddress);

    string public constant name = "IPI CNH";
    string public constant symbol = "CNHC";
    uint8 public constant decimals = 2;
    address public upgradedAddress;
    bool public deprecated;

    BillManager private billManager;

    constructor(BillManager manager, string memory uri) public ERC1155(uri) Pausable(manager.ownersContract()) {
        billManager = manager;
    }

    function setBillManager(BillManager _billManager) external onlyOwners {
        billManager = _billManager;
    }

    /// Override Section Begin
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused checkNormalIds(ids) {
        // TODO if use _burn(), should check if "to" is address(0), then jump check
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /// Override Section End

    /// @notice Issue tokens within specified Bill id
    function issue(uint256 _id, uint256 amount) external onlyOwners checkNormalIds(_asSingletonArray(_id)) {
        bool isInitialIssue;
        address billAddr;
        (isInitialIssue, billAddr) = billManager.tryAddBillIssueAmount(_id, amount);

        if (isInitialIssue) {
            _mint(billAddr, _id, amount, BillCommon.ISSUE);
            emit Issue(_id, amount);
        } else {
            _mint(billAddr, _id, amount, BillCommon.ISSUE_INTEREST);
            emit IssueInterest(_id, amount);
        }
    }

    /// @notice Dispatch tokens from one Bill contract to some accounts
    function dispatch(
        uint256 _id,
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external onlyOwners checkNormalIds(_asSingletonArray(_id)) {
        require(accounts.length == amounts.length, "[CNHC] Parameters (accounts) and (amounts) must be the same length");
        address billAddr = address(billManager.bills(_id));

        for (uint256 i = 0; i < accounts.length; ++i) {
            __transfer(_id, billAddr, accounts[i], amounts[i], BillCommon.DISPATCH);
        }
        emit Dispatch(_id, accounts, amounts);
    }

    /// @notice Redeem the tokens binded to expired Bills, Recall the old tokens and dispatch new tokens
    function redeem(
        address account,
        uint256[] calldata oldIds,
        uint256[] calldata newIds,
        uint256[] calldata newAmounts
    ) external onlyOwners checkNormalIds(newIds) {
        // Phrase 1
        uint256 totalOldBalance;
        uint256[] memory oldBalanceArray;
        (totalOldBalance, oldBalanceArray) = _gatherForRedeem(account, oldIds);
        uint256 totalNewAmount = reduce(newAmounts, addFunc);
        require(totalOldBalance == totalNewAmount, "[CNHC] Redeem amount must match");
        // Phrase 2
        for (uint256 i = 0; i < oldIds.length; ++i) {
            delete _balances[oldIds[i]][account];
        }
        // destroy callback
        address operator = _msgSender();
        _doSafeBatchTransferAcceptanceCheck(operator, account, address(0), oldIds, oldBalanceArray, BillCommon.REDEEM_DESTROY);
        // Phrase 3
        _dispatchForRedeem(account, newIds, newAmounts);
        emit Redeem(account, oldIds, newIds, newAmounts);
    }

    /// @notice Private function for redeem
    function _gatherForRedeem(address account, uint256[] calldata oldIds) private view returns (uint256 totalOldBalance, uint256[] memory oldBalanceArray) {
        oldBalanceArray = new uint256[](oldIds.length);
        for (uint256 i = 0; i < oldIds.length; ++i) {
            uint256 oldVal = _balances[oldIds[i]][account];
            oldBalanceArray[i] = oldVal;
            totalOldBalance = totalOldBalance.add(oldVal);
        }
    }

    /// @notice Private function for redeem
    function _dispatchForRedeem(
        address account,
        uint256[] memory newIds,
        uint256[] memory newAmounts
    ) private {
        for (uint256 i = 0; i < newIds.length; ++i) {
            address billAddr = address(billManager.bills(newIds[i]));
            uint256 amount = newAmounts[i];
            __transfer(newIds[i], billAddr, account, amount, BillCommon.REDEEM_DISPATCH);
        }
    }

    /// @dev Private transfer for single address to single address
    function __transfer(
        uint256 id,
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) internal {
        // SafeMath will throw with insuficient funds _from or if _id is not valid (balance will be 0)
        _balances[id][from] = _balances[id][from].sub(amount, "[CNHC] Insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        address operator = _msgSender();
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /// @notice Deprecate current contract in favour of a new one
    function deprecate(address _upgradedAddress) external onlyOwners {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    modifier checkNormalIds(uint256[] memory _ids) {
        require(billManager.verifyIds(_ids, BillCommon.BillState.Normal), "[CNHC] Invalid bill id found");
        _;
    }

    function addFunc(uint256 a, uint256 b) private pure returns (uint256) {
        return a.add(b);
    }

    function reduce(uint256[] memory a, function(uint256, uint256) pure returns (uint256) f) internal pure returns (uint256) {
        uint256 r = a[0];
        for (uint256 i = 1; i < a.length; i++) {
            r = f(r, a[i]);
        }
        return r;
    }
}
