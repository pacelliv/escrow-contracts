// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library EscrowTypes {
    enum State {
        CREATED,
        CONFIRMED,
        DISPUTED,
        RESOLVED
    }
}
