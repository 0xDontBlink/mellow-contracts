// SPDX-License-Identifier: MIT

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import { FixedPointMathLib } from "https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol";

pragma solidity ^0.8.0;

/**
 * @author addo_xyz
 * @notice Bonding curve logic for a linear curve, where each buy/sell changes spot price by adding/substracting delta
 */
contract BitsLinearCurve is Ownable {
    using FixedPointMathLib for uint256;

    uint128 public delta = 600000000000000; //approx $20 per share

    constructor() Ownable(_msgSender()){}

    function setDelta(uint128 _delta) public onlyOwner {
        delta = _delta;
    }

    enum Error {
        OK, // No error
        INVALID_NUMITEMS, // The numItem value is 0
        SPOT_PRICE_OVERFLOW, // The updated spot price doesn't fit into 128 bits
        DELTA_OVERFLOW, // The updated delta doesn't fit into 128 bits
        SPOT_PRICE_UNDERFLOW, // The updated spot price goes too low
        AUCTION_ENDED // The auction has ended
    }
    
    function getBuyInfo(
        uint128 spotPrice,
        uint128 d,
        uint256 numItems,
        uint256 creatorFeeMultiplier,
        uint256 mellowFeeMultiplier
    )
        public
        pure
        returns (
            Error error,
            uint128 newSpotPrice,
            uint256 inputValue,
            uint256 creatorFee,
            uint256 mellowFee
        )
    {
        // We only calculate changes for buying 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0);
        }

        // For a linear curve, the spot price increases by delta for each item bought
        uint256 newSpotPrice_ = spotPrice + d * numItems;
        if (newSpotPrice_ > type(uint128).max) {
            return (Error.SPOT_PRICE_OVERFLOW, 0, 0, 0, 0);
        }
        newSpotPrice = uint128(newSpotPrice_);

        // Spot price is assumed to be the instant sell price. To avoid arbitraging LPs, we adjust the buy price upwards.
        // If spot price for buy and sell were the same, then someone could buy 1 NFT and then sell for immediate profit.
        // EX: Let S be spot price. Then buying 1 NFT costs S ETH, now new spot price is (S+delta).
        // The same person could then sell for (S+delta) ETH, netting them delta ETH profit.
        // If spot price for buy and sell differ by delta, then buying costs (S+delta) ETH.
        // The new spot price would become (S+delta), so selling would also yield (S+delta) ETH.
        uint256 buySpotPrice = spotPrice + d;

        // If we buy n items, then the total cost is equal to:
        // (buy spot price) + (buy spot price + 1*delta) + (buy spot price + 2*delta) + ... + (buy spot price + (n-1)*delta)
        // This is equal to n*(buy spot price) + (delta)*(n*(n-1))/2
        // because we have n instances of buy spot price, and then we sum up from delta to (n-1)*delta
        inputValue = (numItems * buySpotPrice + (numItems * (numItems - 1) * d) / 2);

        // Account for the protocol fee, a flat percentage of the buy amount
        mellowFee = inputValue.mulWadUp(mellowFeeMultiplier);

        // Account for the trade fee, only for Trade pools
        creatorFee = inputValue.mulWadUp(creatorFeeMultiplier);

        // Add the protocol and trade fees to the required input amount
        inputValue += creatorFee + mellowFee;

        // If we got all the way here, no math error happened
        error = Error.OK;
    }

    /**
     * @dev See {ICurve-getSellInfo}
     */
    function getSellInfo(
        uint128 spotPrice,
        uint128 d,
        uint256 numItems,
        uint256 creatorFeeMultiplier,
        uint256 mellowFeeMultiplier
    )
        public
        pure
        returns (
            Error error,
            uint128 newSpotPrice,
            uint256 outputValue,
            uint256 creatorFee,
            uint256 mellowFee
        )
    {
        // We only calculate changes for selling 1 or more NFTs
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0, 0, 0);
        }

        // We first calculate the change in spot price after selling all of the items
        uint256 totalPriceDecrease = d * numItems;

        // If the current spot price is less than the total price decrease, we keep the newSpotPrice at 0
        if (spotPrice < totalPriceDecrease) {
            // We calculate how many items we can sell into the linear curve until the spot price reaches 0, rounding up
            uint256 numItemsTillZeroPrice = spotPrice / d + 1;
            numItems = numItemsTillZeroPrice;
        }
        // Otherwise, the current spot price is greater than or equal to the total amount that the spot price changes
        // Thus we don't need to calculate the maximum number of items until we reach zero spot price, so we don't modify numItems
        else {
            // The new spot price is just the change between spot price and the total price change
            newSpotPrice = spotPrice - uint128(totalPriceDecrease);
        }

        // If we sell n items, then the total sale amount is:
        // (spot price) + (spot price - 1*delta) + (spot price - 2*delta) + ... + (spot price - (n-1)*delta)
        // This is equal to n*(spot price) - (delta)*(n*(n-1))/2
        outputValue = numItems * spotPrice - (numItems * (numItems - 1) * d) / 2;

        // Account for the protocol fee, a flat percentage of the sell amount
        mellowFee = outputValue.mulWadUp(mellowFeeMultiplier);

        // Account for the trade fee, only for Trade pools
        creatorFee = outputValue.mulWadUp(creatorFeeMultiplier);

        // Subtract the protocol and trade fees from the output amount to the seller
        outputValue -= (creatorFee + mellowFee);

        // If we reached here, no math errors
        error = Error.OK;
    }
}
