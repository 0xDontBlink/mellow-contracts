// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FeeReaderErrorCodes} from "./FeeReaderErrorCodes.sol";

interface IFeeReader {
    function getPrice(
        uint256 supply,
        uint256 delta
    ) external view returns (uint256 price);

    /**
     * @notice Given the current state of the supply and the trade, computes how much the user
     * should pay when buying bits, the new bit price, and other values.
     * @param bitsSupply The current supply of bits
     * @param delta The delta parameter of the pair, what it means depends on the curve
     * @param numBits The number of Bits the user is buying
     * @param creatorFeeMultiplier Determines how much fee the creator takes from this trade, 18 decimals
     * @param mellowFeeMultiplier Determines how much fee mellow takes from this trade, 18 decimals
     * @return error Any math calculation errors, only Error.OK means the returned values are valid
     * @return spotPrice The current spot price, in ether
     * @return newSpotPrice The updated buy spot price, in ether
     * @return inputValue The amount that the user should pay, in ether
     * @return creatorFee The amount that is sent to the bits creator, in ether
     * @return mellowFee The fee to send to mellow, in ether
     * @return reflectionFee The fee to send to the reflection fee distributor, in ether
     */
    function getBuyInfo(
        uint256 bitsSupply,
        uint256 delta,
        uint256 numBits,
        uint256 creatorFeeMultiplier,
        uint256 mellowFeeMultiplier,
        uint256 reflectionFeeMultiplier
    )
        external
        view
        returns (
            FeeReaderErrorCodes.Error error,
            uint256 spotPrice,
            uint256 newSpotPrice,
            uint256 inputValue,
            uint256 creatorFee,
            uint256 mellowFee,
            uint256 reflectionFee
        );

    /**
     * @notice Given the current state of the supply and the trade, computes how much the user
     * should recieve when selling bits, the new bit price, and other values.
     * @param bitsSupply The current supply of bits
     * @param delta The delta parameter of the pair, what it means depends on the curve
     * @param numBits The number of Bits the user is selling
     * @param creatorFeeMultiplier Determines how much fee the creator takes from this trade, 18 decimals
     * @param mellowFeeMultiplier Determines how much fee mellow takes from this trade, 18 decimals
     * @return error Any math calculation errors, only Error.OK means the returned values are valid
     * @return spotPrice The current spot price, in ether
     * @return newSpotPrice The updated sell spot price, in ether
     * @return outputValue The amount that the user should recieve, in ether
     * @return creatorFee The amount that is sent to the bits creator, in ether
     * @return mellowFee The fee to send to mellow, in ether
     * @return reflectionFee The fee to send to the reflection fee distributor, in ether
     */
    function getSellInfo(
        uint256 bitsSupply,
        uint256 delta,
        uint256 numBits,
        uint256 creatorFeeMultiplier,
        uint256 mellowFeeMultiplier,
        uint256 reflectionFeeMultiplier
    )
        external
        view
        returns (
            FeeReaderErrorCodes.Error error,
            uint256 spotPrice,
            uint256 newSpotPrice,
            uint256 outputValue,
            uint256 creatorFee,
            uint256 mellowFee,
            uint256 reflectionFee
        );
}
