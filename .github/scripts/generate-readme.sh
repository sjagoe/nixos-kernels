#!/usr/bin/env bash

cat < .github/README.header.md
cat <<'EOF'

## Included kernels

This project provides the following kernels:

| description | version | arch | package name |
|-------------|---------|------|--------------|
EOF

packages="$(nix eval --json .#packages)"

mapfile -t archs < <(echo "$packages" | jq -er '. | keys | .[]')

description() {
    kernel="$1"
    version="$2"
    if [[ "${kernel}" =~ surface ]]; then
        echo "Linux v$version with surface-linux patches applied"
    else
        if [[ "$version" =~ ^6\.18\. ]]; then
            echo "Linux LTS v$version"
        else
            echo "Linux stable v$version"
        fi
    fi
}

for arch in "${archs[@]}"; do
    mapfile -t kernels < <(echo "$packages" | jq -er --arg arch "$arch" '.[$arch] | keys | .[]')
    for kernel in "${kernels[@]}"; do
        version="$(nix eval --json ".#packages.$arch.$kernel.version" | jq -er .)"
        desc="$(description "$kernel" "$version")"
        echo "| $desc | "'`'"$version"'`'" | "'`'"$arch"'`'" | "'`'"$kernel"'`'" |"
    done
done
