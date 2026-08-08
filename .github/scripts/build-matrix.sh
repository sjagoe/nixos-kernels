#!/usr/bin/env bash

set -euo pipefail

echo "Store paths to build"
nix eval --json .#packages | jq .
echo "===="
builds="$(nix eval --json .#ci.build)"

valid_builds='[]'

CACHES=(
    cache.nixos.org
    nixos-kernels.cachix.org
)

exists_in_cache() {
    hash="$1"
    for cache in "${CACHES[@]}"; do
        if curl -o/dev/null -fsSL "https://${cache}/${hash}.narinfo"; then
            return 0
        fi
    done
    return 1
}

declare -a hashes
hashes=()
count="$(echo "$builds" | jq -e '. | length')"
for ((ix=0; ix<count; ix++)); do
    mapfile -t hashes < <(echo "$builds" | jq -er --argjson ix "$ix" '.[$ix].outputHashes[]')
    for hash in "${hashes[@]}"; do
        if ! exists_in_cache "$hash"; then
            valid_builds="$(echo "$valid_builds" | jq -e --argjson ix "$ix" --argjson builds "$builds" '. + [$builds[$ix]]')"
            break
        fi
    done
done

builds_in_matrix="$(echo "$valid_builds" | jq '. | length')"
if [ "$builds_in_matrix" -eq 0 ]; then
    continue_build=false
else
    continue_build=true
fi

matrix="$(echo "$valid_builds" | jq -e '[.[] | del(.paths) | del(.outputHashes)]')"
separator="matrix-$RANDOM"
{
    echo "continue=${continue_build}"
    echo "matrix<<$separator"
    echo "$matrix" | jq -e .
    echo "$separator"
} >> "$GITHUB_OUTPUT"
cat "$GITHUB_OUTPUT"
