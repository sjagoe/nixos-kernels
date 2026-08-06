# NixOS mainline kernels

Kernels built from kernel.org sources.

## Usage

Binaries are available from the `nixos-kernels` cachix.org cache.

Add the follwing to your `nix.conf`:

```
extra-substituters = https://nixos-kernels.cachix.org
extra-trusted-public-keys = nixos-kernels.cachix.org-1:RIMUFtH7hjB2skf7CYu5yy+4zsd3uEVsR+2OprRtKdQ=
```

Add this repository to your flake inputs

```
{
  ...
  inputs = {
    ...
    nixos-kernels.url = "github:sjagoe/nixos-kernels";
    nixos-kernels.inputs.nixpkgs.follows = "nixpkgs";
    ...
  };

  outputs = { ... }@inputs: {
    ...
    nixosConfigurations.hosts.hostname.specialArgs = { inherit inputs; };
  };
}
```

And in your host configuration, set the appropriate kernel packages:

```
{ config, pkgs, lib, inputs, ... }:

{
  config.boot.kernelPackages = pkgs.linuxPackagesFor inputs.nixos-kernels.packages.${pkgs.stdenv.hostPlatform.system}.linux_7_1;
}
```


## Included kernels

This project provides the following kernels:

| description | version | arch | package name |
|-------------|---------|------|--------------|
| Linux LTS v6.18.43 | `6.18.43` | `aarch64-linux` | `linux_6_18` |
| Linux stable v7.1.7 | `7.1.7` | `aarch64-linux` | `linux_7_1` |
| Linux v6.18.43 with surface-linux patches applied | `6.18.43` | `x86_64-linux` | `linux-surface_6_18` |
| Linux LTS v6.18.43 | `6.18.43` | `x86_64-linux` | `linux_6_18` |
| Linux stable v7.1.7 | `7.1.7` | `x86_64-linux` | `linux_7_1` |
