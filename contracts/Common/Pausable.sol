/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2016 Smart Contract Solutions, Inc.
 * Copyright (c) CENTRE SECZ 2018-20200
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

pragma solidity ^0.6.0;

import {MultiOwnable} from "./MultiOwnable.sol";
import {Owners} from "./Owners.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is MultiOwnable {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address indexed account, string text);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address indexed account);

    event PauserChanged(address indexed newAddress);

    address public pauser;
    bool private _paused;
    string private _pauseText;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor(Owners owner) public MultiOwnable(owner) {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool) {
        return _paused;
    }

    function pauseText() external view returns (string memory) {
        return _pauseText;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "[CNHC] System paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "[CNHC] System not paused");
        _;
    }

    /**
     * @dev throws if called by any account other than the pauser
     */
    modifier onlyPauser() {
        require(msg.sender == pauser, "[CNHC] Caller is not the pauser");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause(string memory text) public onlyPauser whenNotPaused {
        _paused = true;
        _pauseText = text;
        emit Paused(msg.sender, _pauseText);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        _pauseText = "";
        emit Unpaused(msg.sender);
    }

    /**
     * @dev update the pauser role
     */
    function updatePauser(address _newPauser) external onlyOwners {
        require(_newPauser != address(0), "[CNHC] New pauser is the zero address");
        pauser = _newPauser;
        emit PauserChanged(pauser);
    }
}
