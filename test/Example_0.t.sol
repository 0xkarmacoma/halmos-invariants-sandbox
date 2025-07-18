// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {MiniVat} from "src/MiniVat.sol";

// adapted from https://github.com/aviggiano/property-based-testing-benchmark/blob/main/projects/dai-certora/test/MiniVat.t.sol
// this is the OG example that shows how to emulate stateful testing from a single test (check_minivat_n_full_symbolic)
// run:
//   halmos --contract MiniVatTest_0 --function check_minivat_n_full_symbolic
contract Example_0 is Test, SymTest {
    MiniVat public minivat;

    function setUp() public {
        minivat = new MiniVat();
    }

    function check_minivat_n_full_symbolic(bytes4[] memory selectors) public {
        for (uint256 i = 0; i < selectors.length; ++i) {
            assumeValidSelector(selectors[i]);
            assumeSuccessfulCall(address(minivat), calldataFor(selectors[i]));
        }

        assertEq(
            minivat.debt(),
            minivat.Art() * minivat.rate(),
            "The Fundamental Equation of DAI"
        );
    }

    function assumeValidSelector(bytes4 selector) internal view {
        vm.assume(
            selector == minivat.init.selector ||
                selector == minivat.frob.selector ||
                selector == minivat.fold.selector ||
                selector == minivat.move.selector ||
                selector == bytes4(0)
        );
    }

    function assumeSuccessfulCall(address target, bytes memory data) public {
        (bool success, ) = target.call(data);
        vm.assume(success);
    }

    function calldataFor(bytes4 selector) internal view returns (bytes memory) {
        if (selector == minivat.init.selector) {
            return abi.encodeWithSelector(selector);
        } else if (selector == minivat.move.selector) {
            return
                abi.encodeWithSelector(
                    selector,
                    svm.createAddress("dst"),
                    svm.createInt256("wad")
                );
        } else if (selector == minivat.frob.selector) {
            return abi.encodeWithSelector(selector, svm.createInt256("dart"));
        } else if (selector == minivat.fold.selector) {
            return abi.encodeWithSelector(selector, svm.createInt256("delta"));
        } else {
            revert();
        }
    }
}
