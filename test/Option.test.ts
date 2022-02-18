// import { expect } from "chai";
// import { Signer } from "@ethersproject/abstract-signer";
// import hre = require("hardhat");
// import { OptionPoolFactory, OptionPool, TokenA, TokenB } from "../typechain";
// import { getAddresses } from "../hardhat/deployments";
// const { ethers, deployments } = hre;

// describe("Option", function () {
//   this.timeout(0);

//   let user: Signer;
//   let optionPoolFactory: OptionPoolFactory;
//   let tokenA: TokenA;
//   let tokenB: TokenB;

//   beforeEach("setup", async () => {
//     if (hre.network.name !== "hardhat") {
//       console.error("Test Suite is meant to be run on hardhat only");
//       process.exit(1);
//     }

//     await deployments.fixture();

//     [user] = await ethers.getSigners();

//     optionPoolFactory = (await ethers.getContract(
//       "OptionPoolFactory"
//     )) as OptionPoolFactory;
//     tokenA = (await ethers.getContract("TokenA")) as TokenA;
//     tokenB = (await ethers.getContract("TokenB")) as TokenB;
//   });

//   it("#0: Create a Option Pool with the factory", async () => {
//     const short = tokenA.address;
//     const base = tokenB.address;
//     const expiryTime = 3600 * 24 * 30; // 1 month expiry time.
//     const strike = ethers.utils.parseUnits("1000", 18); //
//     const timeBeforeDeadLine = 3600 * 24; // 1 day for exercing.
//     const bcv = ethers.utils.parseUnits("3000", 18); //
//     const initialTotalSupply = ethers.utils.parseUnits("1000000", 18);

//     await tokenB
//       .connect(user)
//       .approve(optionPoolFactory.address, initialTotalSupply);

//     const salt = await optionPoolFactory.getSalt(short, base, expiryTime);

//     await optionPoolFactory.createCallOption(
//       short,
//       base,
//       getAddresses().WETH,
//       expiryTime,
//       strike,
//       timeBeforeDeadLine,
//       bcv,
//       initialTotalSupply
//     );

//     expect(await optionPoolFactory.getCallOptions(salt)).to.be.not.eq(
//       ethers.constants.AddressZero
//     );
//   });

//   it("#1: Add liquidity to Option Pool", async () => {
//     const short = tokenA.address;
//     const base = tokenB.address;
//     const expiryTime = 3600 * 24 * 30; // 1 month expiry time.
//     const strike = ethers.utils.parseUnits("1000", 18); //
//     const timeBeforeDeadLine = 3600 * 24; // 1 day for exercing.
//     const bcv = ethers.utils.parseUnits("3000", 18); //
//     const initialTotalSupply = ethers.utils.parseUnits("1000000", 18);

//     await tokenB
//       .connect(user)
//       .approve(optionPoolFactory.address, initialTotalSupply);

//     const salt = await optionPoolFactory.getSalt(short, base, expiryTime);

//     await optionPoolFactory.createCallOption(
//       short,
//       base,
//       getAddresses().WETH,
//       expiryTime,
//       strike,
//       timeBeforeDeadLine,
//       bcv,
//       initialTotalSupply
//     );

//     const optionPool = (await ethers.getContractAt(
//       "OptionPool",
//       await optionPoolFactory.getCallOptions(salt),
//       user
//     )) as OptionPool;

//     const addend = ethers.utils.parseUnits("2000000", 18);

//     await tokenB.connect(user).approve(optionPool.address, addend);

//     await optionPool.increaseSupply(addend);

//     expect(await tokenB.balanceOf(optionPool.address)).to.be.eq(
//       initialTotalSupply.add(addend)
//     );
//   });

//   it("#2: Create Option from Option Pool", async () => {
//     const short = tokenA.address;
//     const base = tokenB.address;
//     const expiryTime = 3600 * 24 * 30; // 1 month expiry time.
//     const strike = ethers.utils.parseUnits("1000", 18); //
//     const timeBeforeDeadLine = 3600 * 24; // 1 day for exercing.
//     const bcv = ethers.utils.parseUnits("3000", 18); //
//     const initialTotalSupply = ethers.utils.parseUnits("1000000", 18);

//     await tokenB
//       .connect(user)
//       .approve(optionPoolFactory.address, initialTotalSupply);

//     const salt = await optionPoolFactory.getSalt(short, base, expiryTime);

//     await optionPoolFactory.createCallOption(
//       short,
//       base,
//       getAddresses().WETH,
//       expiryTime,
//       strike,
//       timeBeforeDeadLine,
//       bcv,
//       initialTotalSupply
//     );

//     const optionPool = (await ethers.getContractAt(
//       "OptionPool",
//       await optionPoolFactory.getCallOptions(salt),
//       user
//     )) as OptionPool;

//     const addend = ethers.utils.parseUnits("2000000", 18);

//     await tokenB.connect(user).approve(optionPool.address, addend);

//     await optionPool.increaseSupply(addend);

//     expect(await tokenB.balanceOf(optionPool.address)).to.be.eq(
//       initialTotalSupply.add(addend)
//     );

//     const notional = ethers.utils.parseUnits("1000", 18);
//     const premium = await optionPool.getPrice(notional);

//     await tokenA.approve(optionPool.address, premium);
//     const receiver = await user.getAddress();

//     await optionPool.create(notional, receiver);

//     const block = await hre.ethers.provider.getBlock("latest");

//     const newOption = await optionPool.getOptionOfReceiver(
//       receiver,
//       (await optionPool.getNextID(receiver)).sub(1)
//     );

//     expect(newOption.startTime).to.be.eq(block.timestamp);
//     expect(newOption.notional).to.be.eq(notional);
//     expect(newOption.price).to.be.eq(premium);
//     expect(newOption.receiver).to.be.eq(receiver);
//   });
// });
