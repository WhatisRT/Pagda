# Warning: only edit this file if you know what you're doing!
# To customize the build, prefer the optional pagda.nix escape hatch.
{
  description = "Pagda docsAssets example";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    agda-nix = {
      url = "github:input-output-hk/agda.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pagda.url = "github:WhatisRT/pagda";
  };

  outputs = inputs: inputs.pagda.lib.mkFlake { inherit inputs; src = ./.; };
}
