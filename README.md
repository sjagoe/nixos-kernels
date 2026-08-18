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

## Included kernels

This project provides the following kernels:

| description | version | arch | package name |
|-------------|---------|------|--------------|
| Linux LTS v6.18.44 | `6.18.44` | `aarch64-linux` | `linux_6_18` |
| Linux stable v7.1.8 | `7.1.8` | `aarch64-linux` | `linux_7_1` |
| Linux stable v7.2 | `7.2` | `aarch64-linux` | `linux_7_2` |
| Linux v6.18.44 with surface-linux patches applied | `6.18.44` | `x86_64-linux` | `linux-surface_6_18` |
| Linux LTS v6.18.44 | `6.18.44` | `x86_64-linux` | `linux_6_18` |
| Linux stable v7.1.8 | `7.1.8` | `x86_64-linux` | `linux_7_1` |
| Linux stable v7.2 | `7.2` | `x86_64-linux` | `linux_7_2` |
