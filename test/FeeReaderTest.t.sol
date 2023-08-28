// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

import {FeeReader} from "../contracts/FeeReader.sol";
import {FeeReaderErrorCodes} from "../contracts/FeeReaderErrorCodes.sol";

contract FeeReaderTest is Test {
    FeeReader feeReader;

    function setUp() public {
        feeReader = new FeeReader();
    }

    // Test:
    // Bits Supply: 30
    // Num items: 5
    // Delta: 100000000000000000 (0.1 ETH)
    // CreatorFee: 5000000000000000
    // mellowFee: 3000000000000000
    // reflectionFee: 2000000000000000
    // Expected: 16.632 ETH
    function test_getBuyInfoExample() public {
        uint128 bitsSupply = 30;
        uint128 delta = 0.1 ether;
        uint256 numItems = 5;
        uint256 creatorFeeMultiplier = (FixedPointMathLib.WAD * 5) / 1000; // 0.5%
        uint256 mellowFeeMultiplier = (FixedPointMathLib.WAD * 2) / 1000; // 0.2%
        uint256 reflectionFeeMultiplier = (FixedPointMathLib.WAD * 1) / 1000; // 0.1%
        (
            FeeReaderErrorCodes.Error error,
            uint256 spotPrice,
            uint256 newSpotPrice,
            uint256 inputValue /* tradeFee */,
            uint256 creatorFee,
            uint256 mellowFee,
            uint256 reflectionFee
        ) = feeReader.getBuyInfo(
                bitsSupply,
                delta,
                numItems,
                creatorFeeMultiplier,
                mellowFeeMultiplier,
                reflectionFeeMultiplier
            );
        assertEq(
            uint256(error),
            uint256(FeeReaderErrorCodes.Error.OK),
            "Error code not OK"
        );
        assertEq(newSpotPrice, 3.5 ether, "Spot price incorrect");
        assertEq(inputValue, 16.632 ether, "Input value incorrect");
        assertEq(mellowFee, 0.033 ether, "Protocol fee incorrect");
    }

    function test_getSellInfoExample() public {
        uint128 bitsSupply = 30;
        uint128 delta = 0.1 ether;
        uint256 numItems = 5;
        uint256 creatorFeeMultiplier = (FixedPointMathLib.WAD * 5) / 1000; // 0.5%
        uint256 mellowFeeMultiplier = (FixedPointMathLib.WAD * 2) / 1000; // 0.2%
        uint256 reflectionFeeMultiplier = (FixedPointMathLib.WAD * 1) / 1000; // 0.1%
        (
            FeeReaderErrorCodes.Error error,
            uint256 spotPrice,
            uint256 newSpotPrice,
            uint256 outputValue /* tradeFee */,
            uint256 creatorFee,
            uint256 mellowFee,
            uint256 reflectionFee
        ) = feeReader.getSellInfo(
                bitsSupply,
                delta,
                numItems,
                creatorFeeMultiplier,
                mellowFeeMultiplier,
                reflectionFeeMultiplier
            );
        assertEq(
            uint256(error),
            uint256(FeeReaderErrorCodes.Error.OK),
            "Error code not OK"
        );
        assertEq(newSpotPrice, 2.5 ether, "Spot price incorrect");
        assertEq(outputValue, 13.888 ether, "Output value incorrect");
        assertEq(mellowFee, 0.028 ether, "Mellow fee incorrect");
    }
}
