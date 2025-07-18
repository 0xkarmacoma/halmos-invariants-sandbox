// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Vat} from "src/Vat.sol";

// putting it all together: halmos v0.3.0 handles stateful testing natively, it can now just run `invariant_dai()`

// run with:
//   halmos --contract Example_4 --function invariant_dai

/// @custom:halmos --early-exit --invariant-depth 2
contract Example_4 is Test {
    Vat public vat;
    bytes32 ilk;

    function setUp() public {
        vat = new Vat();
        ilk = "gems";

        vat.init(ilk);
    }

    function invariant_dai() public view {
        assertEq(
            vat.debt(),
            vat.vice() + vat.Art(ilk) * vat.rate(ilk),
            "The Fundamental Equation of DAI"
        );
    }
}
