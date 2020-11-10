pragma solidity ^0.6.0;

import "../Common/MultiOwnable.sol";
import "../Common/Owners.sol";
import "../math/SafeMath.sol";
import "../ERC1155/ERC1155Receiver.sol";

contract Bill is MultiOwnable, ERC1155Receiver {
    using SafeMath for uint256;

    uint256 public id;
    uint256 public billAmount;
    uint256 public totalAmount;
    string public drawer;
    string public draweeBankName;
    bytes8 public draweeDate;
    string public accepter;
    string public accepterBankName;
    bytes8 public expireDate;

    bool public claimed;
    uint256[] childrenIds;

    event AddAmount(address operator, uint256 value);

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
    ) MultiOwnable(owners) public {
        id = _id;
        billAmount = _billAmount;
        // totalAmount is set to 0
        totalAmount = 0;
        drawer = _drawer;
        draweeBankName = _draweeBankName;
        accepter = _accepter;
        accepterBankName = _accepterBankName;

        draweeDate = _draweeDate;
        expireDate = _expireDate;

        claimed = false;
    }

    function claim() external onlyOwners {
        claimed = true;
    }

    function addAmount(uint256 value) external onlyOwners {
        require(claimed, "Bill: just claimed bill could add amount");
        uint256 oldAmount = totalAmount;
        totalAmount = oldAmount.add(value);
        emit AddAmount(tx.origin, value);
    }

    function isClaimed() external view returns (bool) {
        return claimed;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
