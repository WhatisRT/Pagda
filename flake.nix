{
  description = "Pagda, the package manager for Agda";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
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
        pagda = import ./default.nix { inherit pkgs; };
        default = pagda;
      });

      # `nix flake check` builds pagda and runs its test suites,
      # including the end-to-end tests in test/e2e.
      checks = forAllSystems (pkgs: {
        pagda = import ./default.nix { inherit pkgs; };
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
