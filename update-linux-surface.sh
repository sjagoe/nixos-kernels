#!/usr/bin/env bash

set -euo pipefail

METADATA_PATH=surface-kernel/linux-surface.json

log() {
    echo "$*" 1>&2
}

update() {
    local owner=
    local repo=
    local current_rev=
    local current_hash=
    local update_ref=

    owner="$(jq -er .owner < "${METADATA_PATH}")"
    repo="$(jq -er .repo < "${METADATA_PATH}")"
    current_rev="$(jq -er .rev < "${METADATA_PATH}")"
    current_hash="$(jq -er .hash < "${METADATA_PATH}")"
    # Weird way of getting the branch we want to update from the upsteam
    update_ref="$(jq -er '.["upstream-fetch-ref"]' < "${METADATA_PATH}")"

    local new_rev=
    local new_hash=

    update="$(nix-prefetch-git "https://github.com/${owner}/${repo}" --rev "${update_ref}")"
    new_rev="$(echo "$update" | jq -er .rev)"
    new_hash="$(echo "$update" | jq -er .hash)"

    if [[ "$new_rev" == "$current_rev" ]] && [[ "$new_hash" == "$current_hash" ]]; then
        log "No change detected in ${owner}/${repo} $update_ref"
        return 0
    elif [[ "$new_rev" == "$current_rev" ]] && [[ "$new_hash" != "$current_hash" ]]; then
        log "Error: ${owner}/${repo} $update_ref"
        log "Revision remained the same while hash changed!"
        exit 1
    elif [[ "$new_rev" != "$current_rev" ]] && [[ "$new_hash" == "$current_hash" ]]; then
        log "Error: ${owner}/${repo} $update_ref"
        log "Hash remained the same while revision changed!"
        exit 1
    fi

    jq -ne \
       --arg owner "$owner" \
       --arg repo "$repo" \
       --arg rev "$new_rev" \
       --arg hash "$new_hash" \
       --arg ref "$update_ref" \
       '
       {
         "upstream-fetch-ref": $ref,
         "owner": $owner,
         "repo": $repo,
         "rev": $rev,
         "hash": $hash
       }' > "${METADATA_PATH}.tmp"
    mv "${METADATA_PATH}.tmp" "${METADATA_PATH}"

    log "Updated ${owner}/${repo} to upstream $update_ref"
    log "  $current_rev -> $new_rev"
    log "  $current_hash -> $new_hash"
}

update
