pragma solidity ^0.6.0;

import {BillManagerOwner} from "./BillManagerOwner.sol";
import {BillManager} from "../BillManager.sol";
import "./BillCommon.sol";

contract Verifiable is BillManagerOwner {
    constructor(BillManager _billManager) BillManagerOwner(_billManager) public {}
    function verifyNormalIds(uint256[] memory _ids) public view {
        require(billManager.verifyIds(_ids, BillCommon.BillState.Normal), "Verifiable: ids contains invalid bill id, need normal ids");
    }

    function verifyDiscardedIds(uint256[] memory _ids) public view {
        require(billManager.verifyIds(_ids, BillCommon.BillState.Discarded), "Verifiable: ids contains invalid bill id, need expired ids");
    }

    modifier checkNormalIds(uint256[] memory _ids) {
        verifyNormalIds(_ids);
        _;
    }

    modifier checkDiscardedIds(uint256[] memory _ids) {
        verifyDiscardedIds(_ids);
        _;
    }
}
