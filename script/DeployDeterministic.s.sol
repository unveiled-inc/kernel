pragma solidity ^0.8.0;

import "src/factory/KernelFactory.sol";
import "forge-std/Script.sol";

import "./deterministic/ECDSAValidator.s.sol";
import "./deterministic/Factory.s.sol";
import "./deterministic/SessionKey.s.sol";
import "./deterministic/Kernel2_2.s.sol";
import "./deterministic/Kernel2_3.s.sol";

contract DeployDeterministic is Script {
    function run() external {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address DEPLOYER = address(0x77bbFD2d630A9123Ae5da78a7Af8856983223c8A);
        vm.startBroadcast(DEPLOYER);
        KernelFactory factory = KernelFactory(payable(FactoryDeploy.deploy()));

        address k24 = address(0xd3082872F8B06073A021b4602e022d5A070d7cfC);
        address k24_1tx = address(0xac8C2458377Bd372221007CC91739d9FC6a7B957);
        address k23lite = address(0x482EC42E88a781485E1B6A4f07a0C5479d183291);

        if (!factory.isAllowedImplementation(k24)) {
            factory.setImplementation(k24, true);
        }
        if (!factory.isAllowedImplementation(k24_1tx)) {
            factory.setImplementation(k24_1tx, true);
        }
        if (!factory.isAllowedImplementation(k23lite)) {
            factory.setImplementation(k23lite, true);
        }

        vm.stopBroadcast();
    }
}
