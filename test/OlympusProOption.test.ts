import { expect } from "chai";
import { Signer } from "ethers";
import hre = require("hardhat");
import { OlympusProOption, PokeMeResolver } from "../typechain";
import { getAddresses } from "../hardhat/deployments";

const { ethers, deployments } = hre;

describe("OlympusProOption", function () {
  this.timeout(0);
  let user: Signer;
  let user2: Signer;
  let option: OlympusProOption;
  let pokeMeResolver: PokeMeResolver;

  beforeEach(async () => {
    await deployments.fixture();
    [user, user2] = await ethers.getSigners();

    option = (await ethers.getContract("OlympusProOption")) as OlympusProOption;

    pokeMeResolver = (await ethers.getContract(
      "PokeMeResolver"
    )) as PokeMeResolver;
  });

  it("#0: should initialized in the creation", async function () {
    const instantFee = await option.connect(user).instantFee();
    expect(ethers.utils.parseEther(instantFee.toString())).to.equal(
      ethers.utils.parseEther("5000000000000000")
    );

    const totalFees = await option.connect(user).totalFees();
    expect(totalFees).to.equal(0);
  });

  it("#1: should set manager correctly", async function () {
    const user2Address = await user2.getAddress();
    const owner = await user.getAddress();
    const marketId = 0;
    const timeBeforeDeadLine = 3600 * 24; // 1 day
    const bcv = 2;
    const pokeMe = getAddresses().PokeMe;
    await option.initialize(
      owner,
      marketId,
      timeBeforeDeadLine,
      bcv,
      pokeMe,
      pokeMeResolver.address
    );
    expect(owner).to.equal(await option.owner());
    await option.connect(user).setManager(user2Address);
    const manager = await option.manager();
    expect(manager).to.equal(user2Address);
  });

  it("#2: should revert when fee is zero", async function () {
    const user2Address = await user2.getAddress();
    const owner = await user.getAddress();
    const marketId = 0;
    const timeBeforeDeadLine = 3600 * 24; // 1 day
    const bcv = 2;
    const pokeMe = getAddresses().PokeMe;
    await option.initialize(
      owner,
      marketId,
      timeBeforeDeadLine,
      bcv,
      pokeMe,
      pokeMeResolver.address
    );
    await option.connect(user).setManager(user2Address);
    await expect(option.connect(user2).setFee(0)).to.be.revertedWith(
      "fee != 0"
    );
  });

  it("#3: should revert when fee is greater that .3 percent", async function () {
    const user2Address = await user2.getAddress();
    const owner = await user.getAddress();
    const marketId = 0;
    const timeBeforeDeadLine = 3600 * 24; // 1 day
    const bcv = 2;
    const pokeMe = getAddresses().PokeMe;
    await option.initialize(
      owner,
      marketId,
      timeBeforeDeadLine,
      bcv,
      pokeMe,
      pokeMeResolver.address
    );
    await option.connect(user).setManager(user2Address);
    await expect(
      option.connect(user2).setFee(ethers.utils.parseUnits("0.4", 18))
    ).to.be.revertedWith("fee >= 30%");
  });

  it("#4: should set fee when call setFee", async function () {
    const user2Address = await user2.getAddress();
    const owner = await user.getAddress();
    const marketId = 0;
    const timeBeforeDeadLine = 3600 * 24; // 1 day
    const bcv = 2;
    const pokeMe = getAddresses().PokeMe;
    await option.initialize(
      owner,
      marketId,
      timeBeforeDeadLine,
      bcv,
      pokeMe,
      pokeMeResolver.address
    );
    await option.connect(user).setManager(user2Address);
    await option.connect(user2).setFee(ethers.utils.parseUnits("0.25", 18));
    const instantFee = await option.instantFee();
    expect(ethers.utils.parseEther(instantFee.toString())).to.equal(
      ethers.utils.parseEther("250000000000000000")
    );
  });

  it("#5: should revert when feeReception is address zero", async function () {
    const user2Address = await user2.getAddress();
    const owner = await user.getAddress();
    const marketId = 0;
    const timeBeforeDeadLine = 3600 * 24; // 1 day
    const bcv = 2;
    const pokeMe = getAddresses().PokeMe;
    await option.initialize(
      owner,
      marketId,
      timeBeforeDeadLine,
      bcv,
      pokeMe,
      pokeMeResolver.address
    );
    await option.connect(user).setManager(user2Address);
    await expect(
      option.connect(user2).setFeeRecipient(ethers.constants.AddressZero)
    ).to.be.revertedWith("!newFeeRecipient");
  });

//   it("#6: should revert when calling getCumulatedFees with feeReception address zero", async function () {
//     const user2Address = await user2.getAddress();
//     const owner = await user.getAddress();
//     const marketId = 0;
//     const timeBeforeDeadLine = 3600 * 24; // 1 day
//     const bcv = 2;
//     const pokeMe = getAddresses().PokeMe;
//     await option.initialize(
//       owner,
//       marketId,
//       timeBeforeDeadLine,
//       bcv,
//       pokeMe,
//       pokeMeResolver.address
//     );
//     await option.connect(user).setManager(user2Address);
//     await expect(
//         option.connect(user2).getCumulatedFees()
//     ).to.be.revertedWith("!newFeeRecipient");
//   });
});
