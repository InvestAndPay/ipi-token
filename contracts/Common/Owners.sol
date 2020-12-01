pragma solidity ^0.6.0;

contract Owners {
    // Owner of the contract
    address private _mainOwner;
    mapping(address => bool) private _owners;
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event AddNewOwner(address indexed newOwner);

    event RemoveOwner(address indexed owner);

    modifier onlyMainOwner() {
        require(msg.sender == _mainOwner, "[OWN] Caller is not the main owner");
        _;
    }

    constructor() public {
        setMainOwner(msg.sender);
    }

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function mainOwner() external view returns (address) {
        return _mainOwner;
    }

    function isOwner(address who) external view returns (bool) {
        return who == _mainOwner || _owners[who];
    }

    /**
     * @dev Sets a new owner address
     */
    function setMainOwner(address newOwner) private {
        _mainOwner = newOwner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferMainOwnership(address newOwner) external onlyMainOwner {
        require(newOwner != address(0), "[OWN] New owner is the zero address");
        emit OwnershipTransferred(_mainOwner, newOwner);
        setMainOwner(newOwner);
    }

    function addOwner(address owner) external onlyMainOwner {
        require(owner != address(0), "[OWN] New owner is the zero address");
        _owners[owner] = true;

        emit AddNewOwner(owner);
    }

    function removeOwner(address owner) external onlyMainOwner {
        require(owner != address(0), "[OWN] New owner is the zero address");
        require(_owners[owner], "[OWN] Owner is not existed");

        delete _owners[owner];

        emit RemoveOwner(owner);
    }
}
