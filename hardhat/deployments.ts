export interface Addresses {
  PokeMe: string;
}

export const getAddresses = (network: string): Addresses => {
  return {
    PokeMe: "0xB3f5503f93d5Ef84b06993a1975B9D21B962892F",
  };
};
