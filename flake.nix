{
  description = "Exploring integration between Nix and AI coding agents";
  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
      inputs.treefmt-nix.follows = "treefmt-nix";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs =
    inputs:
    let
      # Override bun with AVX-free baseline binary.
      # Required for systems with pre-AVX CPUs (e.g., Mac Pro 5,1 Xeon E5620).
      # The standard bun binary requires AVX, which crashes both the bun2nix
      # build hook and the qmd runtime wrapper on these systems.
      bunBaselineOverlay = final: prev: {
        bun = prev.bun.overrideAttrs (oldAttrs: {
          src = prev.fetchurl {
            url = "https://github.com/oven-sh/bun/releases/download/bun-v${oldAttrs.version}/bun-linux-x64-baseline.zip";
            hash = "sha256-q+NG9jQUVHzfazW3pkmkkMcouT0AYiYVaSORioTA5Zs=";
          };
        });
      };

      blueprintOutputs = inputs.blueprint {
        inherit inputs;
        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [ bunBaselineOverlay ];
      };

    in
    blueprintOutputs
    // {
      overlays.default = import ./overlays {
        packages = blueprintOutputs.packages;
      };
    };
}
