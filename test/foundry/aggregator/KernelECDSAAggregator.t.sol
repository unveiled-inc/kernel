// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEntryPoint} from "I4337/interfaces/IEntryPoint.sol";
import {IAggregator} from "I4337/interfaces/IAggregator.sol";
import "src/Kernel.sol";
import "src/validator/ECDSAAggregatedValidator.sol";
// test artifacts
// test utils
import "forge-std/Test.sol";
import {ERC4337Utils} from "../utils/ERC4337Utils.sol";
import {KernelTestBase} from "../KernelTestBase.sol";
import {TestExecutor} from "../mock/TestExecutor.sol";
import {TestValidator} from "../mock/TestValidator.sol";
import {IKernel} from "src/interfaces/IKernel.sol";

using ERC4337Utils for IEntryPoint;

contract KernelECDSAAggregatorTest is KernelTestBase {
    address parent;
    address parentOwner;
    uint256 parentOwnerKey;
    function setUp() public virtual {
        (parent) = makeAddr("parent");
        (parentOwner, parentOwnerKey) = makeAddrAndKey("parentOwner");
        _initialize();
        defaultValidator = new ECDSAAggregatedValidator();
        _setAddress();
        _setExecutionDetail();
    }

    function test_ignore() external {}

    function _setExecutionDetail() internal virtual override {
        executionDetail.executor = address(new TestExecutor());
        executionSig = TestExecutor.doNothing.selector;
        executionDetail.validator = new TestValidator();
    }

    function getEnableData() internal view virtual override returns (bytes memory) {
        return "";
    }

    function getValidatorSignature(UserOperation memory) internal view virtual override returns (bytes memory) {
        return "";
    }

    function getOwners() internal view override returns (address[] memory) {
        address[] memory owners = new address[](1);
        owners[0] = owner;
        return owners;
    }

    function getInitializeData() internal view override returns (bytes memory) {
        return abi.encodeWithSelector(KernelStorage.initialize.selector, defaultValidator, abi.encodePacked(owner, address(0)));
    }

    function signUserOp(UserOperation memory op) internal view override returns (bytes memory) {
        return abi.encodePacked(bytes4(0x00000000), entryPoint.signUserOpHash(vm, ownerKey, op));
    }

    function getWrongSignature(UserOperation memory op) internal view override returns (bytes memory) {
        return abi.encodePacked(bytes4(0x00000000), entryPoint.signUserOpHash(vm, ownerKey + 1, op));
    }

    function signHash(bytes32 hash) internal view override returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey, ECDSA.toEthSignedMessageHash(hash));
        return abi.encodePacked(r, s, v);
    }

    function getWrongSignature(bytes32 hash) internal view override returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerKey + 1, ECDSA.toEthSignedMessageHash(hash));
        return abi.encodePacked(r, s, v);
    }

    function test_default_validator_enable() external override {
        UserOperation memory op = entryPoint.fillUserOp(
            address(kernel),
            abi.encodeWithSelector(
                IKernel.execute.selector,
                address(defaultValidator),
                0,
                abi.encodeWithSelector(ECDSAAggregatedValidator.enable.selector, abi.encodePacked(address(0xdeadbeef))),
                Operation.Call
            )
        );
        op.signature = signUserOp(op);
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = op;
        entryPoint.handleOps(ops, beneficiary);
        (address owner, ) = ECDSAAggregatedValidator(address(defaultValidator)).ecdsaValidatorStorage(address(kernel));
        assertEq(owner, address(0xdeadbeef), "owner should be 0xdeadbeef");
    }

    function test_mode_4() external {
        UserOperation memory op = entryPoint.fillUserOp(
            address(kernel),
            abi.encodeWithSelector(
                IKernel.execute.selector,
                address(defaultValidator),
                0,
                abi.encodeWithSelector(ECDSAAggregatedValidator.enable.selector, abi.encodePacked(owner, parent)),
                Operation.Call
            )
        );
        op.signature = signUserOp(op);
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = op;
        entryPoint.handleOps(ops, beneficiary);
        (address o, address p) = ECDSAAggregatedValidator(address(defaultValidator)).ecdsaValidatorStorage(address(kernel));
        assertEq(o, owner, "owner should be owner");
        assertEq(p, parent, "parent should be parent");
        vm.startPrank(parent);
        defaultValidator.enable(abi.encodePacked(parentOwner, address(0)));
        vm.stopPrank();
        op = entryPoint.fillUserOp(
            address(kernel),
            abi.encodeWithSelector(
                IKernel.execute.selector,
                address(parent),
                1,
                "",
                Operation.Call
            )
        );
        assertEq(entryPoint.getUserOpHash(op), ECDSAAggregatedValidator(address(defaultValidator)).userOpHash(address(entryPoint),op));
        op.signature = abi.encodePacked(bytes4(0x00000004), entryPoint.signUserOpHash(vm, parentOwnerKey, op));
        IEntryPoint.UserOpsPerAggregator[] memory aops = new IEntryPoint.UserOpsPerAggregator[](1);
        aops[0].aggregator = IAggregator(address(defaultValidator));
        aops[0].userOps = new UserOperation[](1);
        aops[0].userOps[0] = op;

        entryPoint.handleAggregatedOps(aops, beneficiary);
    }

    function test_default_validator_disable() external override {
        UserOperation memory op = entryPoint.fillUserOp(
            address(kernel),
            abi.encodeWithSelector(
                IKernel.execute.selector,
                address(defaultValidator),
                0,
                abi.encodeWithSelector(ECDSAAggregatedValidator.disable.selector, ""),
                Operation.Call
            )
        );
        op.signature = signUserOp(op);
        UserOperation[] memory ops = new UserOperation[](1);
        ops[0] = op;
        entryPoint.handleOps(ops, beneficiary);
        (address owner, ) = ECDSAAggregatedValidator(address(defaultValidator)).ecdsaValidatorStorage(address(kernel));
        assertEq(owner, address(0), "owner should be 0");
    }
}
