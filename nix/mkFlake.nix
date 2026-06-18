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
in
{
  packages = forAllSystems (
    system:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = [ inputs.agda-nix.overlays.default ];
      };
      plib = pagdaLib.${system};

      # An optional pagda.nix can pin/add dependencies (overlay), customize the
      # build (overrideAttrs) and pick a documentation backend (docs).
      pagdaNix =
        if builtins.pathExists (src + "/pagda.nix")
        then import (src + "/pagda.nix") { inherit pkgs; pagda = plib; }
        else { };

      # The library derivation is derived from the .agda-lib file.
      default = plib.callAgdaLib2nix {
        agdaPackages = pkgs.agdaPackages;
        inherit src;
        overlay = pagdaNix.overlay or null;
        overrideAttrs = pagdaNix.overrideAttrs or (_: { });
      };

      docs = (pagdaNix.docs or (plib.docBackends.enhancedHtml { })) default;
    in
    {
      inherit default docs;
      agda = pkgs.agdaPackages.agda.withPackages (
        builtins.filter (p: p ? isAgdaDerivation) default.buildInputs
      );
    }
  );
}
