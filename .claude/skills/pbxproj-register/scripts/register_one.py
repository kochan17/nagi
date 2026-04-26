#!/usr/bin/env python3
"""Register Swift / Metal files into the legacy-style pbxproj.

Why this exists:
  nagi.xcodeproj/project.pbxproj uses quoted short IDs ('A1000NNN' / 'B1000NNN')
  that the pbxproj Python library mishandles. This CLI inserts the four sites
  needed for build + Xcode UI visibility: PBXBuildFile, PBXFileReference,
  the appropriate PBXGroup child entry, and the Sources phase files list.

Why each site matters:
  - PBXBuildFile + Sources phase  → the file gets compiled
  - PBXFileReference              → the project knows the file metadata
  - PBXGroup child entry          → the file shows up in Xcode Project Navigator

Idempotency:
  Detection is structural, not filename-grep: we look up the file by path,
  then verify all four sites independently. An "orphan" (FileRef without a
  matching BuildFile or Sources entry) is healed by adding the missing pieces
  using the existing FileRef ID — not by deleting and recreating.

Usage:
  python3 register_one.py <repo-relative-path> [<path2> ...]

Exit codes:
  0 — registered or already complete (idempotent)
  1 — invalid input (missing file, unsupported extension, etc.)
  2 — pbxproj structural error
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

EXT_TO_FILETYPE = {
    ".swift": "sourcecode.swift",
    ".metal": "sourcecode.metal",
}

NAGI_ROOT_GROUP_ID = "E1000002"  # the "nagi" PBXGroup
SOURCES_PHASE_ID = "F1000002"


def find_repo_root() -> Path:
    """Walk up from cwd to find a directory containing nagi.xcodeproj/project.pbxproj.

    This is cwd-based, NOT __file__-based, so the script targets the worktree
    or repo the user is actually working in — not whichever copy of the script
    happens to be on disk. This was iteration-1's most damaging bug.
    """
    cwd = Path.cwd()
    for p in [cwd] + list(cwd.parents):
        if (p / "nagi.xcodeproj" / "project.pbxproj").exists():
            return p
    raise RuntimeError(
        "could not locate nagi.xcodeproj/project.pbxproj from cwd or parents"
    )


def validate(rel_path: str, repo: Path) -> tuple[Path, str] | None:
    p = Path(rel_path)
    if p.is_absolute():
        try:
            p = p.relative_to(repo)
        except ValueError:
            print(f"  skip (outside repo): {rel_path}", file=sys.stderr)
            return None

    abs_path = repo / p
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


def find_existing_state(content: str, rel_path: str) -> dict:
    """Inspect the four registration sites independently.

    Returns:
        {
          "b_id":  str | None,   # FileRef ID if any matching file ref found
          "a_id":  str | None,   # BuildFile ID that points at b_id
          "in_sources":     bool,   # whether a_id appears in F1000002 files list
          "parent_group_id": str | None,  # PBXGroup that has b_id as child
        }
    """
    filename = Path(rel_path).name

    # Step 1: locate PBXFileReference. Existing entries use either:
    #   path = nagi/Foo/Bar.swift; sourceTree = SOURCE_ROOT;   (script-added)
    #   path = Bar.swift; sourceTree = "<group>";              (Xcode-added, group-relative)
    # Match either form by checking path tail equals filename OR full rel_path.
    fileref_iter = re.finditer(
        r"\s*'(B1000\d+)'(?:\s*/\*[^*]*\*/)?\s*=\s*\{\s*isa\s*=\s*PBXFileReference;[^}]*?path\s*=\s*([^;]+?)\s*;",
        content,
    )
    b_id = None
    for m in fileref_iter:
        path_value = m.group(2).strip().strip('"')
        if path_value == rel_path or path_value == filename or path_value.endswith("/" + filename):
            b_id = m.group(1)
            break

    if b_id is None:
        return {"b_id": None, "a_id": None, "in_sources": False, "parent_group_id": None}

    # Step 2: PBXBuildFile pointing at b_id (with or without comment annotations).
    bf_match = re.search(
        rf"\s*'(A1000\d+)'(?:\s*/\*[^*]*\*/)?\s*=\s*\{{\s*isa\s*=\s*PBXBuildFile;\s*fileRef\s*=\s*'?{b_id}'?[^}}]*\}}",
        content,
    )
    a_id = bf_match.group(1) if bf_match else None

    # Step 3: a_id appears as a token in F1000002 files = ( ... ).
    in_sources = False
    if a_id:
        sources_match = re.search(
            rf"'{SOURCES_PHASE_ID}'\s*=\s*\{{[^}}]*?files\s*=\s*\(([^)]*)\)",
            content,
            re.DOTALL,
        )
        if sources_match and re.search(rf"\b{a_id}\b", sources_match.group(1)):
            in_sources = True

    # Step 4: which PBXGroup has b_id as a child token?
    parent_group_id = None
    for gm in re.finditer(
        r"'(E1000\d+)'\s*=\s*\{\s*isa\s*=\s*PBXGroup;[^}]*?children\s*=\s*\(([^)]*)\)",
        content,
        re.DOTALL,
    ):
        if re.search(rf"\b{b_id}\b", gm.group(2)):
            parent_group_id = gm.group(1)
            break

    return {
        "b_id": b_id,
        "a_id": a_id,
        "in_sources": in_sources,
        "parent_group_id": parent_group_id,
    }


def next_id(content: str, prefix: str) -> str:
    """Return the next available ID like A1000NNN by scanning the whole file."""
    nums = [int(m.group(1)) for m in re.finditer(rf"{prefix}1000(\d+)", content)]
    return f"{prefix}1000{(max(nums) if nums else 0) + 1:03d}"


def ensure_group_chain(content: str, dir_parts: list[str]) -> tuple[str, str]:
    """Walk/create PBXGroup chain under E1000002 for dir_parts.

    dir_parts = ['Scenes', 'Waves'] for nagi/Scenes/Waves/X.swift.
    Returns (updated_content, deepest_group_id).
    """
    current_id = NAGI_ROOT_GROUP_ID

    for part in dir_parts:
        # Read current group's children block.
        group_match = re.search(
            rf"'{current_id}'\s*=\s*\{{\s*isa\s*=\s*PBXGroup;\s*children\s*=\s*\(([^)]*)\)",
            content,
            re.DOTALL,
        )
        if not group_match:
            raise RuntimeError(f"could not locate PBXGroup '{current_id}'")
        children_text = group_match.group(1)

        # Among the E IDs referenced as children, find one whose own definition has path = part.
        child_id = None
        for cm in re.finditer(r"'?(E1000\d+)'?", children_text):
            cid = cm.group(1)
            child_def = re.search(
                rf"'{cid}'\s*=\s*\{{\s*isa\s*=\s*PBXGroup;[^}}]*?path\s*=\s*\"?{re.escape(part)}\"?\s*;",
                content,
            )
            if child_def:
                child_id = cid
                break

        if child_id is None:
            # Create a new empty group with path = part as a child of current_id.
            new_e_id = next_id(content, "E")
            new_group_def = (
                f"\t\t'{new_e_id}' = {{\n"
                f"\t\t\tisa = PBXGroup;\n"
                f"\t\t\tchildren = (\n"
                f"\t\t\t);\n"
                f"\t\t\tpath = {part};\n"
                f"\t\t\tsourceTree = \"<group>\";\n"
                f"\t\t}};"
            )
            content = content.replace(
                "/* End PBXGroup section */",
                new_group_def + "\n/* End PBXGroup section */",
                1,
            )
            # Append the new group ID to current_id's children list.
            content = _append_to_group_children(content, current_id, f"'{new_e_id}' /* {part} */")
            child_id = new_e_id

        current_id = child_id

    return content, current_id


def _append_to_group_children(content: str, group_id: str, child_token: str) -> str:
    """Insert `child_token,` just before the closing `);` of group_id's children list."""
    pat = re.compile(
        rf"('{group_id}'\s*=\s*\{{\s*isa\s*=\s*PBXGroup;[^}}]*?children\s*=\s*\([^)]*?)(\s*\);)",
        re.DOTALL,
    )
    new_content, n = pat.subn(
        lambda m: m.group(1) + f"\n\t\t\t\t{child_token}," + m.group(2),
        content,
        count=1,
    )
    if n == 0:
        raise RuntimeError(f"failed to append to children of {group_id}")
    return new_content


