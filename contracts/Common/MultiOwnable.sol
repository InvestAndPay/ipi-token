/**
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2018 zOS Global Limited.
 * Copyright (c) CENTRE SECZ 2018-2020
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

import "./Owners.sol";

/**
 * @notice The Ownable contract has an owner address, and provides basic
 * authorization control functions
 * @dev Forked from https://github.com/OpenZeppelin/openzeppelin-labs/blob/3887ab77b8adafba4a26ace002f3a684c1a3388b/upgradeability_ownership/contracts/ownership/Ownable.sol
 * Modifications:
 * 1. Consolidate OwnableStorage into this contract (7/13/18)
 * 2. Reformat, conform to Solidity 0.6 syntax, and add error messages (5/13/20)
 * 3. Make public functions external (5/27/20)
 */
contract MultiOwnable {
    Owners public ownersContract;

    /**
     * @dev The constructor sets the original owner of the contract to the sender account.
     */
    constructor(Owners _owners) public {
        ownersContract = _owners;
    }

    // Deprecated
    // function setOwnersContract(Owners _owners) external onlyOwners {
    //     ownersContract = _owners;
    // }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    // modifier onlyMainOwner() {
    //     require(
    //         tx.origin == ownersContract.mainOwner(),
    //         "MultiOwnable: caller is not the main owner");
    //     _;
    // }

    /**
     * @dev Throws if called by any account other than the main owner or other owners.
     */
    modifier onlyOwners() {
        require(tx.origin == ownersContract.mainOwner() || ownersContract.isOwner(tx.origin), "MultiOwnable: caller is not the owner members");
        _;
    }

    //    modifier onlyOwnersIncludeOrigin() {
    //        if (tx.origin == msg.sender) {
    //            require(
    //                msg.sender == _mainOwner || msg.sender == _contractOwner || owners[msg.sender],
    //                "MultiOwnable: caller is not the owner members"
    //            );
    //        } else {
    //            require(
    //                tx.origin == _mainOwner || msg.sender == _mainOwner
    //                || tx.origin == _contractOwner || msg.sender == _contractOwner
    //                || owners[tx.origin] || owners[msg.sender],
    //                "MultiOwnable: caller is not the owner members"
    //            );
    //        }
    //        _;
    //    }
}
