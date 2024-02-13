import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { Wallet,ContractFactory,Contract } from "zksync-ethers";
import { ethers } from 'ethers';

const deployECDSA: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const privateKey = process.env.DEPLOYER_PRIVATE_KEY;
  const wallet = new Wallet(privateKey);
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("ECDSAValidator");
  const kernelContract = await deployer.deploy(artifact, []);
  console.log(`ECDSA Contract address: ${await kernelContract.getAddress()}`);
}

export default deployECDSA
