# NixOS mainline kernels

Kernels built from kernel.org sources.

## Usage

Binaries are available from the `nixos-kernels` cachix.org cache.

Example flake configuration using `nixos-kernels`:

```
{
  description = "NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://nixos-kernels.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-kernels.cachix.org-1:RIMUFtH7hjB2skf7CYu5yy+4zsd3uEVsR+2OprRtKdQ="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixos-kernels.url = "github:sjagoe/nixos-kernels";
    nixos-kernels.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, nixos-kernels, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          nixos-kernels.nixosModules.nixos-kernels
          ({ config, pkgs, ... }: {
            nixos-kernels.enable = true;
            nixos-kernels.package = nixos-kernels.packages.${pkgs.stdenv.hostPlatform.system}.linux_7_1;
          })
        ];
      };
    };
  };
}
```
