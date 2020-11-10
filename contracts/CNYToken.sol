pragma solidity ^0.6.0;

import "./ERC1155/ERC1155.sol";
import "./Bill/BillManagerOwner.sol";
import "./Bill/BillCommon.sol";
import "./Bill/Bill.sol";
import "./Bill/Verifiable.sol";
import "./Common/MultiOwnable.sol";
import "./math/SafeMath.sol";
import "./Common/Pausable.sol";
import "./BillManager.sol";

contract CNYToken is ERC1155, MultiOwnable, Pausable, BillManagerOwner, Verifiable {
    using SafeMath for uint256;
    // id, receiver address list, receiver value list
    event Dispatch(uint256 id, address[] addrs, uint256[] values);
    // redeem to who, old bill ids, new bill ids, new bill values
    event Redeem(address _to, uint256[] oldIds, uint256[] newIds, uint256[] values);

    string public constant name = "IPI CNH";
    string public constant symbol = "CNHC";

    constructor(BillManager manager, string memory uri) ERC1155(uri) Verifiable(manager) Pausable(manager.ownersContract()) public {}

    ///
    // Override
    ///
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
    internal override
    {
        require(!paused, "CNYToken: token transfer while paused");
        // TODO if use _burn(), should check if "to" is address(0), then jump check
        verifyNormalIds(ids);
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    ///
    // self function
    ///
    function issue(uint256 _id, uint256 value) external onlyOwners checkNormalIds(_asSingletonArray(_id)) {
        BillManager billManager = BillManager(billManager);
        Bill bill = billManager.bills(_id);
        uint256 maxBillAmount = bill.billAmount();
        uint256 currentAmount = bill.totalAmount();
        uint256 nAmount = currentAmount.add(value);
        require(nAmount <= maxBillAmount, "CNYToken: bill amount overflow error");

        if(bill.claimed()){
            bill.addAmount(value);
            _mint(address(bill), _id, value, BillCommon.ISSUE_INTEREST);
        }else{
            bill.claim();
            bill.addAmount(value);
            _mint(address(bill), _id, value, BillCommon.ISSUE);
        }
    }

    function dispatch(uint256 _id, address[] calldata addrs, uint256[] calldata _values) external onlyOwners checkNormalIds(_asSingletonArray(_id)) {
        require(addrs.length == _values.length, "CNYToken: addrs and _values array length must match.");

        BillManager billManager = BillManager(billManager);
        address billAddr = address(billManager.bills(_id));

        for (uint256 i = 0; i < addrs.length; ++i) {
            uint256 value = _values[i];
            transfer(_id, billAddr, addrs[i], value, BillCommon.DISPATCH);
        }
        emit Dispatch(_id, addrs, _values);
    }

    function redeem(
        address _to,
        uint256[] calldata oldIds,
        uint256[] calldata newIds,
        uint256[] calldata _values
    ) external onlyOwners checkNormalIds(newIds) {
        // we only need newIds should be valid
        uint256 total_value = reduce(_values, addFunc);
        uint256 total = 0;
        uint256[] memory amounts = new uint256[](oldIds.length);
        for (uint256 i = 0; i < oldIds.length; ++i) {
            uint256 oldVal = _balances[oldIds[i]][_to];
            amounts[i] = oldVal;
            total += oldVal;
            // todo, may use _burn(), but _burn() would not do delete, and would log event
            // remove old bills
            delete _balances[oldIds[i]][_to];
        }
        require(total == total_value, "CNYToken: redeem value must match");

        // destroy callback
        address operator = _msgSender();
        _doSafeBatchTransferAcceptanceCheck(operator, _to, address(0), oldIds, amounts, BillCommon.REDEEM_DESTROY);

        // move redeem to a function due to "Stack too deep"
        dispatchForRedeem(_to, newIds, _values);
        emit Redeem(_to, oldIds, newIds, _values);
    }

    // private util functions
    function dispatchForRedeem(
        address _to,
        uint256[] memory newIds,
        uint256[] memory _values
    ) private {
        BillManager billManager = BillManager(billManager);
        for (uint256 i = 0; i < newIds.length; ++i) {
            address billAddr = address(billManager.bills(newIds[i]));
            uint256 value = _values[i];
            transfer(newIds[i], billAddr, _to, value, BillCommon.REDEEM_DISPATCH);
        }
    }

    function transfer(uint256 id, address from, address to, uint256 value, bytes memory data) internal {
        // SafeMath will throw with insuficient funds _from
        // or if _id is not valid (balance will be 0)
        _balances[id][from] = _balances[id][from].sub(value);
        _balances[id][to] = _balances[id][to].add(value);

        address operator = _msgSender();
        // todo do we need this event?
        // emit TransferSingle(operator, from, to, id, value);
        _doSafeTransferAcceptanceCheck(operator, from, to, id, value, data);
    }

    function addFunc(uint a, uint b) pure private returns (uint) {
        return a.add(b);
    }

    function reduce(uint[] memory a, function(uint, uint) pure returns (uint) f)
    internal
    pure
    returns (uint)
    {
        uint r = a[0];
        for (uint i = 1; i < a.length; i++) {
            r = f(r, a[i]);
        }
        return r;
    }
}