#!/usr/bin/env python

import argparse
import json
import logging
import os
import subprocess
from pathlib import Path

import requests

logger = logging.getLogger("update-linux-surface")


METADATA = Path(__file__).parent / "surface-kernel/linux-surface.json"


def configure_logging():
    format_ = '%(asctime)s %(levelname)-8.8s [%(name)s:%(lineno)s] %(message)s'
    formatter = logging.Formatter(format_)
    handler = logging.StreamHandler()
    handler.setFormatter(formatter)
    handler.setLevel(logging.INFO)
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)


def prefetch_git(owner, repo, ref):
    url = f"https://github.com/{owner}/{repo}"
    result = subprocess.run(
        ["nix", "run", "nixpkgs#nix-prefetch-git", "--", url, "--rev", ref],
        check=True,
        stdout=subprocess.PIPE,
    )
    return json.loads(result.stdout.decode("utf-8"))


def common_args(parser):
    parser.add_argument(
        "--owner",
        help="Override the repository owner to update from",
    )
    parser.add_argument(
        "--repo",
        help="Override the repository name to update from",
    )
    parser.add_argument(
        "--ref",
        help="Override the ref to update from",
    )


def parse_args():
    parser = argparse.ArgumentParser()
    parser.set_defaults(
        func=lambda *args: parser.error("No command selected"),
    )
    subparsers = parser.add_subparsers()
    ci = subparsers.add_parser(
        "ci",
        help="Update all sources according to their current upstreams",
    )
    ci.set_defaults(
        func=update_ci,
        owner=None,
        repo=None,
        ref=None,
    )

    lts = subparsers.add_parser(
        "update-lts",
        help="Update the LTS linux-surface kernel patch source",
    )
    lts.set_defaults(func=update_lts)
    common_args(lts)

    stable = subparsers.add_parser(
        "update-stable",
        help="Update the Stable linux-surface kernel patch source"
    )
    stable.set_defaults(func=update_stable)
    common_args(stable)

    reset = subparsers.add_parser(
        "reset",
        help="Reset all patch sources to upstream linux-surface master",
    )
    reset.set_defaults(
        func=update_reset,
        owner="linux-surface",
        repo="linux-surface",
        ref="refs/heads/master",
    )

    return parser.parse_args()


def update_kernel(ns, meta):
    owner = ns.owner or meta["owner"]
    repo = ns.repo or meta["repo"]
    ref = ns.ref or meta["upstream-fetch-ref"]
    current_rev = meta["rev"]
    current_hash = meta["hash"]
    if not ref.startswith("refs/"):
        ref = f"refs/heads/{ref}"

    update = prefetch_git(owner, repo, ref)
    new_rev = update["rev"]
    new_hash = update["hash"]

    if new_rev == current_rev and new_hash == current_hash:
        logger.info("No changes to %s/%s %s", owner, repo, ref)
        return meta
    elif new_rev != current_rev and new_hash == current_hash:
        logger.error("%s/%s %s: Revision changed without a hash change",
                     owner, repo, ref)
        exit(1)
    elif new_rev == current_rev and new_hash != current_hash:
        logger.error("%s/%s %s: Hash changed without a revision change",
                     owner, repo, ref)
        exit(1)

    return {
        "upstream-fetch-ref": ref,
        "owner": owner,
        "repo": repo,
        "rev": new_rev,
        "hash": new_hash,
    }


def write_metadata(old_value, new_value):
    if old_value != new_value:
        tmp = METADATA.with_suffix('.json.tmp')
        tmp.write_text(f"{json.dumps(new_value, indent=2)}\n")
        tmp.rename(METADATA)
    else:
        logger.info("No changes detected")


def kernel_releases():
    releases = json.loads(Path("kernels.json").read_text())["versions"]

    ordered = list(sorted(([int(i) for i in r.split(".")], r) for r in releases))
    lts = ordered[0][1]
    stable = ordered[-1][1]

    return lts, stable


def files_in_diff(owner, repo, old_rev, new_rev):
    api_root = f"https://api.github.com/repos/{owner}/{repo}"
    api_url = f"{api_root}/compare/{old_rev}...{new_rev}"

    headers = {"Accept": "application/vnd.github+json"}

    token = os.getenv("GITHUB_TOKEN")
    if token is not None:
        headers["Authorization"] = f"Bearer {token}"

    resp = requests.get(api_url, headers=headers)
    resp.raise_for_status()

    data = resp.json()
    return [file["filename"] for file in data["files"]]


def revisions_changed(old_meta, new_meta, release):
    if (
            old_meta["owner"] != new_meta["owner"] or
            old_meta["repo"] != new_meta["repo"]
    ):
        return True

    owner = old_meta["owner"]
    repo = old_meta["repo"]
    old_rev = old_meta["rev"]
    new_rev = new_meta["rev"]
    return any(f.startswith(f"patches/{release}/")
               for f in files_in_diff(owner, repo, old_rev, new_rev))


def check_patches_changed(old_metadata, new_metadata):
    lts_release, stable_release = kernel_releases()
    if revisions_changed(
            old_metadata["lts"],
            new_metadata["lts"],
            lts_release,
    ):
        return True
    return False


def update_ci(ns, metadata):
    new_metadata = {
        "lts": update_kernel(ns, metadata["lts"]),
    }
    if metadata["stable"] is not None:
        new_metadata["stable"] = update_kernel(ns, metadata["stable"])
    else:
        new_metadata["stable"] = None

    if check_patches_changed(metadata, new_metadata):
        write_metadata(metadata, new_metadata)
    else:
        logger.info("Patches have not changed between revisions")


def update_lts(ns, metadata):
    new_metadata = {
        "lts": update_kernel(ns, metadata["lts"]),
        "stable": metadata["stable"],
    }
    write_metadata(metadata, new_metadata)


def update_stable(ns, metadata):
    stable_meta = metadata["stable"]
    if (
            stable_meta is None and ns.owner is None
            and ns.repo is None and ns.ref is None
    ):
        logger.error(
            "LTS and Stable are on the same source. "
            "To change that, pass at least one of "
            "--owner, --repo or --ref",
        )
        exit(1)

    if stable_meta is None:
        stable_meta = metadata["lts"]
    new_metadata = {
        "lts": metadata["lts"],
        "stable": update_kernel(ns, stable_meta),
    }
    write_metadata(metadata, new_metadata)


def update_reset(ns, metadata):
    new_metadata = {
        "lts": update_kernel(ns, metadata["lts"]),
        "stable": None,
    }
    write_metadata(metadata, new_metadata)


def main():
    configure_logging()
    ns = parse_args()
    metadata = json.loads(METADATA.read_text())
    ns.func(ns, metadata)


if __name__ == '__main__':
    main()
