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
        overlay = import ./overlay.nix { inherit self system; };
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };

        inherit (pkgs.haskellPackages) callCabal2nix; 
        inherit (pkgs.stdenv) mkDerivation;
      in rec {
        packages = {
          inherit (pkgs) buildtools-css buildtools-hakyll build-site;
        };
        defaultPackage = packages.build-site;

        apps.build-site = flake-utils.lib.mkApp {
          drv = packages.build-site;
        };
        defaultApp = apps.build-site;

        devShell = pkgs.haskellPackages'.shellFor {
          packages = hp': [ hp'.buildtools-hakyll ];

          buildInputs = (with pkgs; [
            buildtools-hakyll
            git
          ]) ++ (with pkgs.haskellPackages'; [
            ghcid
            haskell-language-server
            hlint
            ormolu
          ]);

          withHoogle = true;

          shellHook = ''
            export POSTCSS_MODULES="${pkgs.buildtools-css.shell.nodeDependencies}/lib/node_modules" \
            export NODE_PATH="$NODE_PATH:${pkgs.buildtools-css.shell.nodeDependencies}/lib/node_modules" \
            export PATH="$PATH:${pkgs.buildtools-css.shell.nodeDependencies}/bin"
          '';
        };
      });
}
