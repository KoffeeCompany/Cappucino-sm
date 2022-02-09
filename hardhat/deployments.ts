export interface Addresses {
  /* eslint-disable @typescript-eslint/naming-convention */
  PokeMe: string;
  WETH: string;
  /* eslint-enable @typescript-eslint/naming-convention */
}

export const getAddresses = (): Addresses => {
  return {
    PokeMe: "0xB3f5503f93d5Ef84b06993a1975B9D21B962892F",
    WETH: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2",
  };
};
