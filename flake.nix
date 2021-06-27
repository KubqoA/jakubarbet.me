{
  description = "jakubarbet.me";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.05";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { flake-utils, nixpkgs, self }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        haskellPackagesOverlay = import ./overlay.nix;
        overlays = [ haskellPackagesOverlay ];
        pkgs = import nixpkgs { inherit system overlays; };

        inherit (pkgs.haskellPackages) callCabal2nix; 
        inherit (pkgs.stdenv) mkDerivation;
      in rec {
        packages = { inherit (pkgs.haskellPackages') hakyll-gen site; };
        defaultPackage = packages.site;

        apps.site = flake-utils.lib.mkApp {
          drv = packages.generator;
          exePath = "/bin/hakyll-gen";
        };
        defaultApp = apps.site;

        devShell = pkgs.haskellPackages'.shellFor {
          packages = hp': [ hp'.hakyll-gen ];

          buildInputs = with pkgs.haskellPackages'; [
            hakyll-gen
            ghcid
            haskell-language-server
            hlint
            ormolu
          ];

          withHoogle = true;
        };
      });
}
