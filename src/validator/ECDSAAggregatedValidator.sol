// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {UserOperation} from "I4337/interfaces/UserOperation.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {IKernelValidator} from "../interfaces/IKernelValidator.sol";
import {ValidationData} from "../common/Types.sol";
import {SIG_VALIDATION_FAILED} from "../common/Constants.sol";
import "forge-std/console.sol";

struct ECDSAAggregatedValidatorStorage {
    address owner;
    address parent;
}

contract ECDSAAggregatedValidator is IKernelValidator {
    event OwnerChanged(address indexed kernel, address indexed oldOwner, address indexed newOwner);

    mapping(address => ECDSAAggregatedValidatorStorage) public ecdsaValidatorStorage;

    function disable(bytes calldata) external payable override {
        delete ecdsaValidatorStorage[msg.sender];
    }

    function enable(bytes calldata _data) external payable override {
        address owner = address(bytes20(_data[0:20]));
        address parent = address(bytes20(_data[20:40]));
        address oldOwner = ecdsaValidatorStorage[msg.sender].owner;
        ecdsaValidatorStorage[msg.sender].owner = owner;
        ecdsaValidatorStorage[msg.sender].parent = parent;
        emit OwnerChanged(msg.sender, oldOwner, owner);
    }

    function validateUserOp(UserOperation calldata _userOp, bytes32 _userOpHash, uint256)
        external
        payable
        override
        returns (ValidationData validationData)
    {
        address owner = ecdsaValidatorStorage[_userOp.sender].owner;
        bytes32 hash = ECDSA.toEthSignedMessageHash(_userOpHash);
        if (owner == ECDSA.recover(hash, _userOp.signature)) {
            return ValidationData.wrap(0);
        }
        if (owner != ECDSA.recover(_userOpHash, _userOp.signature)) {
            return SIG_VALIDATION_FAILED;
        }
    }

    function validateSignature(bytes32 hash, bytes calldata signature) public view override returns (ValidationData) {
        address owner = ecdsaValidatorStorage[msg.sender].owner;
        if (owner == ECDSA.recover(hash, signature)) {
            return ValidationData.wrap(0);
        }
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(hash);
        address recovered = ECDSA.recover(ethHash, signature);
        if (owner != recovered) {
            return SIG_VALIDATION_FAILED;
        }
        return ValidationData.wrap(0);
    }

    // === aggregator functions ===
    function validateSignatures(
        UserOperation[] calldata userOps,
        bytes calldata //this is not actually a signature aggregator
    ) external view {
        for (uint256 i = 0; i < userOps.length; i++) {
            // msg.sender will be entrypoint
            UserOperation calldata userOp = userOps[i];
            bytes32 opHash = userOpHash(msg.sender, userOp);
            address owner = ecdsaValidatorStorage[userOp.sender].owner;
            bytes32 hash = ECDSA.toEthSignedMessageHash(opHash);
            // should be using signature offset of 4
            if (owner == ECDSA.recover(hash, userOp.signature[4:])) {
                return; // no revert means success
            }
            address parentOwner = ecdsaValidatorStorage[ecdsaValidatorStorage[userOp.sender].parent].owner;
            if ( parentOwner != ECDSA.recover(hash, userOp.signature[4:])) {
                revert();
            }
        }
    }

    function aggregateSignatures(
        UserOperation[] calldata userOps
    ) external view returns (bytes memory aggregatedSignature) {
        // no-op
    }

    function userOpHash(address entrypoint, UserOperation memory userOp) public view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256(
                    abi.encode(
                        userOp.sender,
                        userOp.nonce,
                        keccak256(userOp.initCode),
                        keccak256(userOp.callData),
                        userOp.callGasLimit,
                        userOp.verificationGasLimit,
                        userOp.preVerificationGas,
                        userOp.maxFeePerGas,
                        userOp.maxPriorityFeePerGas,
                        keccak256(userOp.paymasterAndData)
                    )
                ),
                entrypoint,
                block.chainid
            )
        );
    }


    function validCaller(address _caller, bytes calldata) external view override returns (bool) {
        return ecdsaValidatorStorage[msg.sender].owner == _caller;
    }
}
