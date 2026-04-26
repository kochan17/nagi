#!/usr/bin/env python3
"""Register one or more Swift / Metal files into the legacy-style pbxproj.

Why this exists:
  nagi.xcodeproj/project.pbxproj uses quoted short IDs ('A1000NNN' / 'B1000NNN')
  that the pbxproj Python library mishandles. We insert PBXBuildFile +
  PBXFileReference + Sources phase entries as raw text, mirroring the patterns
  in scripts/add_to_pbxproj_text.py but exposed as a CLI for the
  `pbxproj-register` skill.

Usage:
  python3 register_one.py <repo-relative-path> [<path2> ...]

Exit codes:
  0 — registered successfully (or all paths were already registered)
  1 — invalid input (path missing on disk, wrong extension, etc.)
  2 — pbxproj structural error (couldn't locate Sources phase F1000002)
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# Locate the repo root by walking up from this file's location.
# .claude/skills/pbxproj-register/scripts/register_one.py
#   parents[0] = scripts
#   parents[1] = pbxproj-register
#   parents[2] = skills
#   parents[3] = .claude
#   parents[4] = repo root (nagi/)
REPO = Path(__file__).resolve().parents[4]
PBX = REPO / "nagi.xcodeproj" / "project.pbxproj"

EXT_TO_FILETYPE = {
    ".swift": "sourcecode.swift",
    ".metal": "sourcecode.metal",
}


def validate(rel_path: str) -> tuple[Path, str] | None:
    """Returns (abs_path, ftype) if valid, else None and prints reason."""
    p = Path(rel_path)
    if p.is_absolute():
        try:
            p = p.relative_to(REPO)
        except ValueError:
            print(f"  skip (outside repo): {rel_path}", file=sys.stderr)
            return None

    abs_path = REPO / p
    if not abs_path.exists():
        print(f"  skip (missing on disk): {rel_path}", file=sys.stderr)
        return None

    if p.suffix not in EXT_TO_FILETYPE:
        print(f"  skip (unsupported ext, not Sources phase): {rel_path}", file=sys.stderr)
        return None

    if p.parts[0] != "nagi":
        print(f"  skip (not under nagi/): {rel_path}", file=sys.stderr)
        return None

    return abs_path, EXT_TO_FILETYPE[p.suffix]


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: register_one.py <path> [<path2> ...]", file=sys.stderr)
        return 1

    content = PBX.read_text()

    # Already-referenced filenames — for skip detection.
    existing_refs = set(
        m.group(1) for m in re.finditer(
            r"isa = PBXFileReference;[^}]*?path\s*=\s*(\S+?)\s*;", content
        )
    )

    a_nums = [int(m.group(1)) for m in re.finditer(r"A1000(\d+)", content)]
    b_nums = [int(m.group(1)) for m in re.finditer(r"B1000(\d+)", content)]
    next_a = (max(a_nums) if a_nums else 0) + 1
    next_b = (max(b_nums) if b_nums else 0) + 1

    new_build_files: list[str] = []
    new_file_refs: list[str] = []
    new_sources_lines: list[str] = []
    registered: list[tuple[str, str, str]] = []  # (rel_path, a_id, b_id)
    skipped_existing: list[str] = []
    invalid: list[str] = []

    for raw in sys.argv[1:]:
        result = validate(raw)
        if result is None:
            invalid.append(raw)
            continue
        abs_path, ftype = result
        rel = str(abs_path.relative_to(REPO))
        filename = abs_path.name

        # Check both pre-existing and just-staged additions.
        already = filename in existing_refs or any(
            r[0].endswith(filename) for r in registered
        )
        if already:
            skipped_existing.append(rel)
            print(f"  skip (already registered): {filename}")
            continue

        a_id = f"A1000{next_a:03d}"
        b_id = f"B1000{next_b:03d}"
        next_a += 1
        next_b += 1

        new_build_files.append(
            f"\t\t'{a_id}' /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = '{b_id}' /* {filename} */; }};"
        )
        new_file_refs.append(
            f"\t\t'{b_id}' /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {rel}; sourceTree = SOURCE_ROOT; }};"
        )
        new_sources_lines.append(f"\t\t\t\t{a_id},")
        registered.append((rel, a_id, b_id))
        print(f"  + {rel}  (BuildFile {a_id}, FileRef {b_id})")

    if invalid:
        # Validation failures are an error condition even if some paths succeed.
        return 1

    if not new_build_files:
        # Everything was already registered. That's success (idempotent).
        return 0

    # Insert the new entries before each section's "End" marker.
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

    # Append into the Sources phase (F1000002).
    sources_pattern = re.compile(
        r"(\s*'F1000002' = \{[^}]*?files = \(\n)((?:\s*[A-Za-z0-9'_ /*,.]+\n)*)(\s*\);)",
        re.DOTALL,
    )
    match = sources_pattern.search(content)
    if not match:
        print("ERROR: could not locate PBXSourcesBuildPhase F1000002.", file=sys.stderr)
        return 2

    head, existing_files, tail = match.group(1), match.group(2), match.group(3)
    new_block = head + existing_files + "\n".join(new_sources_lines) + "\n" + tail
    content = content[: match.start()] + new_block + content[match.end():]

    PBX.write_text(content)
    print(f"\nwrote {PBX.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
