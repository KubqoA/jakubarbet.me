final: prev:
let

in {
  haskellPackages' = prev.haskellPackages.override {
    overrides = hpFinal: hpPrev: {
      site = hpPrev.callCabal2nix "site" ./src {};
    };
  };
}
