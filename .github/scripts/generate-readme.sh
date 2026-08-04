#!/usr/bin/env bash

cat <<'EOF'
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
EOF

packages="$(nix eval --json .#packages)"

mapfile -t archs < <(echo "$packages" | jq -er '. | keys | .[]')

description() {
    kernel="$1"
    version="$2"
    if [[ "${kernel}" =~ surface ]]; then
        echo "Linux v$version with surface-linux patches applied"
    else
        echo "Mainline Linux v$version"
    fi
}

for arch in "${archs[@]}"; do
    mapfile -t kernels < <(echo "$packages" | jq -er --arg arch "$arch" '.[$arch] | keys | .[]')
    for kernel in "${kernels[@]}"; do
        attrib=".#packages.$arch.$kernel"
        version="$(nix eval --json "${attrib}.version" | jq -er .)"
        desc="$(description "$kernel" "$version")"
        echo "| $arch | $version | $desc | $attrib |"
    done
done
