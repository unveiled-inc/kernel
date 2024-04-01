pragma solidity ^0.8.0;

import "src/factory/KernelFactory.sol";
import "I4337/interfaces/IStakeManager.sol";
import "src/Kernel.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";
import "src/validator/ECDSAValidator.sol";

contract DeployKernel is Script {
    address constant DEPLOYER = 0x77bbFD2d630A9123Ae5da78a7Af8856983223c8A;
    address constant ENTRYPOINT_0_6 = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    address constant EXPECTED_KERNEL_ADDRESS = 0xac8C2458377Bd372221007CC91739d9FC6a7B957;
    address payable constant EXPECTED_KERNEL_FACTORY_ADDRESS = payable(0x2b5f79B0a0A78Ecc9E339Cc6cb5d86de05Aa9364);

    function run() public {
        vm.startBroadcast(DEPLOYER);
        KernelFactory factory = KernelFactory(EXPECTED_KERNEL_FACTORY_ADDRESS);

        if (EXPECTED_KERNEL_ADDRESS.code.length == 0) {
            Kernel kernel;
            kernel = new Kernel{salt: 0}(IEntryPoint(ENTRYPOINT_0_6));
            console.log("Kernel address: %s", address(kernel));
            require(address(kernel) == EXPECTED_KERNEL_ADDRESS, "address mismatch");
        }
        if (factory.isAllowedImplementation(EXPECTED_KERNEL_ADDRESS) == false) {
            console.log("Registering kernel implementation");
            factory.setImplementation(EXPECTED_KERNEL_ADDRESS, true);
        }
        IEntryPoint entryPoint = IEntryPoint(ENTRYPOINT_0_6);
        IStakeManager.DepositInfo memory info = entryPoint.getDepositInfo(address(factory));
        if (info.stake == 0) {
            console.log("Need to stake to factory");
        }
        vm.stopBroadcast();
    }
}
