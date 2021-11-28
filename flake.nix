{
  description = "Iosevka - custom Muse variant";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat }:
    let
      allSystems = flake-utils.lib.eachDefaultSystem
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};

            plainPackage = pkgs.iosevka.override {
              privateBuildPlan = builtins.readFile ./iosevka-muse.toml;
              set = "muse";
            };

            nerdFontPackage = let outDir = "$out/share/fonts/truetype/"; in
              pkgs.stdenv.mkDerivation {
                pname = "iosevka-muse-nerd-font";
                version = plainPackage.version;

                src = ./.;

                buildInputs = [ pkgs.nerd-font-patcher ];

                configurePhase = "mkdir -p ${outDir}";
                buildPhase = ''
                  for fontfile in ${plainPackage}/share/fonts/truetype/*
                  do
                  nerd-font-patcher $fontfile --complete --careful --outputdir ${outDir}
                  done
                '';
                dontInstall = true;
              };

            packages = {
              normal = plainPackage;
              nerd-font = nerdFontPackage;
            };
          in
          {
            inherit packages;
            defaultPackage = plainPackage;
          }
        );
    in
    {
      packages = allSystems.packages;
      defaultPackage = allSystems.defaultPackage;
      overlay = final: prev: {
        iosevka-muse = allSystems.packages.${final.system}; # either `normal` or `nerd-font`
      };
    };
}