def add_buildfile_entry(content: str, a_id: str, b_id: str, filename: str) -> str:
    line = (
        f"\t\t'{a_id}' /* {filename} in Sources */ = "
        f"{{isa = PBXBuildFile; fileRef = '{b_id}' /* {filename} */; }};"
    )
    return content.replace(
        "/* End PBXBuildFile section */",
        line + "\n/* End PBXBuildFile section */",
        1,
    )


def add_fileref_entry(content: str, b_id: str, rel_path: str, filename: str, ftype: str) -> str:
    line = (
        f"\t\t'{b_id}' /* {filename} */ = "
        f"{{isa = PBXFileReference; lastKnownFileType = {ftype}; "
        f"path = {filename}; sourceTree = \"<group>\"; }};"
    )
    return content.replace(
        "/* End PBXFileReference section */",
        line + "\n/* End PBXFileReference section */",
        1,
    )


def add_to_sources_phase(content: str, a_id: str) -> str:
    pat = re.compile(
        rf"('{SOURCES_PHASE_ID}'\s*=\s*\{{[^}}]*?files\s*=\s*\([^)]*?)(\s*\);)",
        re.DOTALL,
    )
    new_content, n = pat.subn(
        lambda m: m.group(1) + f"\n\t\t\t\t{a_id}," + m.group(2),
        content,
        count=1,
    )
    if n == 0:
        raise RuntimeError(f"failed to insert into PBXSourcesBuildPhase {SOURCES_PHASE_ID}")
    return new_content


