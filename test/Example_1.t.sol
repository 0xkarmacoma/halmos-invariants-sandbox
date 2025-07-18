// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {Vat} from "src/Vat.sol";

// this one targets the full Vat contract, not just the MiniVat contract
// it also uses the new svm.createCalldata(address) cheatcode

// run with:
//   halmos --contract Example_1 --function check_vat_createCalldata

/// @custom:halmos --early-exit
contract Example_1 is Test, SymTest {
    Vat public vat;
    bytes32 public ilk = "gems";

    function setUp() public {
        vat = new Vat();
        vat.init(ilk);
    }

    function check_vat_createCalldata() public {
        uint256 depth = vm.envOr("INVARIANT_DEPTH", uint256(2));
        console.log("generating call sequences with depth", depth);

        for (uint256 i = 0; i < depth; ++i) {
            assumeSuccessfulCall(
                address(vat),
                svm.createCalldata(address(vat))  // using the new cheatcode
            );
        }

        assertEq(
            vat.debt(),
            vat.vice() + vat.Art(ilk) * vat.rate(ilk),
            "The Fundamental Equation of DAI"
        );
    }

    function assumeSuccessfulCall(address target, bytes memory data) public {
        (bool success, ) = target.call(data);
        vm.assume(success);
    }
}
