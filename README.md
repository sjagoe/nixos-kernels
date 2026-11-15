# NixOS linux-surface kernels

Kernels built from kernel.org sources for MS Surface.

This flake also passes through the latest LTS and Stable kernels from
nixos-26.05-small.

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

## Included kernels

This project provides the following kernels:

| description | version | arch | package name |
|-------------|---------|------|--------------|
| Linux LTS v6.18.63 | `6.18.63` | `aarch64-linux` | `linux_6_18` |
| Linux stable v7.3.4 | `7.3.4` | `aarch64-linux` | `linux_7_3` |
| Linux v6.18.63 with surface-linux patches applied | `6.18.63` | `x86_64-linux` | `linux-surface_6_18` |
| Linux v7.3.4 with surface-linux patches applied | `7.3.4` | `x86_64-linux` | `linux-surface_7_3` |
| Linux LTS v6.18.63 | `6.18.63` | `x86_64-linux` | `linux_6_18` |
| Linux stable v7.3.4 | `7.3.4` | `x86_64-linux` | `linux_7_3` |
