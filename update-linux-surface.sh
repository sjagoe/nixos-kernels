#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC2016
AWK_SCRIPT='BEGIN { found = 0; matched = ""; }
{
  if ($0 ~ /^  linux-surface = pkgs.fetch/) {
    found = 1;
  };
  if (found == 1) {
    matched = matched "\n" $0;
  };
  if (found == 1 && $0 ~ /^  \};$/) {
    found = 0;
  }
}
END { print matched; }'

MATCH="$(awk "$AWK_SCRIPT" < surface-kernel/default.nix)"

pkg_value() {
    local name="$1"

    echo "$MATCH" | grep "^ \+${name} *=" | sed -e "s/^ \+${name} *= *"'"'"\([^"'"'"]\+\)"'"'";$/\1/"
}

log() {
    echo "$*" 1>&2
}

update() {
    local owner=
    owner="$(pkg_value owner)"
    local repo=
    repo="$(pkg_value repo)"
    local current_rev=
    current_rev="$(pkg_value rev)"
    local current_hash=
    current_hash="$(pkg_value hash)"
    # Weird way of getting the branch we want to update from the upsteam
    local update_branch=
    update_branch="$(pkg_value "# branch")"

    local new_rev=
    local new_hash=

    update="$(nix-prefetch-git "https://github.com/${owner}/${repo}" --rev "refs/heads/${update_branch}")"
    new_rev="$(echo "$update" | jq -er .rev)"
    new_hash="$(echo "$update" | jq -er .hash)"

    if [[ "$new_rev" == "$current_rev" ]] && [[ "$new_hash" == "$current_hash" ]]; then
        log "No change detected in ${owner}/${repo} $update_branch"
        return 1
    elif [[ "$new_rev" == "$current_rev" ]] && [[ "$new_hash" != "$current_hash" ]]; then
        log "Error: ${owner}/${repo} $update_branch"
        log "Revision remained the same while hash changed!"
        exit 2
    elif [[ "$new_rev" != "$current_rev" ]] && [[ "$new_hash" == "$current_hash" ]]; then
        log "Error: ${owner}/${repo} $update_branch"
        log "Hash remained the same while revision changed!"
        exit 2
    fi

    sed -i \
        -e "s/\(^ \+rev\).*;$/\1 = \"${new_rev}\";/" \
        -e "s/\(^ \+hash\).*;$/\1 = \"${new_hash}\";/" \
        surface-kernel/default.nix

    log "Updated ${owner}/${repo} to upstream $update_branch"
    log "  $current_rev -> $new_rev"
    log "  $current_hash -> $new_hash"
}

update
