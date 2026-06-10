{ pkgs ? import <nixpkgs> { } }:

let
  haskellPackages = pkgs.haskellPackages;
  pagda = haskellPackages.callCabal2nix "pagda" ./. { };
in
pkgs.haskell.lib.overrideCabal pagda (drv: {
  # git is invoked by pagda during the end-to-end tests (test/e2e)
  testToolDepends = [ pkgs.git ];
  # The plain Setup.hs used by the nixpkgs builder does not put internal
  # build-tool-depends executables on PATH (cabal-install does), so point
  # the test runner at the freshly built pagda explicitly.
  preCheck = "export PAGDA_BIN=dist/build/pagda/pagda";
})
