{
  description = "Simple template using agda.nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";

    agda-nix = {
      url = "github:input-output-hk/agda.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pagda = {
      url = "./pagda.nix";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    let
      inherit (nixpkgs) lib;
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            inputs.agda-nix.overlays.default
          ];
        };

        pagda = import inputs.pagda { agdaPackages = pkgs.agdaPackages; };
      in
      {
        packages = pagda;
        # devShells.default = pkgs.mkShell {
        #   packages = [
        #     (pkgs.agdaPackages.agda.withPackages (
        #       builtins.filter (p: p ? isAgdaDerivation) simple-library.buildInputs
        #     ))
        #   ];
        # };
      }
    );
}
