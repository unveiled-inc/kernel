import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import { Wallet } from "zksync-ethers";

const deployEntryPoint: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log("DEPLOY FACTORY");
  const privateKey = process.env.DEPLOYER_PRIVATE_KEY;
  const wallet = new Wallet(privateKey);
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("KernelFactory");
  const owner = await wallet.getAddress();
  const entrypoint = "0x2cE341E8f1E010822B18b6Ce3a37cE3b27B0D68d";
  const entryPointContract = await deployer.deploy(artifact, [owner, entrypoint]);
  console.log(`Contract address: ${await entryPointContract.getAddress()}`);
}

export default deployEntryPoint

