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
      `Deploying OlympusProOptionFactory to ${hre.network.name}. Hit ctrl + c to abort`
    );
    await sleep(10000);
  }

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const address = getAddresses();
  await deploy("OlympusProOptionFactory", {
    from: deployer,
    proxy: {
      owner: deployer,
    },
    args: [
      address.PokeMe,
      (await ethers.getContract("PokeMeResolver")).address,
      address.BondDepositoryV2,
      address.TreasuryV2,
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
func.tags = ["OlympusProOptionFactory"];
func.dependencies = ["PokeMeResolver"];
