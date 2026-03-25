{ pkgs ? import <nixpkgs> { } }:

let
  haskellPackages = pkgs.haskellPackages;
in
  haskellPackages.callCabal2nix "pagda" ./. { }
