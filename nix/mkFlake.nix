# The flake outputs for a pagda project, derived from its inputs and source.
#
# A generated project flake.nix is a thin caller of this so the build
# logic lives in pagda and projects pick up improvements by updating
# their `pagda` input.
#
# `pagdaLib` is pagda's own per-system lib and `systems` the systems
# to build for; both are bound by pagda's flake. The project supplies
# its `inputs` (nixpkgs + agda-nix, plus pagda) and `src`:
#
#     outputs = inputs: inputs.pagda.lib.mkFlake { inherit inputs; src = ./.; };
{ pagdaLib, systems }:

{ inputs, src }:

let
  forAllSystems = inputs.nixpkgs.lib.genAttrs systems;

  perSystem =
    system:
    let
      plib = pagdaLib.${system};

      # Import pagda.nix (if present) with the given pkgs and pagda argument.
      importPagdaNix = pkgs': pagda:
        if builtins.pathExists (src + "/pagda.nix")
        then import (src + "/pagda.nix") { pkgs = pkgs'; inherit pagda; }
        else { };

      # First pass: read only nixpkgs.{config,overlays}, which configure how
      # pkgs itself is built and so must not reference pkgs (poisoned here to
      # catch that) or the project's packages.
      nixpkgsCfg = importPagdaNix
        (throw "pagda.nix: nixpkgs.config and nixpkgs.overlays must not reference pkgs")
        plib;

      pkgs = import inputs.nixpkgs {
        inherit system;
        config = nixpkgsCfg.nixpkgs.config or { };
        overlays = [ inputs.agda-nix.overlays.default ] ++ (nixpkgsCfg.nixpkgs.overlays or [ ]);
      };

      # Second pass with the real pkgs. An optional pagda.nix can: configure the
      # nixpkgs import (nixpkgs.config / nixpkgs.overlays, read above), pin/add
      # dependencies (overlay), set package metadata (meta), customize the build
      # (overrideAttrs), pick a documentation backend (docs) and define dev
      # shells (devShells). `pagda` is pagda's per-system lib augmented with this
      # project's `default` and `agda` packages (so dev shells can pull them in).
      pagdaNix = importPagdaNix pkgs (plib // { inherit default agda; });

      # The library derivation is derived from the .agda-lib file, then given the
      # project's metadata.
      default = (plib.callAgdaLib2nix {
        agdaPackages = pkgs.agdaPackages;
        inherit src;
        overlay = pagdaNix.overlay or null;
        overrideAttrs = pagdaNix.overrideAttrs or (_: { });
      }).overrideAttrs (old: {
        meta = (old.meta or { }) // (pagdaNix.meta or { });
      });

      agda = pkgs.agdaPackages.agda.withPackages (
        builtins.filter (p: p ? isAgdaDerivation) default.buildInputs
      );

      docs = (pagdaNix.docs or (plib.docBackends.enhancedHtml { })) default;
    in
    {
      packages = { inherit default docs agda; };

      # devShells.default is the agda dev environment (agda + the project's
      # dependencies) that `pagda shell` and `pagda check` use; pagda.nix may
      # add more shells or override `default` (keep agda available, e.g. with
      # inputsFrom = [ pagda.default ]).
      devShells =
        { default = pkgs.mkShell { inputsFrom = [ default ]; }; }
        // (pagdaNix.devShells or { });
    };

  bySystem = forAllSystems perSystem;
in
{
  packages = builtins.mapAttrs (_: v: v.packages) bySystem;
  devShells = builtins.mapAttrs (_: v: v.devShells) bySystem;
}
