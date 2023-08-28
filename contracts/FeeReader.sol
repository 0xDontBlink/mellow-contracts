// SPDX-License-Identifier: MIT

import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {FeeReaderErrorCodes} from "./FeeReaderErrorCodes.sol";

pragma solidity ^0.8.20;

/**
 * @author addo_xyz
 * @notice Bonding curve logic for a linear curve, where each buy/sell changes spot price by adding/substracting delta
 */
contract FeeReader is FeeReaderErrorCodes {
    using FixedPointMathLib for uint256;

    function getPrice(
        uint256 supply,
        uint256 delta
    ) public pure returns (uint256) {
        if (supply == 0) return 0;
        return (supply * delta);
    }

    // Test:
    // Bits Supply: 30
    // Num items: 5
    // Delta: 100000000000000000 (0.1 ETH)
    // CreatorFee: 5000000000000000
    // mellowFee: 3000000000000000
    // reflectionFee: 2000000000000000
    // Expected: 16.632 ETH
    function getBuyInfo(
        uint256 bitsSupply,
        uint256 delta,
        uint256 numItems,
        uint256 creatorFeeMultiplier,
        uint256 mellowFeeMultiplier,
        uint256 reflectionFeeMultiplier
    )
        public
        pure
        returns (
            Error error,
            uint256 spotPrice,
            uint256 newSpotPrice,
            uint256 inputValue,
            uint256 creatorFee,
            uint256 mellowFee,
            uint256 reflectionFee
        )
    {
        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0, 0, 0);
        }

        // Calculate the current spot price
        spotPrice = getPrice(bitsSupply, delta);
        // For a linear curve, the spot price increases by delta for each item bought
        uint256 newSpotPrice_ = spotPrice + delta * numItems;
        if (newSpotPrice_ > type(uint256).max) {
            return (Error.SPOT_PRICE_OVERFLOW, 0, 0, 0, 0, 0, 0);
        }
        newSpotPrice = uint256(newSpotPrice_);

        // Spot price is assumed to be the instant sell price. To avoid arbitraging LPs, we adjust the buy price upwards.
        // If spot price for buy and sell were the same, then someone could buy 1 NFT and then sell for immediate profit.
        // EX: Let S be spot price. Then buying 1 NFT costs S ETH, now new spot price is (S+delta).
        // The same person could then sell for (S+delta) ETH, netting them delta ETH profit.
        // If spot price for buy and sell differ by delta, then buying costs (S+delta) ETH.
        // The new spot price would become (S+delta), so selling would also yield (S+delta) ETH.
        uint256 buySpotPrice = spotPrice + delta;

        // If we buy n items, then the total cost is equal to:
        // (buy spot price) + (buy spot price + 1*delta) + (buy spot price + 2*delta) + ... + (buy spot price + (n-1)*delta)
        // This is equal to n*(buy spot price) + (delta)*(n*(n-1))/2
        // because we have n instances of buy spot price, and then we sum up from delta to (n-1)*delta
        inputValue = (numItems *
            buySpotPrice +
            (numItems * (numItems - 1) * delta) /
            2);

        // Account for the mellow fee, a flat percentage of the buy amount
        mellowFee = inputValue.mulWadUp(mellowFeeMultiplier);

        // Account for the creator fee
        creatorFee = inputValue.mulWadUp(creatorFeeMultiplier);

        // Account for the reflection fee
        reflectionFee = inputValue.mulWadUp(reflectionFeeMultiplier);

        // Add the mellow, creator and reflection fees to the required input amount
        inputValue += creatorFee + mellowFee + reflectionFee;

        // If we got all the way here, no math error happened
        error = Error.OK;
    }

    // Test:
    // Bits Supply: 30
    // Num items: 5
    // Delta: 100000000000000000
    // CreatorFee: 5000000000000000
    // mellowFee: 2000000000000000
    // ReflectionFee: 2000000000000000
    // ExpectedOutput: 13.888 ETH
    function getSellInfo(
        uint256 bitsSupply,
        uint256 delta,
        uint256 numItems,
        uint256 creatorFeeMultiplier,
        uint256 mellowFeeMultiplier,
        uint256 reflectionFeeMultiplier
    )
        public
        pure
        returns (
            Error error,
            uint256 spotPrice,
            uint256 newSpotPrice,
            uint256 outputValue,
            uint256 creatorFee,
            uint256 mellowFee,
            uint256 reflectionFee
        )
    {
        // We only calculate changes for selling 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0, 0, 0);
        }

        // Calculate the current spot price
        spotPrice = getPrice(bitsSupply, delta);

        // We first calculate the change in spot price after selling all of the items
        uint256 totalPriceDecrease = delta * numItems;

        // If the current spot price is less than the total price decrease, we keep the newSpotPrice at 0
        if (spotPrice < totalPriceDecrease) {
            // We calculate how many items we can sell into the linear curve until the spot price reaches 0, rounding up
            uint256 numItemsTillZeroPrice = spotPrice / delta + 1;
            numItems = numItemsTillZeroPrice;
        }
        // Otherwise, the current spot price is greater than or equal to the total amount that the spot price changes
        // Thus we don't need to calculate the maximum number of items until we reach zero spot price, so we don't modify numItems
        else {
            // The new spot price is just the change between spot price and the total price change
            newSpotPrice = spotPrice - uint256(totalPriceDecrease);
        }

        // If we sell n items, then the total sale amount is:
        // (spot price) + (spot price - 1*delta) + (spot price - 2*delta) + ... + (spot price - (n-1)*delta)
        // This is equal to n*(spot price) - (delta)*(n*(n-1))/2
        outputValue =
            numItems *
            spotPrice -
            (numItems * (numItems - 1) * delta) /
            2;

        // Account for the mellow fee, a flat percentage of the sell amount
        mellowFee = outputValue.mulWadUp(mellowFeeMultiplier);

        // Account for the creator fee
        creatorFee = outputValue.mulWadUp(creatorFeeMultiplier);

        // Account for the reflection fee
        reflectionFee = outputValue.mulWadUp(reflectionFeeMultiplier);

        // Subtract the mellow, creator and reflection fees from the output amount to the seller
        outputValue -= (creatorFee + mellowFee + reflectionFee);

        // If we reached here, no math errors
        error = Error.OK;
    }
}