def register_one(content: str, rel_path: str, ftype: str) -> tuple[str, dict]:
    """Apply only the missing pieces. Returns (new_content, action_summary)."""
    state = find_existing_state(content, rel_path)
    filename = Path(rel_path).name
    rel_parts = Path(rel_path).parts  # e.g. ('nagi', 'Scenes', 'Waves', 'WavesScene.swift')
    dir_parts = list(rel_parts[1:-1])  # strip 'nagi' prefix and the filename itself

    # Decide what's missing.
    actions: list[str] = []
    b_id = state["b_id"]
    a_id = state["a_id"]

    if b_id is None:
        b_id = next_id(content, "B")
        content = add_fileref_entry(content, b_id, rel_path, filename, ftype)
        actions.append(f"FileRef {b_id}")

    if a_id is None:
        a_id = next_id(content, "A")
        content = add_buildfile_entry(content, a_id, b_id, filename)
        actions.append(f"BuildFile {a_id}")

    if not state["in_sources"]:
        content = add_to_sources_phase(content, a_id)
        actions.append("Sources phase")

    if state["parent_group_id"] is None:
        if dir_parts:
            content, group_id = ensure_group_chain(content, dir_parts)
            content = _append_to_group_children(content, group_id, f"'{b_id}' /* {filename} */")
            actions.append(f"Group {group_id}")
        else:
            # File at nagi/ root — add directly to nagi root group.
            content = _append_to_group_children(
                content, NAGI_ROOT_GROUP_ID, f"'{b_id}' /* {filename} */"
            )
            actions.append(f"Group {NAGI_ROOT_GROUP_ID}")

    return content, {"b_id": b_id, "a_id": a_id, "actions": actions}


def main() -> int:
    if len(sys.argv) < 2:
        print("usage: register_one.py <path> [<path2> ...]", file=sys.stderr)
        return 1

    repo = find_repo_root()
    pbx = repo / "nagi.xcodeproj" / "project.pbxproj"
    content = pbx.read_text()

    invalid: list[str] = []
    for raw in sys.argv[1:]:
        result = validate(raw, repo)
        if result is None:
            invalid.append(raw)
            continue
        abs_path, ftype = result
        rel = str(abs_path.relative_to(repo))

        try:
            content, summary = register_one(content, rel, ftype)
        except RuntimeError as e:
            print(f"ERROR: {rel}: {e}", file=sys.stderr)
            return 2

        if summary["actions"]:
            print(f"  + {rel}  ({', '.join(summary['actions'])})")
        else:
            print(f"  ok {rel}  (already complete: BuildFile {summary['a_id']}, FileRef {summary['b_id']})")

    if invalid:
        return 1

    pbx.write_text(content)
    print(f"\nwrote {pbx.relative_to(repo)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
