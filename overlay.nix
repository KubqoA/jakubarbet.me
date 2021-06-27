final: prev:
let
  pkgs = prev;
in {
  haskellPackages' = prev.haskellPackages.override {
    overrides = hpFinal: hpPrev: rec {
      hakyll-gen = hpPrev.callCabal2nix "hakyll-gen" ./hakyll-gen {};

      site = pkgs.stdenv.mkDerivation {
        name = "site";
        buildInputs = [ hakyll-gen ];
        src = pkgs.nix-gitignore.gitignoreSourcePure [
          ./.gitignore
          # Ignored files cannot be referenced via a path, but via string
          ".git"
          ".direnv"
        ] ./.;

        LANG = "en_US.UTF-8";

        buildPhase = ''
          hakyll-gen build --verbose
        '';

        installPhase = ''
          mkdir -p "$out/dist"
          cp -r dist/* "$out/dist"
        '';
      };
    };
  };
}
