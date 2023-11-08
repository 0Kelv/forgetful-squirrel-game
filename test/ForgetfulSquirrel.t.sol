// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {ForgetfulSquirrel} from "../src/ForgetfulSquirrel.sol";

contract ForgetfulSquirrelTest is Test {
    ForgetfulSquirrel public squirrel;

    function setUp() public {
        squirrel = new ForgetfulSquirrel();
    }

    function test_GetRandomBooleanArray() public view {        
        uint256 size = 16;
        bool[] memory randomBooleans = squirrel.getRandomBooleanArray(size);
        for (uint256 i = 0; i < size; i++) {
            console2.logBool(randomBooleans[i]);
        }
    }
}
