/**
 * SPDX-License-Identifier: LGPL
 *
 * Copyright (c) Invest & Pay International(Singapore) Pte. Ltd., 2020-2022
 *
 */
pragma solidity ^0.6.0;

library BillCommon {
    enum BillState {Invalid, Normal, Discarded}

    bytes constant ISSUE = "I";
    bytes constant ISSUE_INTEREST = "I|I";
    bytes constant DISPATCH = "D";
    bytes constant REDEEM_DESTROY = "R|D";
    bytes constant REDEEM_DISPATCH = "R|DI";
}
