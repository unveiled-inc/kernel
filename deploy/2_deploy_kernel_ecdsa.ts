import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { Wallet,ContractFactory,Contract } from "zksync-ethers";
import { ethers } from 'ethers';

const deployKernel: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const privateKey = process.env.DEPLOYER_PRIVATE_KEY;
  const wallet = new Wallet(privateKey);
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("Kernel");
  const kernelContract = await deployer.deploy(artifact, ["0x2cE341E8f1E010822B18b6Ce3a37cE3b27B0D68d"]);
  console.log(`Kernel Contract address: ${await kernelContract.getAddress()}`);

  const factoryArtifact = await deployer.loadArtifact("KernelFactory");
  const factoryFactory = new ContractFactory(factoryArtifact.abi, factoryArtifact.bytecode, deployer.zkWallet);
  const factory = factoryFactory.attach("0xdFC95Ba2EeF18a719599b780B29DD498930A2270");

  await factory.setImplementation(await kernelContract.getAddress(), true);
}

export default deployKernel
