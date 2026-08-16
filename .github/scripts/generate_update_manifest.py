#!/usr/bin/env python3
"""Build Syncy's versioned, integrity-protected update manifest."""

import argparse
import hashlib
import json
from pathlib import Path


def artifact(path: Path) -> dict[str, object]:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return {
        "asset": path.name,
        "sha256": digest.hexdigest(),
        "size": path.stat().st_size,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", required=True)
    parser.add_argument("--android", required=True, type=Path)
    parser.add_argument("--windows", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    for path in (args.android, args.windows):
        if not path.is_file() or path.stat().st_size == 0:
            raise SystemExit(f"Release artifact is missing or empty: {path}")

    manifest = {
        "protocol": 1,
        "version": args.version,
        "platforms": {
            "android": artifact(args.android),
            "windows": artifact(args.windows),
        },
    }
    args.output.write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
