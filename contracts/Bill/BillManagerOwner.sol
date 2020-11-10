pragma solidity ^0.6.0;

import "../BillManager.sol";

contract BillManagerOwner {
    BillManager public billManager;
    constructor(BillManager _billManager) public {
        setBillManager(_billManager);
    }
    function setBillManager(BillManager _billManager) internal {
        billManager = _billManager;
    }
}
