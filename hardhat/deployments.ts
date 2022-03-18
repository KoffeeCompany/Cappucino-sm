export interface Addresses {
  /* eslint-disable @typescript-eslint/naming-convention */
  PokeMe: string;
  WETH: string;
  GELETHGUNILP: string;
  GEL: string;
  TreasuryV2: string;
  BondDepositoryV2: string;
  /* eslint-enable @typescript-eslint/naming-convention */
}

export const getAddresses = (): Addresses => {
  return {
    PokeMe: "0xB3f5503f93d5Ef84b06993a1975B9D21B962892F",
    WETH: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
    GELETHGUNILP: "0xd33669d0a6eb343b8d7643dc270b99116e900e64",
    GEL: "0x15b7c0c907e4C6b9AdaAaabC300C08991D6CEA05",
    TreasuryV2: "0x9A315BdF513367C0377FB36545857d12e85813Ef",
    BondDepositoryV2: "0x9025046c6fb25Fb39e720d97a8FD881ED69a1Ef6"
  };
};
