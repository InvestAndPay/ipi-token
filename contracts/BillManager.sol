pragma solidity ^0.6.0;

import {MultiOwnable} from "./Common/MultiOwnable.sol";
import "./Common/Owners.sol";
import "./Bill/BillCommon.sol";
import "./Bill/Bill.sol";

contract BillManager is MultiOwnable {
    mapping(uint256 => Bill) public bills;
    mapping(uint256 => BillCommon.BillState) public billStates;

    constructor(Owners _owners) MultiOwnable(_owners) public {}

    event CreateBill(uint256 id, Bill bill);
    event DiscardBill(uint256 id);
    event DiscardBills(uint256[] ids);

    modifier onlyExistedId(uint256 _id) {
        require(address(bills[_id]) != address(0), "BillManager: id must be existed");
        _;
    }
    modifier onlyExistedIds(uint256[] memory _ids) {
        for (uint256 i = 0; i < _ids.length; ++i) {
            require(address(bills[_ids[i]]) != address(0), "BillManager: all ids must be existed");
        }
        _;
    }

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
        require(address(bills[_id]) == address(0), "BillManager: id must not exist");

        // msg.sender would be the owner of Bill
        Bill addr = newBill(
            _id,
            _billAmount,
            _drawer,
            _draweeBankName,
            _accepter,
            _accepterBankName,
            _draweeDate,
            _expireDate
        );
        emit CreateBill(_id, addr);

        return addr;
    }

    function discardBill(uint256 _id) external onlyOwners onlyExistedId(_id) {
        billStates[_id] = BillCommon.BillState.Discarded;
        emit DiscardBill(_id);
    }

    function discardBills(uint256[] calldata _ids) external onlyOwners onlyExistedIds(_ids) {
        for (uint256 i = 0; i < _ids.length; ++i) {
            billStates[_ids[i]] = BillCommon.BillState.Discarded;
        }
        emit DiscardBills(_ids);
    }

    // this `force*` function just use for repair contract state, or use for contract update migration
    function forceSetBills(uint256[] calldata _ids, Bill[] calldata _bills, BillCommon.BillState[] calldata _states) external onlyOwners {
        require(_ids.length == _bills.length, "BillManager: params length must match");
        require(_bills.length == _states.length, "BillManager: params length must match");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            bills[id] = _bills[i];
            billStates[id] = _states[i];
        }
    }

    function verifyIds(uint256[] calldata _ids, BillCommon.BillState expectedState) external view returns (bool) {
        for (uint256 i = 0; i < _ids.length; ++i) {
            if (billStates[_ids[i]] != expectedState) {
                return false;
            }
        }
        return true;
    }

    // private inner function
    function newBill(
        uint256 _id,
        uint256 _billAmount,
        string memory _drawer,
        string memory _draweeBankName,
        string memory _accepter,
        string memory _accepterBankName,
        bytes8 _draweeDate,
        bytes8 _expireDate
    ) private returns (Bill) {
        Bill bill = new Bill(
            ownersContract,
            _id,
            _billAmount,
            _drawer,
            _draweeBankName,
            _accepter,
            _accepterBankName,
            _draweeDate,
            _expireDate
        );

        bills[_id] = bill;
        billStates[_id] = BillCommon.BillState.Normal;
        return bill;
    }

}