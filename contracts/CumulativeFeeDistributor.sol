// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICumulativeFeeDistributor} from "./ICumulativeFeeDistributor.sol";

/**
 * @notice Allows anyone to claim a token if they exist in a merkle root.
 */
contract CumulativeFeeDistributor is Ownable, ICumulativeFeeDistributor {
    using SafeERC20 for IERC20;

    bytes32 public override merkleRoot;
    mapping(address => uint256) public cumulativeClaimed;

    receive() external payable {}

    function setMerkleRoot(bytes32 merkleRoot_) external override onlyOwner {
        emit MerkelRootUpdated(merkleRoot, merkleRoot_);
        merkleRoot = merkleRoot_;
    }

    function claim(
        address account,
        uint256 cumulativeAmount,
        bytes32 expectedMerkleRoot,
        bytes32[] calldata merkleProof
    ) external override {
        require(
            merkleRoot == expectedMerkleRoot,
            "CMD: Merkle root was updated"
        );

        // Verify the merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(account, cumulativeAmount));
        require(
            _verifyAsm(merkleProof, expectedMerkleRoot, leaf),
            "CMD: Invalid proof"
        );

        // Mark it claimed
        uint256 preclaimed = cumulativeClaimed[account];
        require(preclaimed < cumulativeAmount, "CMD: Nothing to claim");
        cumulativeClaimed[account] = cumulativeAmount;

        // Send the token
        unchecked {
            uint256 amount = cumulativeAmount - preclaimed;
            (bool sent, ) = payable(account).call{value: amount}("");
            require(sent, "Failed to transfer to account");
            emit Claimed(account, amount);
        }
    }

    // Experimental assembly optimization
    function _verifyAsm(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) private pure returns (bool valid) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let mem1 := mload(0x40)
            let mem2 := add(mem1, 0x20)
            let ptr := proof.offset

            for {
                let end := add(ptr, mul(0x20, proof.length))
            } lt(ptr, end) {
                ptr := add(ptr, 0x20)
            } {
                let node := calldataload(ptr)

                switch lt(leaf, node)
                case 1 {
                    mstore(mem1, leaf)
                    mstore(mem2, node)
                }
                default {
                    mstore(mem1, node)
                    mstore(mem2, leaf)
                }

                leaf := keccak256(mem1, 0x40)
            }

            valid := eq(root, leaf)
        }
    }

    function emergencyWithdraw(
        address _token,
        uint256 _amount
    ) public onlyOwner {
        IERC20(_token).safeTransfer(_msgSender(), _amount);
    }

    function emergencyWithdraw(uint256 amount) public onlyOwner {
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "Failed to transfer to account");
    }
}
