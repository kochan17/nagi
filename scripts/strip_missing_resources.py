#!/usr/bin/env python3
"""Remove pbxproj references to resource files that don't exist on disk.

The nagi project references several slime/waves/touch assets that are missing
from disk, blocking the linker CopyFilesBuildPhase. Rather than fabricate
placeholders we strip the references entirely — the assets can be re-registered
later via add_to_pbxproj_text.py once restored.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
PBX = REPO / "nagi.xcodeproj" / "project.pbxproj"

# File references to strip (filenames only; we locate the IDs dynamically).
MISSING_FILENAMES = {
    "waves_ocean.mp3",
    "touch_start.mp3",
    "touch_release.mp3",
    "slime_touch.mp3",
    "slime_wool.jpg",
    "slime_weave.jpg",
    "slime_velvet.jpg",
    "slime_teddy.jpg",
    "slime_metal_mesh.jpg",
}


def main() -> int:
    content = PBX.read_text()
    original = content

    # 1) Find PBXFileReference lines for these filenames → collect B IDs.
    b_ids: dict[str, str] = {}  # B ID → filename
    file_ref_pattern = re.compile(
        r"\s*'(B1000\d+)' = \{isa = PBXFileReference;[^}]*?path = (\S+?);[^}]*?\};\n?"
    )
    for m in file_ref_pattern.finditer(content):
        bid, path = m.group(1), m.group(2)
        if path in MISSING_FILENAMES:
            b_ids[bid] = path

    if not b_ids:
        print("no matching file references found.")
        return 0

    print(f"found {len(b_ids)} missing file refs:")
    for bid, fn in b_ids.items():
        print(f"  {bid} → {fn}")

    # 2) Find PBXBuildFile lines referencing each B ID → collect A IDs.
    a_ids: set[str] = set()
    build_file_pattern = re.compile(
        r"\s*'(A1000\d+)' /\* [^*]+ \*/ = \{isa = PBXBuildFile; fileRef = '(B1000\d+)' /\*[^*]+\*/; \};\n?"
    )
    for m in build_file_pattern.finditer(content):
        aid, bid = m.group(1), m.group(2)
        if bid in b_ids:
            a_ids.add(aid)

    print(f"\nfound {len(a_ids)} build file refs: {sorted(a_ids)}")

    # 3) Remove PBXBuildFile entries for each A ID.
    for aid in a_ids:
        pat = re.compile(
            rf"\s*'{aid}' /\* [^*]+ in Resources \*/ = \{{isa = PBXBuildFile; fileRef = '(B1000\d+)' /\*[^*]+\*/; \}};\n"
        )
        content, n = pat.subn("", content)
        if n == 0:
            print(f"  WARN: no PBXBuildFile line removed for {aid}", file=sys.stderr)

    # 4) Remove PBXFileReference entries for each B ID.
    for bid in b_ids:
        pat = re.compile(
            rf"\s*'{bid}' = \{{isa = PBXFileReference;[^}}]*?\}};\n"
        )
        content, n = pat.subn("", content)
        if n == 0:
            print(f"  WARN: no PBXFileReference line removed for {bid}", file=sys.stderr)

    # 5) Remove from any PBXGroup children / PBXResourcesBuildPhase files lists.
    #    Match "\t\t\t\tA1000050," or "\t\t\t\tB1000050 /* ... */," style lines.
    for some_id in list(a_ids) + list(b_ids.keys()):
        # Handle both quoted/unquoted and plain-ID vs comment-annotated forms.
        patterns = [
            rf"\s*'{some_id}' /\* [^*]+ \*/,\n",
            rf"\s*'{some_id}',\n",
            rf"\s*{some_id} /\* [^*]+ \*/,\n",
            rf"\s*{some_id},\n",
        ]
        for p in patterns:
            content = re.sub(p, "", content)

    if content == original:
        print("no changes applied.")
        return 1

    PBX.write_text(content)
    print(f"\nwrote {PBX.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
