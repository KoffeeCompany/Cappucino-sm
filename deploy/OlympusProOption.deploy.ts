import { deployments, getNamedAccounts, ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { sleep } from "../src/utils";
import { getAddresses } from "../hardhat/deployments";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  if (
    hre.network.name === "mainnet" ||
    hre.network.name === "goerli" ||
    hre.network.name === "arbitrum"
  ) {
    console.log(
      `Deploying OlympusProOption to ${hre.network.name}. Hit ctrl + c to abort`
    );
    await sleep(10000);
  }

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const address = getAddresses();
  await deploy("OlympusProOption", {
    from: deployer,
    proxy: {
      owner: deployer,
    },
    args: [
      address.GELETHGUNILP,
      address.GEL,
      (await ethers.getContract("OptionPoolFactory")).address,
      address.TreasuryV2,
      address.BondDepositoryV2,
    ],
    log: hre.network.name != "hardhat" ? true : false,
  });
};

export default func;

func.skip = async (hre: HardhatRuntimeEnvironment) => {
  const shouldSkip =
    hre.network.name === "mainnet" ||
    hre.network.name === "goerli" ||
    hre.network.name === "arbitrum";
  return shouldSkip ? true : false;
};
func.tags = ["OlympusProOption"];
func.dependencies = ["OptionPoolFactory"];
