#!/usr/bin/env python3
"""Rename xcresulttool-exported UI test screenshots to readable names.

`xcresulttool export attachments` dumps every PNG under an opaque UUID
filename, grouped by test in manifest.json (each group has a `testIdentifier`
and an `attachments` array of `{exportedFileName, suggestedHumanReadableName,
...}`). This copies each PNG into the destination folder as
"<TestClass>.<testMethod>__<attachment-name>.png", falling back to the
exported name if the manifest doesn't look as expected.
"""
import json
import re
import shutil
import sys
from pathlib import Path

# Xcode's suggested name is "<attachment-name>_<index>_<uuid>.png" — strip the
# trailing index + uuid so what's left is exactly what the test passed to
# `attachment.name`.
_SUFFIX = re.compile(r"_\d+_[0-9A-Fa-f-]{36}$")


def clean_attachment_name(suggested, exported):
    stem = Path(suggested or exported).stem
    return _SUFFIX.sub("", stem) or stem


def clean_test_name(test_identifier):
    # "AddItemFlowTests/testAddingItemAppearsInList()" → "AddItemFlowTests.testAddingItemAppearsInList"
    return test_identifier.replace("()", "").replace("/", ".")


def main():
    export_dir = Path(sys.argv[1])
    out_dir = Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)

    manifest = []
    manifest_path = export_dir / "manifest.json"
    if manifest_path.exists():
        try:
            manifest = json.loads(manifest_path.read_text())
        except json.JSONDecodeError:
            manifest = []

    named = {}
    for group in manifest:
        test_id = clean_test_name(group.get("testIdentifier", ""))
        for attachment in group.get("attachments", []):
            exported = attachment.get("exportedFileName")
            if not exported:
                continue
            attachment_name = clean_attachment_name(attachment.get("suggestedHumanReadableName"), exported)
            named[exported] = "__".join(p for p in [test_id, attachment_name] if p)

    count = 0
    for png in sorted(export_dir.glob("*.png")):
        label = named.get(png.name, png.stem)
        safe = "".join(c if c.isalnum() or c in "-_." else "_" for c in label)
        dest = out_dir / f"{safe}.png"
        i = 1
        while dest.exists():
            dest = out_dir / f"{safe}_{i}.png"
            i += 1
        shutil.copy2(png, dest)
        count += 1

    print(f"Exported {count} screenshot(s) to {out_dir}")


if __name__ == "__main__":
    main()
