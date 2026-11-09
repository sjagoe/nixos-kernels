#!/usr/bin/env python

import argparse
import json
import logging
import subprocess
from pathlib import Path

logger = logging.getLogger("update-linux-surface")


METADATA = Path(__file__).parent / "surface-kernel/linux-surface.json"


def configure_logging():
    format_ = '%(asctime)s %(levelname)-8.8s [%(name)s:%(lineno)s] %(message)s'
    formatter = logging.Formatter(format_)
    handler = logging.StreamHandler()
    handler.setFormatter(formatter)
    handler.setLevel(logging.INFO)
    logger = logging.getLogger('random-ipv6')
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)


def prefetch_git(owner, repo, ref):
    url = f"https://github.com/{owner}/{repo}"
    result = subprocess.run(
        ["nix-prefetch-git", url, "--rev", ref],
        check=True,
        stdout=subprocess.PIPE,
    )
    return json.loads(result.stdout.decode("utf-8"))


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--owner")
    parser.add_argument("--repo")
    parser.add_argument("--ref")

    return parser.parse_args()


def main():
    configure_logging()
    ns = parse_args()

    meta = json.loads(METADATA.read_text())

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
        return
    elif new_rev != current_rev and new_hash == current_hash:
        logger.error("%s/%s %s: Revision changed without a hash change",
                     owner, repo, ref)
        exit(1)
    elif new_rev == current_rev and new_hash != current_hash:
        logger.error("%s/%s %s: Hash changed without a revision change",
                     owner, repo, ref)
        exit(1)

    new_data = {
        "upstream-fetch-ref": ref,
        "owner": owner,
        "repo": repo,
        "rev": new_rev,
        "hash": new_hash,
    }
    tmp = METADATA.with_suffix('.json.tmp')
    tmp.write_text(f"{json.dumps(new_data, indent=2)}\n")
    tmp.rename(METADATA)


if __name__ == '__main__':
    main()
