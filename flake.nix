{
  description = "Iosevka - custom Muse variant";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    (flake-utils.lib.eachDefaultSystem
      (
        system: let
          pkgs = import nixpkgs {inherit system;};

          plainPackage = pkgs.iosevka.override {
            privateBuildPlan = builtins.readFile ./iosevka-muse.toml;
            set = "Muse";
          };

          nerdFontPackage = let
            outDir = "$out/share/fonts/truetype/";
          in
            pkgs.stdenv.mkDerivation {
              pname = "iosevka-muse-nerd-font";
              version = plainPackage.version;

              src = builtins.path {
                path = ./.;
                name = "iosevka-muse";
              };

              buildInputs = [pkgs.nerd-font-patcher];

              configurePhase = "mkdir -p ${outDir}";
              buildPhase = ''
                for fontfile in ${plainPackage}/share/fonts/truetype/*
                do
                nerd-font-patcher $fontfile --complete --careful --outputdir ${outDir}
                done
              '';
              dontInstall = true;
            };
        in {
          packages = {
            default = plainPackage;
            normal = plainPackage;
            nerd-font = nerdFontPackage;
          };
        }
      ))
    // {
      overlay = final: prev: {
        iosevka-muse = self.packages.${final.system}; # either `normal` or `nerd-font`
      };
    };
}
