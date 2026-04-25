#!/usr/bin/env python3
"""Direct text insertion to add files to the legacy-style pbxproj.

Why this exists:
  The project's pbxproj uses quoted short IDs like 'A1000001' that the pbxproj
  Python library misidentifies, causing NoneType errors. We sidestep the library
  and insert entries as raw text blocks, consistent with existing naming.

Usage:
  python3 scripts/add_to_pbxproj_text.py

Edit FILES_TO_ADD in this file and re-run.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PBX = REPO / "nagi.xcodeproj" / "project.pbxproj"

# Entries to insert. Tuple of (repo-relative path, Xcode file type).
FILES_TO_ADD: list[tuple[str, str]] = [
    ("nagi/Shaders/CampfireShader.metal",     "sourcecode.metal"),
    ("nagi/Scenes/Bonfire/BonfireScene.swift", "sourcecode.swift"),
    ("nagi/Studio/ScenePresetStore.swift",    "sourcecode.swift"),
    ("nagi/Studio/PerformanceHUD.swift",      "sourcecode.swift"),
    ("nagi/Studio/SceneDebugView.swift",      "sourcecode.swift"),
    ("nagi/Studio/ABComparisonView.swift",    "sourcecode.swift"),
    ("nagi/Studio/StudioTab.swift",           "sourcecode.swift"),
]


def main() -> int:
    content = PBX.read_text()

    # Find next available short-style IDs (A1000NNN for BuildFile, B1000NNN for FileRef).
    a_nums = [int(m.group(1)) for m in re.finditer(r"A1000(\d+)", content)]
    b_nums = [int(m.group(1)) for m in re.finditer(r"B1000(\d+)", content)]
    next_a = (max(a_nums) if a_nums else 0) + 1
    next_b = (max(b_nums) if b_nums else 0) + 1

    new_build_files: list[str] = []
    new_file_refs: list[str] = []
    new_sources_lines: list[str] = []

    # Skip files whose filename already appears as a PBXFileReference to avoid duplication.
    existing_file_refs = set(
        m.group(1) for m in re.finditer(
            r"isa = PBXFileReference;[^}]*?path\s*=\s*(\S+?)\s*;", content
        )
    )

    for rel_path, ftype in FILES_TO_ADD:
        abs_path = REPO / rel_path
        if not abs_path.exists():
            print(f"  skip (missing on disk): {rel_path}", file=sys.stderr)
            continue

        filename = abs_path.name
        if filename in existing_file_refs:
            print(f"  skip (already referenced): {filename}")
            continue

        a_id = f"A1000{next_a:03d}"
        b_id = f"B1000{next_b:03d}"
        next_a += 1
        next_b += 1

        new_build_files.append(
            f"\t\t'{a_id}' /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = '{b_id}' /* {filename} */; }};"
        )
        new_file_refs.append(
            f"\t\t'{b_id}' /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {rel_path}; sourceTree = SOURCE_ROOT; }};"
        )
        new_sources_lines.append(f"\t\t\t\t{a_id},")
        print(f"  + {rel_path}  (BuildFile {a_id}, FileRef {b_id})")

    if not new_build_files:
        print("no changes.")
        return 0

    # Insert before the End-of-section markers. Use plain string replace on stable anchors.
    content = content.replace(
        "/* End PBXBuildFile section */",
        "\n".join(new_build_files) + "\n/* End PBXBuildFile section */",
        1,
    )
    content = content.replace(
        "/* End PBXFileReference section */",
        "\n".join(new_file_refs) + "\n/* End PBXFileReference section */",
        1,
    )

    # Insert into F1000002 (PBXSourcesBuildPhase). Anchor on the last existing BuildFile line before `);`.
    # We find the F1000002 block and append inside `files = (...)`.
    sources_pattern = re.compile(
        r"(\s*'F1000002' = \{[^}]*?files = \(\n)((?:\s*[A-Za-z0-9'_ /*,.]+\n)*)(\s*\);)",
        re.DOTALL,
    )
    match = sources_pattern.search(content)
    if not match:
        print("ERROR: could not locate PBXSourcesBuildPhase F1000002 block.", file=sys.stderr)
        return 2

    head, existing_files, tail = match.group(1), match.group(2), match.group(3)
    new_block = head + existing_files + "\n".join(new_sources_lines) + "\n" + tail
    content = content[: match.start()] + new_block + content[match.end():]

    PBX.write_text(content)
    print(f"\nwrote {PBX.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
