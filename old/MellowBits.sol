// SPDX-License-Identifier: MIT

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "hardhat/console.sol";

import { IFeeReader } from "./IFeeReader.sol";

pragma solidity ^0.8.20;

contract MellowBits is Ownable {
    address public mellowFeeAddress;
    IFeeReader feeReaderAddress;
    // Fees
    uint256 public mellowFeePercent;
    uint256 public creatorFeePercent;
    uint256 public reflectionFeePercent;

    uint256 public delta = 600000000000000; //approx $20 per share for testing

    constructor() Ownable(_msgSender()){}

    event Trade(address trader, address subject, bool isBuy, uint256 bitAmount, uint256 ethAmount, uint256 mellowEthAmount, uint256 creatorEthAmount, uint256 supply);

    // Subject => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public sharesBalance;

    // SharesSubject => Supply
    mapping(address => uint256) public sharesSupply;

    function getPrice(uint256 supply, uint256 amount) public view returns (uint256) {
        if (supply == 0) return delta * amount;
        return (supply * delta);
    }

    function getBuyPrice(address sharesSubject, uint256 amount) public view returns (uint256) {
        (,uint256 spotPrice,,,,) 
            = feeReaderAddress.getBuyInfo(sharesSupply[sharesSubject], delta, amount, creatorFeePercent, mellowFeePercent);
        return spotPrice;
    }

    function getBuyPriceAfterFee(address sharesSubject, uint256 amount) public view returns (uint256) {
        uint256 supply = sharesSupply[sharesSubject];
        
        (,,, uint256 inputValue,,) 
            = feeReaderAddress.getBuyInfo(supply, delta, amount, creatorFeePercent, mellowFeePercent);
        return inputValue;
    }

   function getSellPrice(address sharesSubject, uint256 amount) public view returns (uint256) {
        (,uint256 spotPrice,,,,) 
            = feeReaderAddress.getBuyInfo(sharesSupply[sharesSubject], delta, amount, creatorFeePercent, mellowFeePercent);
        return spotPrice;
    }

    function getSellPriceAfterFee(address sharesSubject, uint256 amount) public view returns (uint256) {
        uint256 price = getSellPrice(sharesSubject, amount);
        uint256 mellowFee = price * mellowFeePercent / 1 ether;
        uint256 subjectFee = price * creatorFeePercent / 1 ether;
        return price - mellowFee - subjectFee;
    }

    function buyShares(address sharesSubject, uint256 amount) public payable {
        uint256 supply = sharesSupply[sharesSubject];
        require(supply > 0 || sharesSubject == msg.sender, "Only the bits' creator can buy the first share");
        uint256 price = getPrice(supply, amount);
        uint256 mellowFee = price * mellowFeePercent / 1 ether;
        uint256 subjectFee = price * creatorFeePercent / 1 ether;
        require(msg.value >= price + mellowFee + subjectFee, "Insufficient payment");
        sharesBalance[sharesSubject][msg.sender] = sharesBalance[sharesSubject][msg.sender] + amount;
        sharesSupply[sharesSubject] = supply + amount;
        emit Trade(msg.sender, sharesSubject, true, amount, price, mellowFee, subjectFee, supply + amount);
        (bool success1, ) = mellowFeeAddress.call{value: mellowFee}("");
        (bool success2, ) = sharesSubject.call{value: subjectFee}("");
        require(success1 && success2, "Unable to send funds");
    }

    function sellShares(address sharesSubject, uint256 amount) public payable {
        uint256 supply = sharesSupply[sharesSubject];
        require(supply > amount, "Cannot sell the last bit");
        uint256 price = getPrice(supply - amount, amount);
        uint256 mellowFee = price * mellowFeePercent / 1 ether;
        uint256 subjectFee = price * creatorFeePercent / 1 ether;
        require(sharesBalance[sharesSubject][msg.sender] >= amount, "Insufficient bits");
        sharesBalance[sharesSubject][msg.sender] = sharesBalance[sharesSubject][msg.sender] - amount;
        sharesSupply[sharesSubject] = supply - amount;
        emit Trade(msg.sender, sharesSubject, false, amount, price, mellowFee, subjectFee, supply - amount);
        (bool success1, ) = msg.sender.call{value: price - mellowFee - subjectFee}("");
        (bool success2, ) = mellowFeeAddress.call{value: mellowFee}("");
        (bool success3, ) = sharesSubject.call{value: subjectFee}("");
        require(success1 && success2 && success3, "Unable to send funds");
    }

   function setFeeAddress(address _feeAddress) public onlyOwner {
        mellowFeeAddress = _feeAddress;
    }

    function setFeeReaderAddress(IFeeReader _feeReaderAddress) public onlyOwner {
        feeReaderAddress = _feeReaderAddress;
    }

    function setMellowFeePercent(uint256 _feePercent) public onlyOwner {
        mellowFeePercent = _feePercent;
    }

    function setCreatorFeePercent(uint256 _feePercent) public onlyOwner {
        creatorFeePercent = _feePercent;
    }

    function setDeltaAmount(uint256 _delta) public onlyOwner {
        delta = _delta;
    }
}
