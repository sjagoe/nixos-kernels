#!/usr/bin/env python

import json
import re

import feedparser
import semver


rc = re.compile(r'^\d+\.\d+(.\d+)?$')


def parse_id(id):
    _, _, version, _ = id.split(",")
    if rc.match(version) is None:
        return None
    ver = semver.Version.parse(version)
    release = f"{ver.major}.{ver.minor}"
    return release, version


def main():
    feed = feedparser.parse("https://www.kernel.org/feeds/kdist.xml")

    items = [parse_id(item["id"]) for item in feed["entries"]]
    versions = dict(i for i in items if i is not None)
    print(json.dumps(versions, sort_keys=True, indent=2))


if __name__ == '__main__':
    main()
