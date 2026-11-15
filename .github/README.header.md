# NixOS mainline kernels

Kernels built from kernel.org sources.

## Usage

Binaries are available from the `nixos-surface-kernel` cachix.org cache.

Example flake configuration using `nixos-surface-kernel`:

```
{
  description = "NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://nixos-surface-kernel.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-surface-kernel.cachix.org-1:0NRj1XcsGihDlexYdGuRHrxP+yX8o15HUTvk4m6yGVk="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixos-surface-kernel.url = "github:sjagoe/nixos-surface-kernel";
    nixos-surface-kernel.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, nixos-surface-kernel, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          nixos-surface-kernel.nixosModules.default
          ({ config, pkgs, ... }: {
            nixos-surface-kernel.enable = true;
            nixos-surface-kernel.package = nixos-surface-kernel.packages.${pkgs.stdenv.hostPlatform.system}.linux-surface_7_3;
          })
        ];
      };
    };
  };
}
```
