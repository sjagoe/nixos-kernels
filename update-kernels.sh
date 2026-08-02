#!/usr/bin/env bash

set -euo pipefail

kernels="$(jq . < kernels.json)"

fetch_kernel() {
    local full_version="$1"
    local major="${full_version//.*/}"
    local xfilename="linux-${full_version}.tar"
    local filename="${xfilename}.xz"
    local url="https://cdn.kernel.org/pub/linux/kernel/v${major}.x/linux-${full_version}.tar.xz"

    curl -fsSL -o "$filename" "$url"
    unxz < "$filename" > "$xfilename"

    local signfile="${xfilename}.sign"
    local signurl="https://cdn.kernel.org/pub/linux/kernel/v${major}.x/${signfile}"

    gpg --locate-keys gregkh@kernel.org 1>&2

    curl -fsSL -o "$signfile" "$signurl"

    gpg --quiet --verify "$signfile" 1>&2

    rm "$xfilename" "$signfile"

    readlink -f "$filename"
}

latest_version() {
    local version="$1"
    local major="${version//.*/}"
    local versions=
    versions="$(curl -fsSL "https://cdn.kernel.org/pub/linux/kernel/v${major}.x/" | grep 'a href="ChangeLog' | cut -d'"' -f2 | cut -d- -f2 | grep "^${version//./\\.}\(\.\|$\)")"
    if [[ "$versions" == "" ]]; then
        return 1
    fi
    echo "$versions" 1>&2
    patch="$(echo "$versions" | cut -d. -f3 | sort -n | tail -n1)"
    if [[ "$patch" == "" ]]; then
        # We've hit the initial release of the series, which is only MAJOR.MINOR without a patch
        echo "$version"
    else
        echo "${version}.${patch}"
    fi
}

mapfile -t VERSIONS < <(echo "$kernels" | jq -er '.versions[]')

for version in "${VERSIONS[@]}"; do
    if ! full_version="$(latest_version "$version")"; then
        echo "No kernel release found for ${version}"
        continue
    fi
    echo "Checking $full_version"
    if ! echo "$kernels" | jq -e --arg version "$full_version" '.hashes | has($version)' > /dev/null; then
        echo "Fetching $full_version"
        major="${full_version//.*/}"
        path="$(fetch_kernel "$full_version")"
        hash="$(nix-prefetch-url "file://${path}")"
        hash="$(nix hash convert --hash-algo sha256 --from nix32 "$hash")"

        kernels="$(echo "$kernels" | jq -e --arg oldrelease "${version//\./\\.}" \
          '.hashes = (.hashes | to_entries | [.[] | select(.key | test("^\($oldrelease)\\.") | not)] | from_entries)')"
        kernels="$(echo "$kernels" | jq -e --arg version "$full_version" --arg hash "$hash" '.hashes[$version] = $hash')"
    fi
done

echo "$kernels" | jq -e --sort-keys . > kernels.json.tmp
mv kernels.json.tmp kernels.json
