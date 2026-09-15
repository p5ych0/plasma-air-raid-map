#!/usr/bin/env python3
"""Build the installable Plasma wallpaper archive using only the standard library."""
import hashlib
import json
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile

root = Path(__file__).resolve().parent.parent
package = root / "package"
version = json.loads((package / "metadata.json").read_text())["KPlugin"]["Version"]
output = root / "dist" / f"plasma-air-raid-map-{version}.zip"
output.parent.mkdir(exist_ok=True)
with ZipFile(output, "w", ZIP_DEFLATED) as archive:
    for path in sorted(package.rglob("*")):
        if path.is_file():
            archive.write(path, path.relative_to(package))
    for name in ("README.md", "LICENSE"):
        archive.write(root / name, name)
with ZipFile(output) as archive:
    if archive.testzip() is not None:
        raise RuntimeError("Archive integrity check failed")
digest = hashlib.sha256(output.read_bytes()).hexdigest()
(output.parent / "SHA256SUMS").write_text(f"{digest}  {output.name}\n")
print(output)
print(digest)
