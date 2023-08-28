// SPDX-License-Identifier: MIT

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "hardhat/console.sol";

import { IFeeReader } from "./IFeeReader.sol";

pragma solidity ^0.8.20;

contract MellowBits is Ownable {
    address public mellowFeeAddress;
    address public feeDistributor;

    IFeeReader feeReader;
    // Fees
    uint256 public mellowFeePercent;
    uint256 public creatorFeePercent;
    uint256 public reflectionFeePercent;

    uint256 public delta = 500000000000000; //approx $20 per share for testing

    constructor() Ownable(_msgSender()){}

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

    // Subject => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public sharesBalance;

    // SharesSubject => Supply
    mapping(address => uint256) public sharesSupply;

    function getBuyPrice(address sharesSubject, uint256 amount) public view returns (uint256) {
        (,uint256 spotPrice,,,,,) 
            = feeReader.getBuyInfo(sharesSupply[sharesSubject], delta, amount, creatorFeePercent, mellowFeePercent, reflectionFeePercent);
        return spotPrice;
    }

    function getBuyPriceAfterFee(address sharesSubject, uint256 amount) public view returns (uint256) {
        uint256 supply = sharesSupply[sharesSubject];
        
        (,,, uint256 inputValue,,,) 
            = feeReader.getBuyInfo(supply, delta, amount, creatorFeePercent, mellowFeePercent, reflectionFeePercent);
        return inputValue;
    }

   function getSellPrice(address sharesSubject, uint256 amount) public view returns (uint256) {
        (,uint256 spotPrice,,,,,) 
            = feeReader.getBuyInfo(
                sharesSupply[sharesSubject], 
                delta, amount, creatorFeePercent, mellowFeePercent, reflectionFeePercent);
        return spotPrice;
    }

    function getSellPriceAfterFee(address sharesSubject, uint256 amount) public view returns (uint256) {
        uint256 price = getSellPrice(sharesSubject, amount);
        uint256 mellowFee = price * mellowFeePercent / 1 ether;
        uint256 subjectFee = price * creatorFeePercent / 1 ether;
        return price - mellowFee - subjectFee;
    }

    function _calculateFees(
        uint256 price
    )
        private
        view
        returns (
            uint256 mellowFee,
            uint256 creatorFee,
            uint256 reflectionFee
        )
    {
        mellowFee = price * mellowFeePercent / 1 ether;
        creatorFee = price * creatorFeePercent / 1 ether;
        reflectionFee = price * reflectionFeePercent / 1 ether;
    }

    function _transferFees(uint256 mellowFee, uint256 reflectionFee, uint256 creatorFee, address sharesSubject) private {
        (bool mellowFeeTransfer, ) = mellowFeeAddress.call{value: mellowFee}("");
        (bool reflectionFeeTransfer, ) = feeDistributor.call{value: reflectionFee}("");
        (bool creatorFeeTransfer, ) = sharesSubject.call{value: creatorFee}("");
        require(mellowFeeTransfer && creatorFeeTransfer && reflectionFeeTransfer, "Unable to send funds");
    }

    function buyShares(address sharesSubject, uint256 amount) public payable {
        uint256 supply = sharesSupply[sharesSubject];
        require(supply > 0 || sharesSubject == msg.sender, "Only the bits' creator can buy the first share");

        (,uint256 price,,,uint256 creatorFee, uint256 mellowFee, uint256 reflectionFee) 
            = feeReader.getBuyInfo(supply, delta, amount, creatorFeePercent, mellowFeePercent, reflectionFeePercent);

        require(msg.value >= price + mellowFee + creatorFee + reflectionFee, "Insufficient payment");

        sharesBalance[sharesSubject][msg.sender] = sharesBalance[sharesSubject][msg.sender] + amount;
        sharesSupply[sharesSubject] = supply + amount;
        
        emit Trade(msg.sender, sharesSubject, true, amount, price, mellowFee, creatorFee, reflectionFee, supply + amount);
        _transferFees(mellowFee, reflectionFee, creatorFee, sharesSubject);
    }

    function sellShares(address sharesSubject, uint256 amount) public payable {
        uint256 supply = sharesSupply[sharesSubject];
        require(supply > amount, "Cannot sell the last bit");

        uint256 price = feeReader.getPrice(supply - amount, delta);
        (uint256 mellowFee, uint256 creatorFee, uint256 reflectionFee) = _calculateFees(price);

        require(sharesBalance[sharesSubject][msg.sender] >= amount, "Insufficient bits");
        sharesBalance[sharesSubject][msg.sender] = sharesBalance[sharesSubject][msg.sender] - amount;
        sharesSupply[sharesSubject] = supply - amount;

        emit Trade(msg.sender, sharesSubject, false, amount, price, mellowFee, creatorFee, reflectionFee, supply - amount);
        
        (bool senderTransfer, ) = msg.sender.call{value: price - mellowFee - creatorFee - reflectionFee}("");
        require(senderTransfer, "Unable to send funds");

        _transferFees(mellowFee, reflectionFee, creatorFee, sharesSubject);
    }

    function setMellowFeeAddress(address _feeAddress) public onlyOwner {
        mellowFeeAddress = _feeAddress;
    }

    function setFeeReader(IFeeReader _feeReader) public onlyOwner {
        feeReader = _feeReader;
        emit FeeReaderUpdated(_feeReader);
    }

    function setFeeDistributor(address _feeDistributorAddress) public onlyOwner {
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
