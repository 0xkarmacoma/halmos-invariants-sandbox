// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {Vat} from "src/Vat.sol";

// this one shows more general calls (generic sender, value, timestamp)

// run with:
//   halmos --contract Example_3 --function check_vat_generalized

/// @custom:halmos --early-exit
contract Example_3 is Test, SymTest {
    Vat public vat;
    bytes32 public ilk = "gems";
    mapping(uint256 => bool) public visited;

    function setUp() public {
        vat = new Vat();
        vat.init(ilk);
    }

    function check_vat_generalized() public {
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
        // allow any sender and value for this call
        address sender = svm.createAddress("sender");
        uint256 value = svm.createUint256("value");
        vm.deal(sender, value);

        // also allow any block timestamp to simulate calls in different blocks
        uint256 timestamp = svm.createUint256("timestamp");
        vm.assume(timestamp >= block.timestamp);
        vm.warp(timestamp);

        vm.prank(sender);
        (bool success, ) = target.call{value: value}(data);
        vm.assume(success);
    }
}
