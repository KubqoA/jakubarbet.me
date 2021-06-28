{ self, system }:

final: prev: {
  haskellPackages' = prev.haskellPackages.override {
    overrides = hpFinal: hpPrev: {
      buildtools-hakyll = hpPrev.callCabal2nix "buildtools-hakyll" ./buildtools/hakyll {};
    };
  };

  buildtools-css = import ./buildtools/css {
    inherit system;
    pkgs = prev;
  };

  # Wrapper around ‹haskellPackages'.buildtools-hakyll› that sets additional environment
  # variables, so that ‹buildtools-css› can be properly used
  buildtools-hakyll = prev.symlinkJoin {
    name = "buildtools-hakyll";
    paths = with final; [
      haskellPackages'.buildtools-hakyll
      buildtools-css.shell.nodeDependencies
      buildtools-css.package
    ];
    buildInputs = [ prev.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/buildtools-hakyll \
        --set POSTCSS_MODULES "${final.buildtools-css.shell.nodeDependencies}/lib/node_modules" \
        --prefix NODE_PATH : ${final.buildtools-css.shell.nodeDependencies}/lib/node_modules \
        --prefix PATH : ${final.buildtools-css.shell.nodeDependencies}/bin
    '';
  };

  build-site = let
    command = "buildtools-hakyll rebuild";
    paths = with final; [ buildtools-hakyll git ];
    args = map (p: "--prefix PATH : ${p}/bin") paths;
  in prev.runCommand "build-site" {
    f = prev.writeScript "build-site-unwrapped" command;
    buildInputs = [ prev.makeWrapper ];
  } ''
    makeWrapper "$f" "$out"/bin/build-site ${builtins.toString args}
  '';
}
