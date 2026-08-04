# NixOS mainline kernels

Kernels built from kernel.org sources.

## Usage

Binaries are available from the `nixos-kernels` cachix.org cache.

Add the follwing to your `nix.conf`:

```
extra-substituters = https://nixos-kernels.cachix.org
extra-trusted-public-keys = nixos-kernels.cachix.org-1:RIMUFtH7hjB2skf7CYu5yy+4zsd3uEVsR+2OprRtKdQ=
```


## Included kernels

This project provides the following kernels:

| arch | version | description | attribute |
|------|---------|-------------|-----------|
| aarch64-linux | 6.18.42 | Mainline Linux v6.18.42 | .#packages.aarch64-linux.linux_6_18 |
| aarch64-linux | 7.1.6 | Mainline Linux v7.1.6 | .#packages.aarch64-linux.linux_7_1 |
| x86_64-linux | 6.18.42 | Linux v6.18.42 with surface-linux patches applied | .#packages.x86_64-linux.linux-surface_6_18 |
| x86_64-linux | 6.18.42 | Mainline Linux v6.18.42 | .#packages.x86_64-linux.linux_6_18 |
| x86_64-linux | 7.1.6 | Mainline Linux v7.1.6 | .#packages.x86_64-linux.linux_7_1 |
