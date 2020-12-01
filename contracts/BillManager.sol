/**
 * SPDX-License-Identifier: LGPL
 *
 * Copyright (c) Invest & Pay International(Singapore) Pte. Ltd., 2020-2022
 *
 */
pragma solidity ^0.6.0;

import {MultiOwnable} from "./Common/MultiOwnable.sol";
import "./Common/Owners.sol";
import "./Bill/BillCommon.sol";
import "./Bill/Bill.sol";

/// @title BillManager
/// @author Juu17
contract BillManager is MultiOwnable {
    mapping(uint256 => Bill) public bills;
    mapping(uint256 => BillCommon.BillState) public billStates;

    constructor(Owners _owners) public MultiOwnable(_owners) {}

    event CreateBill(uint256 indexed id, Bill indexed bill);
    event DiscardBill(uint256 indexed id);
    event DiscardBills(uint256[] indexed ids);

    modifier onlyExistedId(uint256 _id) {
        require(address(bills[_id]) != address(0), "[BM] Bill id not found");
        _;
    }
    modifier onlyExistedIds(uint256[] memory _ids) {
        for (uint256 i = 0; i < _ids.length; ++i) {
            require(address(bills[_ids[i]]) != address(0), "[BM] Some bill ids not found");
        }
        _;
    }

    /// @notice Create a new Bill contract object and deploy
    function createBill(
        uint256 _id,
        uint256 _billAmount,
        string memory _drawer,
        string memory _draweeBankName,
        string memory _accepter,
        string memory _accepterBankName,
        bytes8 _draweeDate,
        bytes8 _expireDate
    ) external onlyOwners returns (Bill) {
        require(address(bills[_id]) == address(0), "[BM] Bill id already exist");

        Bill bill = new Bill(ownersContract, _id, _billAmount, _drawer, _draweeBankName, _accepter, _accepterBankName, _draweeDate, _expireDate);
        bills[_id] = bill;
        billStates[_id] = BillCommon.BillState.Normal;
        emit CreateBill(_id, bill);

        return bill;
    }

    function tryAddBillIssueAmount(uint256 _id, uint256 _amount) external onlyOwners returns (bool isInitialIssue, address billAddr) {
        Bill bill = bills[_id];
        require(address(bill) != address(0), "[BM] Bill id not found");
        isInitialIssue = bill.addIssueAmount(_amount);
        billAddr = address(bill);
    }

    /// @notice Discard a single Bill contract, set the status to Discarded
    function discardBill(uint256 _id) external onlyOwners onlyExistedId(_id) {
        billStates[_id] = BillCommon.BillState.Discarded;
        emit DiscardBill(_id);
    }

    /// @notice Discard a bunch of Bill contracts, set the statuses to Discarded
    function discardBills(uint256[] calldata _ids) external onlyOwners onlyExistedIds(_ids) {
        for (uint256 i = 0; i < _ids.length; ++i) {
            billStates[_ids[i]] = BillCommon.BillState.Discarded;
        }
        emit DiscardBills(_ids);
    }

    function uploadBills(
        uint256[] calldata _ids,
        Bill[] calldata _bills,
        BillCommon.BillState[] calldata _states
    ) external onlyOwners {
        require(_ids.length == _bills.length, "[BM] Parameters (_ids) and (_bills) must be the same length");
        require(_bills.length == _states.length, "[BM] Parameters (_bills) and (_states) must be the same length");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            bills[id] = _bills[i];
            billStates[id] = _states[i];
        }
    }

    /// @notice Inspect the statues of specified bills
    function verifyIds(uint256[] calldata _ids, BillCommon.BillState expectedState) external view returns (bool) {
        require(_ids.length < 30, "[BM] Parameter (_ids) size too large");
        for (uint256 i = 0; i < _ids.length; ++i) {
            if (billStates[_ids[i]] != expectedState) {
                return false;
            }
        }
        return true;
    }
}
