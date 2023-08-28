// SPDX-License-Identifier: MIT

import {Ownable} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import {FeeReaderErrorCodes} from "./FeeReaderErrorCodes.sol";
import {IFeeReader} from "./IFeeReader.sol";

pragma solidity ^0.8.20;

/**
 * @author addo_xyz
 */
contract MellowBits is Ownable, FeeReaderErrorCodes {
    address public mellowFeeAddress;
    address public feeDistributor;

    IFeeReader public feeReader;
    // Fees
    uint256 public mellowFeePercent;
    uint256 public creatorFeePercent;
    uint256 public reflectionFeePercent;

    uint256 public delta;

    constructor() Ownable(_msgSender()) {}

    event Trade(
        address trader,
        address subject,
        bool isBuy,
        uint256 bitAmount,
        uint256 ethAmount,
        uint256 mellowEthAmount,
        uint256 creatorEthAmount,
        uint256 reflectionEthAmount,
        uint256 supply
    );

    event CreatorFeeUpdated(uint256 fee);
    event MellowFeeUpdated(uint256 fee);
    event ReflectionFeeUpdated(uint256 fee);
    event FeeReaderUpdated(IFeeReader feeReader);
    event FeeDistributorAddressUpdated(address newAddress);
    event DeltaUpdated(uint256 delta);

    error BuyCalculationFailed(Error code);
    error SellCalculationFailed(Error code);

    // Subject => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public bitsBalance;

    // BitsSubject => Supply
    mapping(address => uint256) public bitsSupply;

    function getBuyPrice(
        address bitsSubject,
        uint256 amount
    ) public view returns (uint256) {
        (Error error, uint256 spotPrice, , , , , ) = feeReader.getBuyInfo(
            bitsSupply[bitsSubject],
            delta,
            amount,
            creatorFeePercent,
            mellowFeePercent,
            reflectionFeePercent
        );
        if (error != Error.OK) revert BuyCalculationFailed(error);
        return spotPrice;
    }

    function getBuyPriceAfterFee(
        address bitsSubject,
        uint256 amount
    ) public view returns (uint256) {
        uint256 supply = bitsSupply[bitsSubject];

        (Error error, , , uint256 inputValue, , , ) = feeReader.getBuyInfo(
            supply,
            delta,
            amount,
            creatorFeePercent,
            mellowFeePercent,
            reflectionFeePercent
        );

        if (error != Error.OK) revert BuyCalculationFailed(error);

        return inputValue;
    }

    function getSellPrice(
        address bitsSubject,
        uint256 amount
    ) public view returns (uint256) {
        (Error error, uint256 spotPrice, , , , , ) = feeReader.getBuyInfo(
            bitsSupply[bitsSubject],
            delta,
            amount,
            creatorFeePercent,
            mellowFeePercent,
            reflectionFeePercent
        );
        if (error != Error.OK) revert SellCalculationFailed(error);
        return spotPrice;
    }

    function getSellPriceAfterFee(
        address bitsSubject,
        uint256 amount
    ) public view returns (uint256) {
        uint256 supply = bitsSupply[bitsSubject];

        (Error error, , , uint256 outputValue, , , ) = feeReader.getSellInfo(
            supply,
            delta,
            amount,
            creatorFeePercent,
            mellowFeePercent,
            reflectionFeePercent
        );
        if (error != Error.OK) revert SellCalculationFailed(error);
        return outputValue;
    }

    function _calculateFees(
        uint256 price
    )
        private
        view
        returns (uint256 mellowFee, uint256 creatorFee, uint256 reflectionFee)
    {
        mellowFee = (price * mellowFeePercent) / 1 ether;
        creatorFee = (price * creatorFeePercent) / 1 ether;
        reflectionFee = (price * reflectionFeePercent) / 1 ether;
    }

    function _transferFees(
        uint256 mellowFee,
        uint256 reflectionFee,
        uint256 creatorFee,
        address bitsSubject
    ) private {
        (bool mellowFeeTransfer, ) = mellowFeeAddress.call{value: mellowFee}(
            ""
        );
        (bool reflectionFeeTransfer, ) = feeDistributor.call{
            value: reflectionFee
        }("");
        (bool creatorFeeTransfer, ) = bitsSubject.call{value: creatorFee}("");
        require(
            mellowFeeTransfer && creatorFeeTransfer && reflectionFeeTransfer,
            "Unable to send funds"
        );
    }

    function buyBits(address bitsSubject, uint256 amount) public payable {
        uint256 supply = bitsSupply[bitsSubject];
        require(
            supply > 0 || bitsSubject == msg.sender,
            "Bits creator must buy first bit"
        );

        (
            ,
            uint256 price,
            ,
            uint256 inputValue,
            uint256 creatorFee,
            uint256 mellowFee,
            uint256 reflectionFee
        ) = feeReader.getBuyInfo(
                supply,
                delta,
                amount,
                creatorFeePercent,
                mellowFeePercent,
                reflectionFeePercent
            );

        require(msg.value >= inputValue, "Insufficient payment");

        bitsBalance[bitsSubject][msg.sender] =
            bitsBalance[bitsSubject][msg.sender] +
            amount;
        bitsSupply[bitsSubject] = supply + amount;

        emit Trade(
            msg.sender,
            bitsSubject,
            true,
            amount,
            price,
            mellowFee,
            creatorFee,
            reflectionFee,
            supply + amount
        );

        _transferFees(mellowFee, reflectionFee, creatorFee, bitsSubject);
    }

    function sellBits(address bitsSubject, uint256 amount) public payable {
        uint256 supply = bitsSupply[bitsSubject];
        require(supply > amount, "Cannot sell the last bit");

        uint256 price = feeReader.getPrice(supply - amount, delta);
        (
            uint256 mellowFee,
            uint256 creatorFee,
            uint256 reflectionFee
        ) = _calculateFees(price);

        require(
            bitsBalance[bitsSubject][msg.sender] >= amount,
            "Insufficient bits"
        );
        bitsBalance[bitsSubject][msg.sender] =
            bitsBalance[bitsSubject][msg.sender] -
            amount;
        bitsSupply[bitsSubject] = supply - amount;

        emit Trade(
            msg.sender,
            bitsSubject,
            false,
            amount,
            price,
            mellowFee,
            creatorFee,
            reflectionFee,
            supply - amount
        );

        (bool senderTransfer, ) = msg.sender.call{
            value: price - mellowFee - creatorFee - reflectionFee
        }("");
        require(senderTransfer, "Unable to send funds");

        _transferFees(mellowFee, reflectionFee, creatorFee, bitsSubject);
    }

    function setMellowFeeAddress(address _feeAddress) public onlyOwner {
        mellowFeeAddress = _feeAddress;
    }

    function setFeeReader(IFeeReader _feeReader) public onlyOwner {
        feeReader = _feeReader;
        emit FeeReaderUpdated(_feeReader);
    }

    function setFeeDistributor(
        address _feeDistributorAddress
    ) public onlyOwner {
        feeDistributor = _feeDistributorAddress;
        emit FeeDistributorAddressUpdated(_feeDistributorAddress);
    }

    function setMellowFeePercent(uint256 _feePercent) public onlyOwner {
        mellowFeePercent = _feePercent;
        emit MellowFeeUpdated(_feePercent);
    }

    function setReflectionFeePercent(uint256 _feePercent) public onlyOwner {
        reflectionFeePercent = _feePercent;
        emit ReflectionFeeUpdated(_feePercent);
    }

    function setCreatorFeePercent(uint256 _feePercent) public onlyOwner {
        creatorFeePercent = _feePercent;
        emit CreatorFeeUpdated(_feePercent);
    }

    function setDeltaAmount(uint256 _delta) public onlyOwner {
        delta = _delta;
        emit CreatorFeeUpdated(_delta);
    }
}
