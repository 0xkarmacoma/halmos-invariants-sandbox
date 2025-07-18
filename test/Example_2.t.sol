// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {Vat} from "src/Vat.sol";

// this one demonstrates the how state snapshots to avoid visiting the same state multiple times (conceptually)
// note that this is actually flawed, because updating the `visited` map itself changes the state

// run with:
//   halmos --contract Example_2 --function check_vat_snapshotState

/// @custom:halmos --early-exit
contract Example_2 is Test, SymTest {
    Vat public vat;
    bytes32 public ilk = "gems";
    mapping(uint256 => bool) public visited;

    function setUp() public {
        vat = new Vat();
        vat.init(ilk);
    }

    function check_vat_snapshotState() public {
        uint256 depth = vm.envOr("INVARIANT_DEPTH", uint256(2));
        console.log("generating call sequences with depth", depth);

        // record the initial state snapshot
        visited[vm.snapshotState()] = true;

        for (uint256 i = 0; i < depth; ++i) {
            assumeSuccessfulCall(
                address(vat),
                svm.createCalldata(address(vat))
            );

            uint256 snapshot = vm.snapshotState();

            // skip if the snapshot has already been visited
            vm.assume(!visited[snapshot]);

            // keep track of new snapshots
            visited[snapshot] = true;
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
