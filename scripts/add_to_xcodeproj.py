#!/usr/bin/env python3
"""
Add Swift / Metal / resource files to nagi.xcodeproj/project.pbxproj.

Why this exists:
  The project is pre-Xcode-15 (objectVersion 56, no File System Synchronized Groups).
  Creating a file on disk does NOT add it to the build — it silently becomes orphan.
  Existing repo already has 5 orphan .metal files (FractalShader, KaleidoscopeShader,
  OrbsShader, ParticlesShader, SlimeShader, WavesShader) as evidence.

Usage:
  python3 scripts/add_to_xcodeproj.py <file_path> [<file_path> ...] [--group <GroupName>]
  python3 scripts/add_to_xcodeproj.py --sync                # sync all on-disk files under nagi/ into the project

Examples:
  python3 scripts/add_to_xcodeproj.py nagi/Sensory/SensoryScene.swift --group Sensory
  python3 scripts/add_to_xcodeproj.py nagi/Shaders/CampfireShader.metal --group Shaders
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

try:
    from pbxproj import XcodeProject
except ImportError:
    print("pbxproj not installed. Run: pip3 install --user pbxproj", file=sys.stderr)
    sys.exit(1)


REPO_ROOT = Path(__file__).resolve().parent.parent
PBXPROJ_PATH = REPO_ROOT / "nagi.xcodeproj" / "project.pbxproj"
SOURCE_ROOT = REPO_ROOT / "nagi"


def add_file(project: XcodeProject, file_path: Path, group_name: str | None) -> bool:
    rel_path = file_path.relative_to(REPO_ROOT)
    already = project.get_files_by_path(str(rel_path))
    if already:
        print(f"  skip (already in project): {rel_path}")
        return False

    parent_group = None
    if group_name:
        groups = project.get_groups_by_name(group_name)
        if groups:
            parent_group = groups[0]

    added = project.add_file(
        str(rel_path),
        parent=parent_group,
        force=False,
    )
    if added:
        print(f"  added: {rel_path}" + (f" → group {group_name}" if group_name else ""))
        return True
    print(f"  FAILED to add: {rel_path}", file=sys.stderr)
    return False


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("paths", nargs="*", help="file path(s) relative to repo root or absolute")
    parser.add_argument("--group", default=None, help="target Xcode group name (e.g. Sensory, Shaders)")
    parser.add_argument("--sync", action="store_true", help="scan nagi/ and add all .swift / .metal files not yet in the project")
    args = parser.parse_args()

    if not PBXPROJ_PATH.exists():
        print(f"pbxproj not found: {PBXPROJ_PATH}", file=sys.stderr)
        return 1

    project = XcodeProject.load(str(PBXPROJ_PATH))

    added_any = False

    if args.sync:
        print(f"syncing on-disk files in {SOURCE_ROOT.relative_to(REPO_ROOT)}/ ...")
        for ext in ("*.swift", "*.metal"):
            for path in SOURCE_ROOT.rglob(ext):
                group_name = path.parent.name
                if add_file(project, path, group_name):
                    added_any = True
    else:
        if not args.paths:
            parser.error("provide file paths or use --sync")
        for p in args.paths:
            path = (REPO_ROOT / p).resolve() if not os.path.isabs(p) else Path(p).resolve()
            if not path.exists():
                print(f"  missing on disk: {path}", file=sys.stderr)
                continue
            group = args.group or path.parent.name
            if add_file(project, path, group):
                added_any = True

    if added_any:
        project.save()
        print("project.pbxproj saved.")
    else:
        print("no changes.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
