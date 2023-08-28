// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.20;

import { FeeReaderErrorCodes } from "./FeeReaderErrorCodes.sol";

interface IFeeReader {

    function getPrice(
        uint256 supply, 
        uint256 delta
    )
        external
        view
        returns (
            uint256 price
        );

    /**
     * @notice Given the current state of the pair and the trade, computes how much the user
     * should pay to purchase an NFT from the pair, the new spot price, and other values.
     * @param bitsSupply The current supply of bits
     * @param delta The delta parameter of the pair, what it means depends on the curve
     * @param numBits The number of Bits the user is buying
     * @param creatorFeeMultiplier Determines how much fee the LP takes from this trade, 18 decimals
     * @param mellowFeeMultiplier Determines how much fee the protocol takes from this trade, 18 decimals
     * @return error Any math calculation errors, only Error.OK means the returned values are valid
     * @return spotPrice The current spot price, in tokens
     * @return newSpotPrice The updated selling spot price, in tokens
     * @return inputValue The amount that the user should pay, in tokens
     * @return creatorFee The amount that is sent to the trade fee recipient
     * @return mellowFee The amount of fee to send to the protocol, in tokens
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
     * @notice Given the current state of the pair and the trade, computes how much the user
     * should receive when selling NFTs to the pair, the new spot price, and other values.
     * @param bitsSupply The current supply of bits
     * @param delta The delta parameter of the pair, what it means depends on the curve
     * @param numBits The number of Bits the user is selling 
     * @param feeMultiplier Determines how much fee the LP takes from this trade, 18 decimals
     * @param protocolFeeMultiplier Determines how much fee the protocol takes from this trade, 18 decimals
     * @return error Any math calculation errors, only Error.OK means the returned values are valid
     * @return spotPrice The current spot price, in tokens
     * @return newSpotPrice The updated selling spot price, in tokens
     * @return newDelta The updated delta, used to parameterize the bonding curve
     * @return outputValue The amount that the user should receive, in tokens
     * @return tradeFee The amount that is sent to the trade fee recipient
     * @return protocolFee The amount of fee to send to the protocol, in tokens
     */
    function getSellInfo(
        uint128 bitsSupply,
        uint128 delta,
        uint256 numBits,
        uint256 feeMultiplier,
        uint256 protocolFeeMultiplier,
        uint256 reflectionFeeMultiplier
    )
        external
        view
        returns (
            FeeReaderErrorCodes.Error error,
            uint256 spotPrice,
            uint256 newSpotPrice,
            uint256 newDelta,
            uint256 outputValue,
            uint256 tradeFee,
            uint256 protocolFee,
            uint256 reflectionFee
        );
}
