#!/usr/bin/env bash

set -euo pipefail

log() {
    echo "$*"
} 1>&2

kernels="$(jq . < kernels.json)"

configure_gpg() {
    mkdir -p ~/.gnupg
    chmod go-rwx ~/.gnupg
    cat <<'EOF' > ~/.gnupg/gpg.conf
cert-digest-algo SHA512
default-key 0xD90B6E429FFA9334
default-preference-list SHA512 SHA384 SHA256 SHA224 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
display-charset utf-8
keyid-format 0xlong
keyserver hkps://keyserver.ubuntu.com
list-options show-uid-validity
no-comments
no-emit-version
no-symkey-cache
personal-cipher-preferences AES256 AES192 AES
personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
personal-digest-preferences SHA512 SHA384 SHA256
require-cross-certification
s2k-cipher-algo AES256
s2k-digest-algo SHA512
verify-options show-uid-validity
with-fingerprint
EOF

    # gregkh@kernel.org
    gpg --recv-keys 0x38DBBDC86092693E 1>&2
    gpg --locate-keys gregkh@kernel.org 1>&2
}

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

configure_gpg

mapfile -t VERSIONS < <(echo "$kernels" | jq -er '.versions[]')

# shellcheck disable=SC2016
COMPARE_VERSIONS='
include "semver";
.hashes | keys | .[] | select(. | test($release_r)) as $existing |
$version | cmp_semver($existing) <= 0
'

has_version() {
    local kernels="$1"
    local version="$2"
    local release="$3"

    log "Checking for $version (release $release)"

    echo "$kernels" | jq -er -L./jq \
       --arg release_r "^${release//\./\\.}(\..*)?$" \
       --arg version "$version" \
       "$COMPARE_VERSIONS" >/dev/null
}


for version in "${VERSIONS[@]}"; do
    if ! full_version="$(latest_version "$version")"; then
        log "No kernel release found for ${version}"
        continue
    fi
    if ! echo "$kernels" | has_version "$kernels" "$full_version" "$version"; then
        log "Fetching $full_version"
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
