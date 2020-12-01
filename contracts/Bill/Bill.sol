/**
 * SPDX-License-Identifier: LGPL
 *
 * Copyright (c) Invest & Pay International(Singapore) Pte. Ltd., 2020-2022
 *
 */
pragma solidity ^0.6.0;

import "../Common/MultiOwnable.sol";
import "../Common/Owners.sol";
import "../math/SafeMath.sol";
import "../ERC1155/ERC1155Receiver.sol";

/// @title Bill
/// @author Juu17
contract Bill is MultiOwnable, ERC1155Receiver {
    using SafeMath for uint256;

    uint256 public immutable id;
    uint256 public immutable billAmount;
    uint256 public issuedAmount;
    string public drawer;
    string public draweeBankName;
    bytes8 public immutable draweeDate;
    string public accepter;
    string public accepterBankName;
    bytes8 public immutable expireDate;

    uint256 public initialIssueTime;

    address public immutable managerAddress;

    constructor(
        Owners owners,
        uint256 _id,
        uint256 _billAmount,
        string memory _drawer,
        string memory _draweeBankName,
        string memory _accepter,
        string memory _accepterBankName,
        bytes8 _draweeDate,
        bytes8 _expireDate
    ) public MultiOwnable(owners) {
        id = _id;
        billAmount = _billAmount;
        // issuedAmount is set to 0
        issuedAmount = 0;
        drawer = _drawer;
        draweeBankName = _draweeBankName;
        accepter = _accepter;
        accepterBankName = _accepterBankName;
        draweeDate = _draweeDate;
        expireDate = _expireDate;

        managerAddress = msg.sender;
    }

    /// @notice Only allowed to the BillManager who created me
    function addIssueAmount(uint256 _amount) external returns (bool isInitialIssue) {
        require(msg.sender == managerAddress, "[CNHC] Manager required");

        uint256 newIssueAmount = issuedAmount.add(_amount);
        require(newIssueAmount <= billAmount, "[CNHC] Bill amount overflow warning");

        if (issuedAmount == 0) {
            initialIssueTime = now;
            isInitialIssue = true;
        }
        issuedAmount = newIssueAmount;
    }

    /// @notice Exposed for callers to judge the status of the bill
    function isClaimed() external view returns (bool) {
        return initialIssueTime != 0;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
