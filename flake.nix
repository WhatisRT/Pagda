{
  description = "Pagda, the package manager for Agda";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        # Built without the test suites so installs are fast and robust.
        pagda = import ./default.nix { inherit pkgs; };
        default = pagda;
      });

      apps = forAllSystems (pkgs: rec {
        pagda = {
          type = "app";
          program = nixpkgs.lib.getExe (import ./default.nix { inherit pkgs; });
        };
        default = pagda;
      });

      # An overlay so downstream flakes / NixOS / home-manager configs can pull
      # pagda into their package set: `overlays = [ pagda.overlays.default ]`.
      overlays.default = final: prev: {
        pagda = import ./default.nix { pkgs = final; };
      };

      # Per-system helpers: callAgdaLib2nix builds an Agda library derivation
      # straight from its .agda-lib file (the callCabal2nix analogue), and
      # docBackends are the documentation builders. mkFlake (system-agnostic)
      # assembles a whole project's flake outputs from these; generated project
      # flakes delegate to it.
      lib =
        let
          perSystem = forAllSystems (pkgs: {
            callAgdaLib2nix = import ./nix/callAgdaLib2nix.nix {
              inherit pkgs;
              pagda = import ./default.nix { inherit pkgs; };
            };
            docBackends = rec {
              html = import ./nix/docBackends/html.nix { inherit pkgs; };
              enhancedHtml = import ./nix/docBackends/enhancedHtml.nix {
                inherit pkgs;
                htmlBackend = html;
                agdaDocs = import ./nix/agda-web-docs-lib.nix { inherit pkgs; };
              };
            };
          });
        in
        perSystem // {
          mkFlake = import ./nix/mkFlake.nix {
            pagdaLib = perSystem;
            inherit systems;
          };
        };

      # `nix flake check` builds pagda and runs its test suites,
      # including the end-to-end tests in test/e2e.
      checks = forAllSystems (pkgs: {
        pagda = import ./default.nix {
          inherit pkgs;
          doCheck = true;
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          inputsFrom = [ (import ./default.nix { inherit pkgs; }).env ];
          packages = [
            pkgs.cabal-install
            pkgs.git
          ];
        };
      });
    };
}
